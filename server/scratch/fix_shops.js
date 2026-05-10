const mongoose = require('mongoose');

const MONGODB_URI = "mongodb://admin:Sayan%402005%23%40%24Pandit@ac-q0aewa9-shard-00-00.6vzcsvs.mongodb.net:27017,ac-q0aewa9-shard-00-01.6vzcsvs.mongodb.net:27017,ac-q0aewa9-shard-00-02.6vzcsvs.mongodb.net:27017/local_commerce?ssl=true&replicaSet=atlas-5qy1zz-shard-0&authSource=admin&retryWrites=true&w=majority";

const ShopSchema = new mongoose.Schema({
  name: String,
  category: String,
  rating: Number,
  imageUrl: String,
  description: String
}, { collection: 'shops' });

const UserSchema = new mongoose.Schema({
  name: String,
  role: String,
  businessName: String
}, { collection: 'users' });

async function fixMissingShops() {
  try {
    console.log('🔗 Connecting to MongoDB...');
    await mongoose.connect(MONGODB_URI);
    console.log('✅ Connected!');

    const User = mongoose.model('User', UserSchema);
    const Shop = mongoose.model('Shop', ShopSchema);

    // Find all shopkeepers
    const shopkeepers = await User.find({ role: 'Shopkeeper' });
    console.log(`🔍 Found ${shopkeepers.length} Shopkeepers.`);

    for (const sk of shopkeepers) {
      const shopName = sk.businessName || sk.name;
      
      // Check if shop already exists
      const exists = await Shop.findOne({ name: shopName });
      if (!exists) {
        console.log(`➕ Creating shop for: ${shopName}`);
        await new Shop({
          name: shopName,
          category: 'Grocery',
          rating: 4.8,
          imageUrl: 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&q=80&w=800',
          description: `Premium quality products at ${shopName}.`
        }).save();
      } else {
        console.log(`✔ Shop already exists for: ${shopName}`);
      }
    }

    console.log('🚀 Done! All Shopkeepers now have shops.');
    process.exit(0);
  } catch (err) {
    console.error('❌ Error:', err);
    process.exit(1);
  }
}

fixMissingShops();
