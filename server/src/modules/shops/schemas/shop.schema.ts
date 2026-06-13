import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type ShopDocument = Shop & Document;

@Schema({ timestamps: true })
export class Shop {
  @Prop({ required: true })
  name: string;

  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  owner: Types.ObjectId;

  @Prop({ required: true })
  category: string;

  @Prop({ required: true, enum: ['Retailer', 'Distributor'], default: 'Retailer' })
  shopType: string;

  @Prop()
  description: string;

  @Prop()
  imageUrl: string;

  @Prop({
    type: {
      type: String,
      enum: ['Point'],
      default: 'Point',
    },
    coordinates: {
      type: [Number],
      default: [0, 0],
    },
  })
  location: {
    type: string;
    coordinates: number[];
  };

  @Prop({ default: 0 })
  rating: number;

  @Prop({ default: 0 })
  totalReviews: number;

  @Prop({ default: 'Open' })
  status: string;

  @Prop({ required: true, enum: ['Unverified', 'Pending', 'Verified', 'Rejected'], default: 'Unverified' })
  verificationStatus: string;

  @Prop()
  gstCertificateUrl?: string;

  @Prop()
  tradeLicenseUrl?: string;
}

export const ShopSchema = SchemaFactory.createForClass(Shop);
ShopSchema.index({ location: '2dsphere' }); // Enable Geospatial Search
