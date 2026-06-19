import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type UserDocument = User & Document;

@Schema({ timestamps: true })
export class User {
  @Prop({ required: true })
  name: string;

  @Prop({ required: true, unique: true, lowercase: true })
  email: string;

  @Prop({ required: true, select: false })
  password: string;

  @Prop({ required: true, enum: ['Customer', 'Shopkeeper', 'Distributor', 'Admin'], default: 'Customer' })
  role: string;

  @Prop()
  businessName?: string;

  @Prop()
  phone?: string;

  @Prop({ type: [{ type: Object }] })
  addresses: any[];

  @Prop({ default: true })
  isActive: boolean;

  @Prop({ select: false })
  refreshTokenHash?: string;
}

export const UserSchema = SchemaFactory.createForClass(User);
