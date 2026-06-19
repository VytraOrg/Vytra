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

  @Prop({ required: true, enum: ['Unverified', 'Incomplete', 'Pending', 'Under Review', 'Changes Requested', 'Verified', 'Rejected'], default: 'Incomplete' })
  verificationStatus: string;

  @Prop()
  gstCertificateUrl?: string;

  @Prop()
  tradeLicenseUrl?: string;

  @Prop()
  verificationRejectedReason?: string;

  @Prop()
  verificationRejectedNotes?: string;

  // New Fields for Owner Info
  @Prop()
  ownerName?: string;

  @Prop()
  ownerPhone?: string;

  // New Fields for Address Info
  @Prop()
  address?: string;

  @Prop()
  district?: string;

  @Prop()
  state?: string;

  @Prop()
  pincode?: string;

  // New Fields for Doc Numbers
  @Prop()
  gstNumber?: string;

  @Prop()
  tradeLicenseNumber?: string;

  // New Fields for Admin Review details
  @Prop()
  verificationNotes?: string;

  @Prop()
  changesRequestedDetails?: string;
}

export const ShopSchema = SchemaFactory.createForClass(Shop);
ShopSchema.index({ location: '2dsphere' }); // Enable Geospatial Search
ShopSchema.index({ owner: 1 }, { unique: true });
ShopSchema.index({ status: 1, category: 1 });
