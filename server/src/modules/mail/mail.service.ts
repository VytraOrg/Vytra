import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as nodemailer from 'nodemailer';
import { Resend } from 'resend';

export interface OrderItemSummary {
  name: string;
  quantity: number;
  price: number;
}

export interface OrderConfirmationData {
  orderId: string;
  customerName: string;
  items: OrderItemSummary[];
  totalAmount: number;
  deliveryAddress?: any;
}

export interface OrderStatusData {
  orderId: string;
  customerName: string;
  status: string;
}

@Injectable()
export class MailService {
  private readonly logger = new Logger(MailService.name);
  private resendClient: Resend | null = null;
  private transporter: nodemailer.Transporter | null = null;
  private readonly fromAddress: string;

  constructor(private readonly configService: ConfigService) {
    const resendApiKey = this.configService.get<string>('RESEND_API_KEY');
    if (resendApiKey) {
      this.resendClient = new Resend(resendApiKey);
      this.logger.log('Resend HTTPS Email Client initialized (Port 443 API)');
    }

    const host = this.configService.get<string>('SMTP_HOST', 'smtpout.secureserver.net');
    const port = parseInt(this.configService.get<string>('SMTP_PORT', '587'), 10);
    const user = this.configService.get<string>('SMTP_USER', 'support@vytra.co.in');
    const pass = this.configService.get<string>('SMTP_PASS', '');
    const secure = port === 465 || this.configService.get<string>('SMTP_SECURE') === 'true';

    this.fromAddress = this.configService.get<string>('SMTP_FROM', `"Vytra" <${user}>`);

    if (pass) {
      this.transporter = nodemailer.createTransport({
        host,
        port,
        secure,
        auth: {
          user,
          pass,
        },
        connectionTimeout: 8000,
        greetingTimeout: 8000,
        socketTimeout: 8000,
      });

      this.transporter.verify((error) => {
        if (error) {
          this.logger.warn(`SMTP connection verification failed: ${error.message}`);
        } else {
          this.logger.log(`SMTP transporter ready to deliver emails via ${host}:${port} as ${user}`);
        }
      });
    } else if (!this.resendClient) {
      this.logger.warn(
        'Neither RESEND_API_KEY nor SMTP_PASS is configured. Outgoing emails will be logged to console (Simulation Mode).',
      );
    }
  }

  /**
   * Generic sender with error-shielding so caller never crashes on email failure.
   */
  async sendMail(options: { to: string; subject: string; html: string; text?: string }): Promise<boolean> {
    try {
      // 1. Send via Resend HTTPS API (Works 100% reliably on Render / Cloud on port 443)
      if (this.resendClient) {
        const { data, error } = await this.resendClient.emails.send({
          from: this.fromAddress,
          to: [options.to],
          subject: options.subject,
          html: options.html,
          text: options.text || options.subject,
        });

        if (error) {
          this.logger.error(`Resend dispatch error to ${options.to}: ${error.message}`);
        } else {
          this.logger.log(`Resend email dispatched to ${options.to} (ID: ${data?.id})`);
          return true;
        }
      }

      // 2. Fallback to SMTP transporter
      if (this.transporter) {
        const info = await this.transporter.sendMail({
          from: this.fromAddress,
          to: options.to,
          subject: options.subject,
          text: options.text || options.subject,
          html: options.html,
        });

        this.logger.log(`SMTP email dispatched to ${options.to} (MessageId: ${info.messageId})`);
        return true;
      }

      // 3. Fallback to Simulation Mode
      this.logger.log(
        `[SIMULATED EMAIL] To: ${options.to} | Subject: "${options.subject}" (Configure RESEND_API_KEY or SMTP_PASS to send live)`,
      );
      return true;
    } catch (err: any) {
      this.logger.error(`Failed to send email to ${options.to}: ${err.message}`, err.stack);
      return false;
    }
  }

  /**
   * Order Confirmation Receipt
   */
  async sendOrderConfirmation(to: string, data: OrderConfirmationData): Promise<boolean> {
    const formattedTotal = `₹${data.totalAmount.toLocaleString('en-IN')}`;
    const shortId = data.orderId.slice(-8).toUpperCase();

    const itemsHtml = data.items
      .map(
        (item) => `
        <tr style="border-bottom: 1px solid #f0f0f4;">
          <td style="padding: 12px 8px; font-size: 14px; color: #22222b; font-weight: 500;">
            ${item.name}
          </td>
          <td style="padding: 12px 8px; font-size: 14px; color: #64748b; text-align: center;">
            ×${item.quantity}
          </td>
          <td style="padding: 12px 8px; font-size: 14px; color: #111827; font-weight: 600; text-align: right;">
            ₹${(item.price * item.quantity).toLocaleString('en-IN')}
          </td>
        </tr>
      `,
      )
      .join('');

    const addressText = data.deliveryAddress
      ? typeof data.deliveryAddress === 'string'
        ? data.deliveryAddress
        : [
            data.deliveryAddress.street,
            data.deliveryAddress.city,
            data.deliveryAddress.state,
            data.deliveryAddress.pincode,
          ]
            .filter(Boolean)
            .join(', ') || 'Standard Delivery Address'
      : 'Address on file';

    const html = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Order Confirmation - Vytra</title>
    </head>
    <body style="margin: 0; padding: 0; background-color: #FAF9F6; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; color: #1E1B18;">
      <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #FAF9F6; padding: 36px 16px;">
        <tr>
          <td align="center">
            <table width="100%" cellpadding="0" cellspacing="0" style="max-width: 580px; background-color: #FFFFFF; border-radius: 20px; overflow: hidden; border: 1px solid #EFE9E1; box-shadow: 0 8px 30px rgba(56, 36, 13, 0.06);">
              <!-- Header -->
              <tr>
                <td style="background: linear-gradient(135deg, #1E1B18 0%, #38240D 60%, #4A3728 100%); padding: 36px 32px; text-align: center; border-bottom: 3px solid #D4A373;">
                  <h1 style="margin: 0; font-size: 28px; font-weight: 900; letter-spacing: 2px; color: #FFFFFF;">
                    VYTRA
                  </h1>
                  <div style="display: inline-block; margin-top: 10px; padding: 4px 14px; background: rgba(212, 163, 115, 0.18); border: 1px solid rgba(212, 163, 115, 0.45); border-radius: 20px; font-size: 11px; letter-spacing: 1.2px; text-transform: uppercase; font-weight: 700; color: #D4A373;">
                    Order Confirmation
                  </div>
                </td>
              </tr>

              <!-- Greeting & Summary -->
              <tr>
                <td style="padding: 32px 32px 20px 32px;">
                  <h2 style="margin: 0 0 8px 0; font-size: 20px; font-weight: 800; color: #1E1B18;">
                    Thank you for your order, ${data.customerName || 'valued customer'}! 🎉
                  </h2>
                  <p style="margin: 0; font-size: 14px; line-height: 1.6; color: #7D6E63;">
                    We have received your order <strong style="color: #38240D;">#${shortId}</strong> and our team is already preparing it for speedy delivery.
                  </p>
                </td>
              </tr>

              <!-- Order Details Card -->
              <tr>
                <td style="padding: 0 32px 20px 32px;">
                  <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #FAF9F6; border: 1px solid #EFE9E1; border-radius: 14px; padding: 16px 20px;">
                    <tr>
                      <td style="font-size: 13px; color: #7D6E63; font-weight: 600;">Order ID:</td>
                      <td style="font-size: 13px; color: #1E1B18; font-weight: 700; text-align: right; font-family: monospace;">${data.orderId}</td>
                    </tr>
                    <tr>
                      <td style="font-size: 13px; color: #7D6E63; font-weight: 600; padding-top: 8px;">Status:</td>
                      <td style="font-size: 13px; color: #2D6A4F; font-weight: 700; text-align: right; padding-top: 8px;">● Confirmed & Preparing</td>
                    </tr>
                  </table>
                </td>
              </tr>

              <!-- Items Table -->
              <tr>
                <td style="padding: 0 32px 24px 32px;">
                  <table width="100%" cellpadding="0" cellspacing="0">
                    <thead>
                      <tr style="border-bottom: 2px solid #EFE9E1;">
                        <th style="padding: 10px 8px; font-size: 12px; text-transform: uppercase; letter-spacing: 0.5px; color: #7D6E63; text-align: left;">Item</th>
                        <th style="padding: 10px 8px; font-size: 12px; text-transform: uppercase; letter-spacing: 0.5px; color: #7D6E63; text-align: center;">Qty</th>
                        <th style="padding: 10px 8px; font-size: 12px; text-transform: uppercase; letter-spacing: 0.5px; color: #7D6E63; text-align: right;">Amount</th>
                      </tr>
                    </thead>
                    <tbody>
                      ${itemsHtml}
                    </tbody>
                    <tfoot>
                      <tr>
                        <td colspan="2" style="padding: 18px 8px 4px 8px; font-size: 15px; font-weight: 700; color: #1E1B18; text-align: right;">
                          Total Amount:
                        </td>
                        <td style="padding: 18px 8px 4px 8px; font-size: 19px; font-weight: 900; color: #38240D; text-align: right;">
                          ${formattedTotal}
                        </td>
                      </tr>
                    </tfoot>
                  </table>
                </td>
              </tr>

              <!-- Delivery Address -->
              <tr>
                <td style="padding: 0 32px 32px 32px;">
                  <div style="background-color: #FDFBF9; border: 1px solid #EFE9E1; border-radius: 14px; padding: 16px 20px;">
                    <div style="font-size: 11px; text-transform: uppercase; letter-spacing: 0.8px; font-weight: 700; color: #7D6E63; margin-bottom: 6px;">
                      📍 Delivery Address
                    </div>
                    <div style="font-size: 14px; color: #1E1B18; line-height: 1.5; font-weight: 500;">
                      ${addressText}
                    </div>
                  </div>
                </td>
              </tr>

              <!-- Support Footer -->
              <tr>
                <td style="background-color: #FAF9F6; border-top: 1px solid #EFE9E1; padding: 24px 32px; text-align: center;">
                  <p style="margin: 0 0 6px 0; font-size: 13px; color: #7D6E63;">
                    Have questions about your order or delivery?
                  </p>
                  <p style="margin: 0; font-size: 13px; font-weight: 600; color: #38240D;">
                    Contact our team anytime at <a href="mailto:support@vytra.co.in" style="color: #38240D; text-decoration: underline; font-weight: 700;">support@vytra.co.in</a>
                  </p>
                  <p style="margin: 16px 0 0 0; font-size: 11px; color: #AFA59D;">
                    © ${new Date().getFullYear()} Vytra. Quick & Fresh Local Commerce.
                  </p>
                </td>
              </tr>
            </table>
          </td>
        </tr>
      </table>
    </body>
    </html>
    `;

    return this.sendMail({
      to,
      subject: `Order Confirmed #${shortId} - Vytra`,
      html,
      text: `Thank you for your order #${shortId}! Total: ${formattedTotal}. We are preparing your order. Reach us at support@vytra.co.in for any questions.`,
    });
  }

  /**
   * Welcome Email for New Registrations
   */
  async sendWelcome(to: string, name: string): Promise<boolean> {
    const html = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Welcome to Vytra</title>
    </head>
    <body style="margin: 0; padding: 0; background-color: #FAF9F6; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; color: #1E1B18;">
      <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #FAF9F6; padding: 36px 16px;">
        <tr>
          <td align="center">
            <table width="100%" cellpadding="0" cellspacing="0" style="max-width: 580px; background-color: #FFFFFF; border-radius: 20px; overflow: hidden; border: 1px solid #EFE9E1; box-shadow: 0 8px 30px rgba(56, 36, 13, 0.06);">
              <!-- Header -->
              <tr>
                <td style="background: linear-gradient(135deg, #1E1B18 0%, #38240D 60%, #4A3728 100%); padding: 36px 32px; text-align: center; border-bottom: 3px solid #D4A373;">
                  <h1 style="margin: 0; font-size: 28px; font-weight: 900; letter-spacing: 2px; color: #FFFFFF;">
                    VYTRA
                  </h1>
                  <div style="display: inline-block; margin-top: 10px; padding: 4px 14px; background: rgba(212, 163, 115, 0.18); border: 1px solid rgba(212, 163, 115, 0.45); border-radius: 20px; font-size: 11px; letter-spacing: 1.2px; text-transform: uppercase; font-weight: 700; color: #D4A373;">
                    Welcome
                  </div>
                </td>
              </tr>
              <!-- Content -->
              <tr>
                <td style="padding: 36px 32px 28px 32px;">
                  <h2 style="margin: 0 0 12px 0; font-size: 22px; font-weight: 800; color: #1E1B18;">
                    Welcome to Vytra, ${name || 'Friend'}! 🌿
                  </h2>
                  <p style="margin: 0 0 16px 0; font-size: 15px; line-height: 1.6; color: #7D6E63;">
                    Your account has been successfully created. With Vytra, you get fast, reliable local commerce, instant updates, and verified local merchants delivered straight to your doorstep.
                  </p>

                  <div style="text-align: center; margin: 28px 0;">
                    <a href="https://download.vytra.co.in" style="display: inline-block; background-color: #38240D; color: #FFFFFF; font-size: 14px; font-weight: 700; padding: 14px 28px; border-radius: 12px; text-decoration: none; border: 1px solid #D4A373; box-shadow: 0 4px 12px rgba(56, 36, 13, 0.15);">
                      Download Mobile App 📱
                    </a>
                  </div>

                  <div style="background-color: #FDFBF9; border: 1px solid #EFE9E1; border-radius: 14px; padding: 16px 20px;">
                    <p style="margin: 0; font-size: 13px; line-height: 1.5; color: #7D6E63;">
                      Need help? Reach out directly to our support team at <a href="mailto:support@vytra.co.in" style="color: #38240D; font-weight: 700; text-decoration: underline;">support@vytra.co.in</a>.
                    </p>
                  </div>
                </td>
              </tr>
              <!-- Footer -->
              <tr>
                <td style="background-color: #FAF9F6; border-top: 1px solid #EFE9E1; padding: 20px 32px; text-align: center;">
                  <p style="margin: 0; font-size: 11px; color: #AFA59D;">
                    © ${new Date().getFullYear()} Vytra. Quick & Fresh Local Commerce.
                  </p>
                </td>
              </tr>
            </table>
          </td>
        </tr>
      </table>
    </body>
    </html>
    `;

    return this.sendMail({
      to,
      subject: 'Welcome to Vytra! 🌿',
      html,
      text: `Welcome to Vytra, ${name}! Your account is active. Visit download.vytra.co.in for the mobile app, or contact support@vytra.co.in if you need anything.`,
    });
  }

  /**
   * Order Status Update Email
   */
  async sendOrderStatusUpdate(to: string, data: OrderStatusData): Promise<boolean> {
    const shortId = data.orderId.slice(-8).toUpperCase();
    const isDelivered = data.status.toLowerCase().includes('delivered');
    const isCancelled = data.status.toLowerCase().includes('cancel');
    const statusColor = isDelivered ? '#2D6A4F' : isCancelled ? '#BC4749' : '#38240D';
    const statusBg = isDelivered ? '#EBF5EE' : isCancelled ? '#FDF0ED' : '#F5EBE0';

    const html = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Order Status Update - Vytra</title>
    </head>
    <body style="margin: 0; padding: 0; background-color: #FAF9F6; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; color: #1E1B18;">
      <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #FAF9F6; padding: 36px 16px;">
        <tr>
          <td align="center">
            <table width="100%" cellpadding="0" cellspacing="0" style="max-width: 580px; background-color: #FFFFFF; border-radius: 20px; overflow: hidden; border: 1px solid #EFE9E1; box-shadow: 0 8px 30px rgba(56, 36, 13, 0.06);">
              <!-- Header -->
              <tr>
                <td style="background: linear-gradient(135deg, #1E1B18 0%, #38240D 60%, #4A3728 100%); padding: 36px 32px; text-align: center; border-bottom: 3px solid #D4A373;">
                  <h1 style="margin: 0; font-size: 28px; font-weight: 900; letter-spacing: 2px; color: #FFFFFF;">
                    VYTRA
                  </h1>
                  <div style="display: inline-block; margin-top: 10px; padding: 4px 14px; background: rgba(212, 163, 115, 0.18); border: 1px solid rgba(212, 163, 115, 0.45); border-radius: 20px; font-size: 11px; letter-spacing: 1.2px; text-transform: uppercase; font-weight: 700; color: #D4A373;">
                    Order Update
                  </div>
                </td>
              </tr>
              <!-- Content -->
              <tr>
                <td style="padding: 36px 32px 28px 32px;">
                  <h2 style="margin: 0 0 10px 0; font-size: 20px; font-weight: 800; color: #1E1B18;">
                    Hi ${data.customerName || 'there'},
                  </h2>
                  <p style="margin: 0 0 20px 0; font-size: 15px; color: #7D6E63; line-height: 1.6;">
                    Your order <strong style="color: #38240D;">#${shortId}</strong> status has been updated:
                  </p>
                  <div style="background-color: ${statusBg}; border-left: 4px solid ${statusColor}; border: 1px solid #EFE9E1; border-left-width: 4px; padding: 16px 20px; border-radius: 12px; margin-bottom: 24px;">
                    <div style="font-size: 11px; text-transform: uppercase; letter-spacing: 0.8px; font-weight: 700; color: #7D6E63; margin-bottom: 4px;">
                      Current Status
                    </div>
                    <span style="font-size: 19px; font-weight: 800; color: ${statusColor};">${data.status}</span>
                  </div>
                  <p style="margin: 0; font-size: 13px; color: #7D6E63; line-height: 1.5;">
                    If you have any questions regarding your delivery, reach out to us at <a href="mailto:support@vytra.co.in" style="color: #38240D; font-weight: 700; text-decoration: underline;">support@vytra.co.in</a>.
                  </p>
                </td>
              </tr>
              <!-- Footer -->
              <tr>
                <td style="background-color: #FAF9F6; border-top: 1px solid #EFE9E1; padding: 20px 32px; text-align: center;">
                  <p style="margin: 0; font-size: 11px; color: #AFA59D;">
                    © ${new Date().getFullYear()} Vytra. Quick & Fresh Local Commerce.
                  </p>
                </td>
              </tr>
            </table>
          </td>
        </tr>
      </table>
    </body>
    </html>
    `;

    return this.sendMail({
      to,
      subject: `Order #${shortId} Status: ${data.status} - Vytra`,
      html,
      text: `Your order #${shortId} has been updated to ${data.status}. Contact support@vytra.co.in for help.`,
    });
  }

  /**
   * Password Reset OTP Email
   */
  async sendPasswordResetOtp(to: string, otp: string, name?: string): Promise<boolean> {
    const html = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Password Reset Code - Vytra</title>
    </head>
    <body style="margin: 0; padding: 0; background-color: #FAF9F6; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; color: #1E1B18;">
      <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #FAF9F6; padding: 36px 16px;">
        <tr>
          <td align="center">
            <table width="100%" cellpadding="0" cellspacing="0" style="max-width: 540px; background-color: #FFFFFF; border-radius: 20px; overflow: hidden; border: 1px solid #EFE9E1; box-shadow: 0 8px 30px rgba(56, 36, 13, 0.06);">
              <!-- Header -->
              <tr>
                <td style="background: linear-gradient(135deg, #1E1B18 0%, #38240D 60%, #4A3728 100%); padding: 36px 32px; text-align: center; border-bottom: 3px solid #D4A373;">
                  <h1 style="margin: 0; font-size: 28px; font-weight: 900; letter-spacing: 2px; color: #FFFFFF;">
                    VYTRA
                  </h1>
                  <div style="display: inline-block; margin-top: 10px; padding: 4px 14px; background: rgba(212, 163, 115, 0.18); border: 1px solid rgba(212, 163, 115, 0.45); border-radius: 20px; font-size: 11px; letter-spacing: 1.2px; text-transform: uppercase; font-weight: 700; color: #D4A373;">
                    Password Recovery
                  </div>
                </td>
              </tr>

              <!-- Content -->
              <tr>
                <td style="padding: 36px 32px 24px 32px; text-align: center;">
                  <h2 style="margin: 0 0 10px 0; font-size: 22px; font-weight: 800; color: #1E1B18;">
                    Reset Your Password
                  </h2>
                  <p style="margin: 0 0 26px 0; font-size: 14px; line-height: 1.6; color: #7D6E63;">
                    Hi ${name || 'there'}, we received a request to reset your Vytra account password. Use the verification code below to proceed:
                  </p>

                  <!-- OTP Card -->
                  <div style="background: linear-gradient(180deg, #FDFBF9 0%, #F5EBE0 100%); border: 1.5px solid #D4A373; border-radius: 16px; padding: 22px 28px; margin: 0 auto 20px auto; display: inline-block; box-shadow: 0 4px 16px rgba(56, 36, 13, 0.05);">
                    <div style="font-size: 11px; text-transform: uppercase; letter-spacing: 1.5px; font-weight: 700; color: #7D6E63; margin-bottom: 10px;">
                      Verification Code
                    </div>
                    <div style="font-family: 'Courier New', Courier, monospace; font-size: 38px; font-weight: 900; letter-spacing: 12px; color: #38240D; padding-left: 12px;">
                      ${otp}
                    </div>
                  </div>

                  <!-- Expiry Badge -->
                  <div style="margin-bottom: 22px;">
                    <span style="display: inline-block; background-color: #FAF4EB; border: 1px solid #EFE4D2; border-radius: 20px; padding: 5px 14px; font-size: 12px; font-weight: 600; color: #9C6634;">
                      ⏱ Valid for 10 minutes
                    </span>
                  </div>

                  <p style="margin: 0; font-size: 13px; line-height: 1.5; color: #AFA59D;">
                    If you did not request a password reset, you can safely ignore this email. Your account remains completely secure.
                  </p>
                </td>
              </tr>

              <!-- Footer -->
              <tr>
                <td style="background-color: #FAF9F6; border-top: 1px solid #EFE9E1; padding: 20px 32px; text-align: center;">
                  <p style="margin: 0 0 4px 0; font-size: 12px; color: #7D6E63;">
                    Need help? Contact <a href="mailto:support@vytra.co.in" style="color: #38240D; font-weight: 700; text-decoration: underline;">support@vytra.co.in</a>
                  </p>
                  <p style="margin: 8px 0 0 0; font-size: 11px; color: #AFA59D;">
                    © ${new Date().getFullYear()} Vytra. Quick & Fresh Local Commerce.
                  </p>
                </td>
              </tr>
            </table>
          </td>
        </tr>
      </table>
    </body>
    </html>
    `;

    return this.sendMail({
      to,
      subject: `Your Vytra Password Reset Code: ${otp}`,
      html,
      text: `Your Vytra verification code is ${otp}. Valid for 10 minutes. Contact support@vytra.co.in if you did not request this.`,
    });
  }
}
