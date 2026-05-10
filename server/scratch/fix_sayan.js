const mongoose = require('mongoose');

const MONGODB_URI = "mongodb://admin:Sayan%402005%23%40%24Pandit@ac-q0aewa9-shard-00-00.6vzcsvs.mongodb.net:27017,ac-q0aewa9-shard-00-01.6vzcsvs.mongodb.net:27017,ac-q0aewa9-shard-00-02.6vzcsvs.mongodb.net:27017/local_commerce?ssl=true&replicaSet=atlas-5qy1zz-shard-0&authSource=admin&retryWrites=true&w=majority";

const UserSchema = new mongoose.Schema({}, { collection: 'users', strict: false });
const ShopSchema = new mongoose.Schema({
  name: String,
  category: String,
  rating: Number,
  imageUrl: String,
  description: String
}, { collection: 'shops' });

async function fixSayanAccount() {
  try {
    await mongoose.connect(MONGODB_URI);
    const User = mongoose.model('User', UserSchema);
    const Shop = mongoose.model('Shop', ShopSchema);

    // 1. Fix the role casing
    const result = await User.updateOne(
      { email: 'sayan@gmail.com' },
      { $set: { role: 'Shopkeeper' } }
    );
    console.log('✅ Updated role casing for sayan@gmail.com');

    // 2. Create the shop
    const shopName = "Sayan's Premium Store";
    const exists = await Shop.findOne({ name: shopName });
    if (!exists) {
      await new Shop({
        name: shopName,
        category: 'Electronics',
        rating: 4.9,
        imageUrl: 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?auto=format&fit=crop&q=80&w=800',
        description: 'High-quality electronics and gadgets by Sayan.'
      }).save();
      console.log(`✅ Created shop: ${shopName}`);
    }

    process.exit(0);
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
}

fixSayanAccount();
