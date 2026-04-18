const dns = require('dns');
dns.setServers(['8.8.8.8', '8.8.4.4', '1.1.1.1']);
const mongoose = require('mongoose');

// EXACT Backend Schemas match
const EventSchema = new mongoose.Schema({
  name: String,
  description: String,
  bannerUrl: String,
  venue: String,
  eventDates: [String],
  status: { type: String, default: 'published' },
  isActive: { type: Boolean, default: true },
  ticketPricing: Object,
}, { timestamps: true });

const ZoneSchema = new mongoose.Schema({
  name: String,
  eventId: mongoose.Schema.Types.ObjectId,
  capacity: Number,
  available: Number,
  price: Number,
  type: String, // daily/season
  color: String,
  currentCount: { type: Number, default: 0 },
  isActive: { type: Boolean, default: true },
  allowedTicketCategories: [String],
  features: [String],
}, { timestamps: true });

const UserSchema = new mongoose.Schema({
  phoneNumber: String,
  name: String,
  role: { type: String, default: 'user' },
  isVerified: { type: Boolean, default: false },
}, { timestamps: true });

async function seed() {
  const MONGO_URI = 'mongodb+srv://aashishofficial123_db_user:AV445S3k0brlHEPu@cluster0.q0seg1w.mongodb.net/event_app';
  
  try {
    console.log('Connecting to database...');
    await mongoose.connect(MONGO_URI);
    
    console.log('Cleaning up old data...');
    await mongoose.connection.db.collection('events').deleteMany({});
    await mongoose.connection.db.collection('zones').deleteMany({});
    await mongoose.connection.db.collection('users').deleteMany({});

    const Event = mongoose.model('Event', EventSchema);
    const Zone = mongoose.model('Zone', ZoneSchema);
    const User = mongoose.model('User', UserSchema);

    // 0. Create Admin User
    console.log('Seeding Admin User...');
    const admin = await User.create({
      phoneNumber: '+919999999999',
      name: 'Super Admin',
      role: 'admin',
      isVerified: true
    });
    console.log('Seeding Published Event...');
    const event = await Event.create({
      name: 'Maha Navratri Mahotsav 2024',
      description: 'The biggest Garba festival of Gujarat featuring top artists, massive dance floors, and authentic food stalls.',
      venue: 'GMDC Ground, Ahmedabad',
      bannerUrl: 'https://images.unsplash.com/photo-1582555172866-f73bb12a2ab3?w=800',
      eventDates: ['2024-10-03', '2024-10-04', '2024-10-05', '2024-10-06'],
      status: 'published',
      isActive: true,
      createdBy: admin._id,
      // Frontend ko ye pricing data chahiye hoga
      ticketPricing: {
        regular: { 'General': 500, 'VIP': 2500 },
        season: { 'Player': 8000 }
      }
    });

    // 2. Create Zones (Backend style)
    console.log('Seeding Zones...');
    const zones = [
      {
        name: 'General - Daily',
        eventId: event._id,
        capacity: 5000,
        available: 4850,
        price: 500,
        type: 'daily',
        color: '#FF0080',
        allowedTicketCategories: ['General'],
        features: ['Main Ground Access', 'Food Court Access', 'Standard Security']
      },
      {
        name: 'VIP - Platinum Row',
        eventId: event._id,
        capacity: 1000,
        available: 920,
        price: 2500,
        type: 'daily',
        color: '#7928CA',
        allowedTicketCategories: ['VIP'],
        features: ['Front Stage Access', 'Express Entry', 'Water & Snacks Included']
      },
      {
        name: 'Season Pass (9 Nights)',
        eventId: event._id,
        capacity: 2000,
        available: 1840,
        price: 8000,
        type: 'season',
        color: '#FFD700',
        allowedTicketCategories: ['Player'],
        features: ['9 Days Entry', 'Special ID Card', 'Dedicated Entry Gate', 'Player Zone Access']
      },
      {
        name: 'VVIP Royal Sofa',
        eventId: event._id,
        capacity: 200,
        available: 156,
        price: 15000,
        type: 'daily',
        color: '#FF6B35',
        allowedTicketCategories: ['VVIP'],
        features: ['Sofa Seating', 'Dinner Buffet', 'Valet Parking', 'Artist Meet & Greet (Lucky Winners)']
      }
    ];
    await Zone.insertMany(zones);

    console.log('\n✅ SEEDING COMPLETE!');
    console.log('Event Name: ' + event.name);
    console.log('Event Status: ' + event.status);
    
    process.exit(0);
  } catch (err) {
    console.error('❌ SEEDING FAILED:', err);
    process.exit(1);
  }
}

seed();
