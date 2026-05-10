const { MongoClient } = require('mongodb');

async function run() {
  const uri = 'mongodb+srv://admin:Sayan%402005%23%40%24Pandit@local-commerce-cluster.6vzcsvs.mongodb.net/local_commerce?retryWrites=true&w=majority&appName=local-commerce-cluster';
  const client = new MongoClient(uri);
  try {
    await client.connect();
    const db = client.db('local_commerce');
    const result = await db.collection('shops').updateOne(
      { name: 'Snack Corner' },
      { $set: { shopType: 'Retailer' } }
    );
    console.log('Updated Snack Corner to Retailer:', result.modifiedCount);
  } finally {
    await client.close();
  }
}
run().catch(console.dir);
