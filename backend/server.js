import express from 'express';
import mongoose from 'mongoose';
import dotenv from 'dotenv';
import cors from 'cors';
import cron from 'node-cron';

import authRoutes from './routes/auth.js';
import User from './models/user.js';
import { generateRandomCode } from './utils/codeGenerator.js';

dotenv.config();

const app = express();

// --- Middleware ---
app.use(express.json());

// ✅ Allow only specific origins
const allowedOrigins = [
  'http://172.16.17.5:3000',
  'http://192.168.0.105:3000',
  'http://localhost:3000'
];

app.use(
  cors({
    origin: function (origin, callback) {
      // Allow requests with no origin (like mobile apps or curl)
      if (!origin || allowedOrigins.includes(origin)) {
        return callback(null, true);
      }
      return callback(new Error('Not allowed by CORS'));
    },
    methods: ['GET', 'POST'],
    credentials: true,
  })
);

// --- Database Connection ---
mongoose
  .connect(process.env.MONGO_URI, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
  })
  .then(() => console.log('✅ MongoDB Connected'))
  .catch((err) => console.error('❌ MongoDB connection error:', err));

// --- Routes ---
app.use('/api/auth', authRoutes);

// --- Cron Job: runs every 30 seconds ---
cron.schedule('*/30 * * * * *', async () => {
  try {
    const users = await User.find();
    for (const user of users) {
      user.authCode = generateRandomCode();
      await user.save();
      console.log(`🔄 Updated ${user.username} → ${user.authCode}`);
    }
  } catch (err) {
    console.error('❌ Error updating auth codes:', err);
  }
});

// --- Start Server ---
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`🚀 Server running on port ${PORT}`));
