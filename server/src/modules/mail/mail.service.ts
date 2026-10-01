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
    <body style="margin: 0; padding: 0; background-color: #f7f9fc; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; color: #1f2937;">
      <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f7f9fc; padding: 32px 16px;">
        <tr>
          <td align="center">
            <table width="100%" cellpadding="0" cellspacing="0" style="max-width: 580px; background-color: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 24px rgba(0,0,0,0.06);">
              <!-- Header -->
              <tr>
                <td style="background: linear-gradient(135deg, #1e1b4b 0%, #312e81 50%, #4338ca 100%); padding: 36px 32px; text-align: center;">
                  <h1 style="margin: 0; font-size: 28px; font-weight: 800; letter-spacing: -0.5px; color: #ffffff;">
                    VYTRA
                  </h1>
                  <p style="margin: 8px 0 0 0; font-size: 14px; color: #c7d2fe; letter-spacing: 0.5px; text-transform: uppercase; font-weight: 600;">
                    Order Confirmation
                  </p>
                </td>
              </tr>

              <!-- Greeting & Summary -->
              <tr>
                <td style="padding: 32px 32px 24px 32px;">
                  <h2 style="margin: 0 0 8px 0; font-size: 20px; font-weight: 700; color: #111827;">
                    Thank you for your order, ${data.customerName || 'valued customer'}! 🎉
                  </h2>
                  <p style="margin: 0; font-size: 14px; line-height: 1.6; color: #4b5563;">
                    We have received your order <strong>#${shortId}</strong> and our team is already preparing it for delivery.
                  </p>
                </td>
              </tr>

              <!-- Order Details Card -->
              <tr>
                <td style="padding: 0 32px 24px 32px;">
                  <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f8fafc; border: 1px solid #e2e8f0; border-radius: 12px; padding: 16px 20px;">
                    <tr>
                      <td style="font-size: 13px; color: #64748b; font-weight: 600;">Order ID:</td>
                      <td style="font-size: 13px; color: #0f172a; font-weight: 700; text-align: right;">${data.orderId}</td>
                    </tr>
                    <tr>
                      <td style="font-size: 13px; color: #64748b; font-weight: 600; padding-top: 6px;">Status:</td>
                      <td style="font-size: 13px; color: #059669; font-weight: 700; text-align: right; padding-top: 6px;">Confirmed & Processing</td>
                    </tr>
                  </table>
                </td>
              </tr>

              <!-- Items Table -->
              <tr>
                <td style="padding: 0 32px 24px 32px;">
                  <table width="100%" cellpadding="0" cellspacing="0">
                    <thead>
                      <tr style="border-bottom: 2px solid #e2e8f0;">
                        <th style="padding: 8px 8px; font-size: 12px; text-transform: uppercase; color: #64748b; text-align: left;">Item</th>
                        <th style="padding: 8px 8px; font-size: 12px; text-transform: uppercase; color: #64748b; text-align: center;">Qty</th>
                        <th style="padding: 8px 8px; font-size: 12px; text-transform: uppercase; color: #64748b; text-align: right;">Amount</th>
                      </tr>
                    </thead>
                    <tbody>
                      ${itemsHtml}
                    </tbody>
                    <tfoot>
                      <tr>
                        <td colspan="2" style="padding: 16px 8px 4px 8px; font-size: 16px; font-weight: 700; color: #111827; text-align: right;">
                          Total:
                        </td>
                        <td style="padding: 16px 8px 4px 8px; font-size: 18px; font-weight: 800; color: #4338ca; text-align: right;">
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
                  <div style="background-color: #f1f5f9; border-radius: 12px; padding: 16px 20px;">
                    <div style="font-size: 12px; text-transform: uppercase; letter-spacing: 0.5px; font-weight: 700; color: #64748b; margin-bottom: 6px;">
                      📍 Delivery Address
                    </div>
                    <div style="font-size: 14px; color: #1e293b; line-height: 1.5;">
                      ${addressText}
                    </div>
                  </div>
                </td>
              </tr>

              <!-- Support Footer -->
              <tr>
                <td style="background-color: #f8fafc; border-top: 1px solid #e2e8f0; padding: 24px 32px; text-align: center;">
                  <p style="margin: 0 0 8px 0; font-size: 13px; color: #64748b;">
                    Need assistance or have questions about your delivery?
                  </p>
                  <p style="margin: 0; font-size: 13px; font-weight: 600; color: #4338ca;">
                    Contact us anytime at <a href="mailto:support@vytra.co.in" style="color: #4338ca; text-decoration: underline;">support@vytra.co.in</a>
                  </p>
                  <p style="margin: 16px 0 0 0; font-size: 11px; color: #94a3b8;">
                    © ${new Date().getFullYear()} Vytra. All rights reserved.
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
      <title>Welcome to Vytra</title>
    </head>
    <body style="margin: 0; padding: 0; background-color: #f7f9fc; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;">
      <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f7f9fc; padding: 32px 16px;">
        <tr>
          <td align="center">
            <table width="100%" cellpadding="0" cellspacing="0" style="max-width: 580px; background-color: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 24px rgba(0,0,0,0.06);">
              <tr>
                <td style="background: linear-gradient(135deg, #1e1b4b 0%, #312e81 50%, #4338ca 100%); padding: 36px 32px; text-align: center;">
                  <h1 style="margin: 0; font-size: 28px; font-weight: 800; letter-spacing: -0.5px; color: #ffffff;">
                    VYTRA
                  </h1>
                </td>
              </tr>
              <tr>
                <td style="padding: 32px;">
                  <h2 style="margin: 0 0 12px 0; font-size: 22px; color: #111827;">
                    Welcome to Vytra, ${name || 'Friend'}! 🚀
                  </h2>
                  <p style="margin: 0 0 16px 0; font-size: 15px; line-height: 1.6; color: #4b5563;">
                    Your account has been successfully created. With Vytra, you get fast, reliable local commerce, instant order updates, and verified merchants delivered straight to your doorstep.
                  </p>
                  <p style="margin: 0 0 24px 0; font-size: 15px; line-height: 1.6; color: #4b5563;">
                    Get the latest app releases anytime at <a href="https://download.vytra.co.in" style="color: #4338ca; font-weight: 600; text-decoration: none;">download.vytra.co.in</a>.
                  </p>
                  <div style="background-color: #f1f5f9; border-radius: 12px; padding: 16px 20px;">
                    <p style="margin: 0; font-size: 13px; color: #475569;">
                      Need help? Reach out directly to our support team at <a href="mailto:support@vytra.co.in" style="color: #4338ca; font-weight: 600;">support@vytra.co.in</a>.
                    </p>
                  </div>
                </td>
              </tr>
              <tr>
                <td style="background-color: #f8fafc; border-top: 1px solid #e2e8f0; padding: 20px 32px; text-align: center;">
                  <p style="margin: 0; font-size: 11px; color: #94a3b8;">
                    © ${new Date().getFullYear()} Vytra. All rights reserved.
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
      subject: 'Welcome to Vytra! 🚀',
      html,
      text: `Welcome to Vytra, ${name}! Your account is active. Visit download.vytra.co.in for the mobile app, or contact support@vytra.co.in if you need anything.`,
    });
  }

  /**
   * Order Status Update Email
   */
  async sendOrderStatusUpdate(to: string, data: OrderStatusData): Promise<boolean> {
    const shortId = data.orderId.slice(-8).toUpperCase();
    const html = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <title>Order Status Update - Vytra</title>
    </head>
    <body style="margin: 0; padding: 0; background-color: #f7f9fc; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;">
      <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f7f9fc; padding: 32px 16px;">
        <tr>
          <td align="center">
            <table width="100%" cellpadding="0" cellspacing="0" style="max-width: 580px; background-color: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 24px rgba(0,0,0,0.06);">
              <tr>
                <td style="background: linear-gradient(135deg, #1e1b4b 0%, #312e81 50%, #4338ca 100%); padding: 32px; text-align: center;">
                  <h1 style="margin: 0; font-size: 26px; font-weight: 800; color: #ffffff;">VYTRA</h1>
                  <p style="margin: 6px 0 0 0; font-size: 13px; color: #c7d2fe; text-transform: uppercase;">Order Status Update</p>
                </td>
              </tr>
              <tr>
                <td style="padding: 32px;">
                  <h2 style="margin: 0 0 8px 0; font-size: 20px; color: #111827;">
                    Hi ${data.customerName || 'there'},
                  </h2>
                  <p style="margin: 0 0 20px 0; font-size: 15px; color: #4b5563;">
                    Your order <strong>#${shortId}</strong> status has been updated to:
                  </p>
                  <div style="background-color: #eef2ff; border-left: 4px solid #4f46e5; padding: 14px 18px; border-radius: 8px; margin-bottom: 24px;">
                    <span style="font-size: 18px; font-weight: 700; color: #3730a3;">${data.status}</span>
                  </div>
                  <p style="margin: 0; font-size: 13px; color: #64748b;">
                    If you have questions regarding this order, reach out to us at <a href="mailto:support@vytra.co.in" style="color: #4338ca;">support@vytra.co.in</a>.
                  </p>
                </td>
              </tr>
              <tr>
                <td style="background-color: #f8fafc; border-top: 1px solid #e2e8f0; padding: 16px 32px; text-align: center;">
                  <p style="margin: 0; font-size: 11px; color: #94a3b8;">
                    © ${new Date().getFullYear()} Vytra. All rights reserved.
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
      <title>Password Reset Code - Vytra</title>
    </head>
    <body style="margin: 0; padding: 0; background-color: #f7f9fc; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; color: #1f2937;">
      <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f7f9fc; padding: 32px 16px;">
        <tr>
          <td align="center">
            <table width="100%" cellpadding="0" cellspacing="0" style="max-width: 540px; background-color: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 24px rgba(0,0,0,0.06);">
              <!-- Header -->
              <tr>
                <td style="background: linear-gradient(135deg, #1e1b4b 0%, #312e81 50%, #4338ca 100%); padding: 32px; text-align: center;">
                  <h1 style="margin: 0; font-size: 26px; font-weight: 800; letter-spacing: -0.5px; color: #ffffff;">
                    VYTRA
                  </h1>
                  <p style="margin: 6px 0 0 0; font-size: 13px; color: #c7d2fe; letter-spacing: 0.5px; text-transform: uppercase; font-weight: 600;">
                    Password Recovery
                  </p>
                </td>
              </tr>

              <!-- Content -->
              <tr>
                <td style="padding: 32px 32px 20px 32px; text-align: center;">
                  <h2 style="margin: 0 0 12px 0; font-size: 22px; font-weight: 700; color: #111827;">
                    Reset Your Password
                  </h2>
                  <p style="margin: 0 0 24px 0; font-size: 14px; line-height: 1.6; color: #4b5563;">
                    Hi ${name || 'there'}, we received a request to reset your Vytra account password. Use the 6-digit verification code below to continue:
                  </p>

                  <!-- OTP Box -->
                  <div style="background-color: #eef2ff; border: 2px dashed #6366f1; border-radius: 12px; padding: 20px; margin: 0 auto 24px auto; display: inline-block;">
                    <span style="font-family: 'Courier New', Courier, monospace; font-size: 34px; font-weight: 800; letter-spacing: 10px; color: #3730a3; padding-left: 10px;">
                      ${otp}
                    </span>
                  </div>

                  <p style="margin: 0 0 12px 0; font-size: 13px; color: #dc2626; font-weight: 600;">
                    ⏱ This verification code is valid for 10 minutes.
                  </p>
                  <p style="margin: 0; font-size: 13px; line-height: 1.5; color: #64748b;">
                    If you did not request a password reset, you can safely disregard this email. Your password will remain unchanged.
                  </p>
                </td>
              </tr>

              <!-- Footer -->
              <tr>
                <td style="background-color: #f8fafc; border-top: 1px solid #e2e8f0; padding: 20px 32px; text-align: center;">
                  <p style="margin: 0 0 4px 0; font-size: 12px; color: #64748b;">
                    Need help? Contact <a href="mailto:support@vytra.co.in" style="color: #4338ca; text-decoration: underline;">support@vytra.co.in</a>
                  </p>
                  <p style="margin: 8px 0 0 0; font-size: 11px; color: #94a3b8;">
                    © ${new Date().getFullYear()} Vytra. All rights reserved.
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
