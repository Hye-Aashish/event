const dns = require('dns');
const mongoose = require('mongoose');

// Force Google's DNS to bypass ISP DNS blocking
dns.setServers(['8.8.8.8', '8.8.4.4', '1.1.1.1']);

const URI = "mongodb+srv://aashishofficial123_db_user:AV445S3k0brlHEPu@cluster0.q0seg1w.mongodb.net/event_app?retryWrites=true&w=majority&appName=Cluster0";

async function testConnection() {
  console.log('🔍 Resolving SRV with Google DNS (8.8.8.8)...');
  
  try {
    await new Promise((resolve, reject) => {
      dns.resolveSrv('_mongodb._tcp.cluster0.q0seg1w.mongodb.net', (err, addresses) => {
        if (err) {
          console.error('❌ SRV still failing:', err.message);
          reject(err);
        } else {
          console.log('✅ SRV Resolved:', JSON.stringify(addresses));
          resolve(addresses);
        }
      });
    });
    
    console.log('\n🔗 Connecting to Atlas...');
    await mongoose.connect(URI, {
      serverSelectionTimeoutMS: 10000,
      socketTimeoutMS: 45000,
    });
    console.log('✅ SUCCESS! MongoDB Atlas Connected!');
    console.log('DB Name:', mongoose.connection.name);
    await mongoose.disconnect();
    process.exit(0);
    
  } catch (err) {
    console.error('\n❌ Connection Error:', err.message);
    process.exit(1);
  }
}

testConnection();
