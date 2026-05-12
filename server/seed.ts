import mongoose from 'mongoose';

const MONGODB_URI = "mongodb://admin:Sayan%402005%23%40%24Pandit@ac-q0aewa9-shard-00-00.6vzcsvs.mongodb.net:27017,ac-q0aewa9-shard-00-01.6vzcsvs.mongodb.net:27017,ac-q0aewa9-shard-00-02.6vzcsvs.mongodb.net:27017/local_commerce?ssl=true&replicaSet=atlas-5qy1zz-shard-0&authSource=admin&retryWrites=true&w=majority";

async function seed() {
  await mongoose.connect(MONGODB_URI);
  console.log('Connected to MongoDB');

  const User = mongoose.connection.collection('users');
  const Order = mongoose.connection.collection('orders');

  const user = await User.findOne({ email: 'sayanpandit@gmail.com' }) || await User.findOne({});
  if (!user) {
    console.log('No users found to associate orders with.');
    process.exit(0);
  }

  console.log(`Adding orders for user: ${user.email} (${user._id})`);

  const dummyOrders = [
    {
      userId: user._id,
      items: [
        { productId: new mongoose.Types.ObjectId(), name: "Organic Basmati Rice", quantity: 2, price: 550, unit: "5kg" },
        { productId: new mongoose.Types.ObjectId(), name: "Farm Fresh Milk", quantity: 3, price: 65, unit: "1L" }
      ],
      totalAmount: 1295,
      deliveryAddress: "123 Green Valley, Sector 5, Kolkata",
      status: "Delivered",
      createdAt: new Date(Date.now() - 86400000 * 2), // 2 days ago
    },
    {
      userId: user._id,
      items: [
        { productId: new mongoose.Types.ObjectId(), name: "Premium Whole Wheat", quantity: 1, price: 420, unit: "10kg" }
      ],
      totalAmount: 420,
      deliveryAddress: "123 Green Valley, Sector 5, Kolkata",
      status: "Processing",
      createdAt: new Date(),
    },
    {
      userId: user._id,
      items: [
        { productId: new mongoose.Types.ObjectId(), name: "Lays Classic Party Pack", quantity: 5, price: 50, unit: "80g" },
        { productId: new mongoose.Types.ObjectId(), name: "Coca Cola", quantity: 2, price: 95, unit: "2L" }
      ],
      totalAmount: 440,
      deliveryAddress: "123 Green Valley, Sector 5, Kolkata",
      status: "Shipped",
      createdAt: new Date(Date.now() - 3600000 * 5), // 5 hours ago
    },
    {
      userId: user._id,
      items: [
        { productId: new mongoose.Types.ObjectId(), name: "Surf Excel Matic", quantity: 1, price: 1150, unit: "4kg" },
        { productId: new mongoose.Types.ObjectId(), name: "Vim Dishwash Gel", quantity: 1, price: 155, unit: "500ml" }
      ],
      totalAmount: 1305,
      deliveryAddress: "789 Blue Ridge, Salt Lake, Kolkata",
      status: "Cancelled",
      createdAt: new Date(Date.now() - 86400000 * 5), // 5 days ago
    }
  ];

  await Order.insertMany(dummyOrders);
  console.log('Successfully added 2 dummy orders.');

  await mongoose.disconnect();
}

seed().catch(console.error);
