import { Injectable, UnauthorizedException, ConflictException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import * as bcrypt from 'bcrypt';
import { User, UserDocument } from '../users/schemas/user.schema';
import { Shop, ShopDocument } from '../shops/schemas/shop.schema';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';

@Injectable()
export class AuthService {
  constructor(
    @InjectModel(User.name) private userModel: Model<UserDocument>,
    @InjectModel(Shop.name) private shopModel: Model<ShopDocument>,
    private jwtService: JwtService,
  ) {}

  async register(registerDto: RegisterDto) {
    const { email, password, role, name, businessName } = registerDto;
    
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

  async promoteToAdmin(email: string) {
    const result = await this.userModel.updateOne({ email }, { role: 'Admin' });
    return { success: result.modifiedCount > 0 };
  }

  private generateToken(user: UserDocument) {
    const payload = { sub: user._id, email: user.email, role: user.role };
    return {
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
        businessName: user.businessName,
      },
      access_token: this.jwtService.sign(payload),
    };
  }
}
