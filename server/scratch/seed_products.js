const mongoose = require('mongoose');

const MONGODB_URI = "mongodb://admin:Sayan%402005%23%40%24Pandit@ac-q0aewa9-shard-00-00.6vzcsvs.mongodb.net:27017,ac-q0aewa9-shard-00-01.6vzcsvs.mongodb.net:27017,ac-q0aewa9-shard-00-02.6vzcsvs.mongodb.net:27017/local_commerce?ssl=true&replicaSet=atlas-5qy1zz-shard-0&authSource=admin&retryWrites=true&w=majority";

const ProductSchema = new mongoose.Schema({}, { collection: 'products', strict: false });
const ShopSchema = new mongoose.Schema({}, { collection: 'shops', strict: false });

async function seedProducts() {
  try {
    await mongoose.connect(MONGODB_URI);
    const Product = mongoose.model('Product', ProductSchema);
    const Shop = mongoose.model('Shop', ShopSchema);

    const shops = await Shop.find({});
    
    const productData = [
      {
        shopName: "Guddu Enterprise",
        items: [
          { name: "Basmati Rice", price: 85, unit: "kg", category: "Staples", images: ["https://images.unsplash.com/photo-1586201375761-83865001e31c?q=80&w=400"] },
          { name: "Arhar Dal", price: 120, unit: "kg", category: "Staples", images: ["https://images.unsplash.com/photo-1547050605-2f260ec3391d?q=80&w=400"] },
          { name: "Tata Salt", price: 28, unit: "kg", category: "Staples", images: ["https://images.unsplash.com/photo-1610450535251-24957e84f5f8?q=80&w=400"] }
        ]
      },
      {
        shopName: "Snack Corner",
        items: [
          { name: "Lays Classic", price: 20, unit: "Packet", category: "Snacks", images: ["https://images.unsplash.com/photo-1566478989037-eec170784d0b?q=80&w=400"] },
          { name: "Kurkure Masala", price: 20, unit: "Packet", category: "Snacks", images: ["https://images.unsplash.com/photo-1621447509323-5705b5ff7f3e?q=80&w=400"] },
          { name: "Oreo Biscuits", price: 35, unit: "Packet", category: "Snacks", images: ["https://images.unsplash.com/photo-1558961363-fa8fdf82db35?q=80&w=400"] }
        ]
      },
      {
        shopName: "City Pharmacy",
        items: [
          { name: "Dolo 650", price: 30, unit: "Strip", category: "Household", images: ["https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?q=80&w=400"] },
          { name: "Hand Sanitizer", price: 50, unit: "Bottle", category: "Household", images: ["https://images.unsplash.com/photo-1584483766114-2ace6bdf2401?q=80&w=400"] }
        ]
      },
      {
        shopName: "Fresh Fruits Market",
        items: [
          { name: "Red Apple", price: 180, unit: "kg", category: "Veggies", images: ["https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?q=80&w=400"] },
          { name: "Fresh Banana", price: 60, unit: "Dozen", category: "Veggies", images: ["https://images.unsplash.com/photo-1571771894821-ad9902d83f4a?q=80&w=400"] }
        ]
      },
      {
        shopName: "Sayan's Premium Store",
        items: [
          { name: "Organic A2 Milk", price: 95, unit: "Litre", category: "Dairy", images: ["https://images.unsplash.com/photo-1550583724-1255818c0533?q=80&w=400"] },
          { name: "Desi Ghee", price: 650, unit: "kg", category: "Dairy", images: ["https://images.unsplash.com/photo-1589927986089-35812388d1f4?q=80&w=400"] },
          { name: "Pure Forest Honey", price: 450, unit: "Bottle", category: "Staples", images: ["https://images.unsplash.com/photo-1587049352846-4a222e784d38?q=80&w=400"] }
        ]
      }
    ];

    await Product.deleteMany({});
    
    const finalProducts = [];
    for (const group of productData) {
      const shop = shops.find(s => s.name === group.shopName);
      if (shop) {
        for (const item of group.items) {
          finalProducts.push({
            ...item,
            shop: shop._id,
            isAvailable: true,
            description: `Quality ${item.name} from ${shop.name}`
          });
        }
      }
    }

    await Product.insertMany(finalProducts);
    console.log(`✅ ${finalProducts.length} unique products seeded across ${productData.length} shops.`);
    process.exit(0);
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
}

seedProducts();
