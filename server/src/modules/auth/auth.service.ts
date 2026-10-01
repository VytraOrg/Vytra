import { Injectable, UnauthorizedException, ConflictException, BadRequestException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import * as bcrypt from 'bcrypt';
import { User, UserDocument } from '../users/schemas/user.schema';
import { Shop, ShopDocument } from '../shops/schemas/shop.schema';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { MailService } from '../mail/mail.service';

@Injectable()
export class AuthService {
  constructor(
    @InjectModel(User.name) private userModel: Model<UserDocument>,
    @InjectModel(Shop.name) private shopModel: Model<ShopDocument>,
    private jwtService: JwtService,
    private mailService: MailService,
  ) {}

  async register(registerDto: RegisterDto) {
    const { email, password, role, name, businessName } = registerDto;
    
    if (role === 'Admin') {
      throw new BadRequestException('Registration of Admin accounts is not permitted');
    }
    
    const existingUser = await this.userModel.findOne({ email });
    if (existingUser) {
      throw new ConflictException('Email already exists');
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const user = new this.userModel({
      ...registerDto,
      password: hashedPassword,
    });

    await user.save();

    // AUTO-CREATE SHOP IF ROLE IS SHOPKEEPER OR DISTRIBUTOR
    if (role === 'Shopkeeper' || role === 'Distributor') {
      const shopType = role === 'Shopkeeper' ? 'Retailer' : 'Distributor';
      
      const newShop = new this.shopModel({
        owner: user._id,
        name: businessName || name,
        category: 'Grocery', 
        shopType: shopType,
        rating: 4.5,
        imageUrl: role === 'Shopkeeper' 
          ? 'https://images.unsplash.com/photo-1534723452862-4c874018d66d?auto=format&fit=crop&q=80&w=800'
          : 'https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?auto=format&fit=crop&q=80&w=800',
        description: `Welcome to ${businessName || name}'s premium ${shopType === 'Retailer' ? 'store' : 'distribution center'}.`,
      });
      await newShop.save();
    }

    // Fire welcome email asynchronously
    this.mailService.sendWelcome(user.email, user.name).catch(() => {});

    return this.generateToken(user);
  }

  async login(loginDto: LoginDto) {
    const { email, password, role } = loginDto;
    
    const user = await this.userModel.findOne({ email }).select('+password');
    if (!user || !user.password) {
      throw new UnauthorizedException('Invalid credentials');
    }

    let isMatch = false;
    try {
      isMatch = await bcrypt.compare(password, user.password);
    } catch (e) {
      // Handle potential hash format errors
      throw new UnauthorizedException('Authentication failed. Please check your credentials or reset your password.');
    }

    if (!isMatch) {
      throw new UnauthorizedException('Invalid credentials');
    }

    if (user.role !== role) {
      throw new UnauthorizedException('Invalid role for this user');
    }

    return this.generateToken(user);
  }

  async refresh(token: string) {
    try {
      const payload = this.jwtService.verify(token);
      if (payload.tokenType !== 'refresh') {
        throw new UnauthorizedException('Invalid token type');
      }

      const user = await this.userModel.findById(payload.sub).select('+refreshTokenHash');
      if (!user || !user.isActive || !user.refreshTokenHash) {
        throw new UnauthorizedException('Session expired or user inactive');
      }

      const isMatch = await bcrypt.compare(token, user.refreshTokenHash);
      if (!isMatch) {
        throw new UnauthorizedException('Invalid session');
      }

      return this.generateToken(user);
    } catch (e) {
      throw new UnauthorizedException('Invalid or expired refresh token');
    }
  }

  async logout(userId: string) {
    const user = await this.userModel.findById(userId);
    if (user) {
      user.refreshTokenHash = null as any;
      await user.save();
    }
    return { success: true };
  }

  async updateProfile(
    userId: string,
    updateDto: { phone?: string; imageUrl?: string; name?: string; businessName?: string },
  ) {
    const user = await this.userModel.findById(userId);
    if (!user) {
      throw new BadRequestException('User not found');
    }

    if (updateDto.phone !== undefined) user.phone = updateDto.phone;
    if (updateDto.imageUrl !== undefined) user.imageUrl = updateDto.imageUrl;
    if (updateDto.name !== undefined) user.name = updateDto.name;
    if (updateDto.businessName !== undefined) user.businessName = updateDto.businessName;

    await user.save();

    return {
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
        businessName: user.businessName,
        phone: user.phone || '',
        imageUrl: user.imageUrl || '',
      },
    };
  }

  private async generateToken(user: UserDocument) {
    const payload = { sub: user._id, email: user.email, role: user.role, tokenType: 'access' };
    const refreshPayload = { sub: user._id, tokenType: 'refresh' };

    const accessToken = this.jwtService.sign(payload);
    const refreshToken = this.jwtService.sign(refreshPayload, {
      expiresIn: '7d',
    });

    user.refreshTokenHash = await bcrypt.hash(refreshToken, 10);
    await user.save();

    return {
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
        businessName: user.businessName,
        phone: user.phone || '',
        imageUrl: user.imageUrl || '',
      },
      access_token: accessToken,
      refresh_token: refreshToken,
    };
  }
}
