const mongoose = require('mongoose');

const MONGODB_URI = "mongodb://admin:Sayan%402005%23%40%24Pandit@ac-q0aewa9-shard-00-00.6vzcsvs.mongodb.net:27017,ac-q0aewa9-shard-00-01.6vzcsvs.mongodb.net:27017,ac-q0aewa9-shard-00-02.6vzcsvs.mongodb.net:27017/local_commerce?ssl=true&replicaSet=atlas-5qy1zz-shard-0&authSource=admin&retryWrites=true&w=majority";

const ShopSchema = new mongoose.Schema({}, { collection: 'shops', strict: false });

async function updateShopTypes() {
  try {
    await mongoose.connect(MONGODB_URI);
    const Shop = mongoose.model('Shop', ShopSchema);

    // Set most to Retailer
    await Shop.updateMany({}, { $set: { shopType: 'Retailer' } });

    // Set Snack Corner to Distributor for B2B testing
    await Shop.updateOne({ name: 'Snack Corner' }, { $set: { shopType: 'Distributor' } });
    
    console.log('✅ Shops categorized into Retailers and Distributors.');
    process.exit(0);
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
}

updateShopTypes();
