import express from 'express';
import mongoose from 'mongoose';
import dotenv from 'dotenv';
import authRoutes from './routes/auth.js';
import cron from 'node-cron';
import User from './models/user.js';
import { generateRandomCode } from './utils/codeGenerator.js';
import cors from 'cors';


dotenv.config();

const app = express();
app.use(express.json());

app.use(cors({
  origin: 'http://172.16.12.9:3000', // or '*' to allow all origins
  methods: ['GET', 'POST'],
  credentials: true, // if sending cookies
}));
mongoose.connect(process.env.MONGO_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
}).then(() => {
  console.log("✅ MongoDB Connected");
}).catch(err => {
  console.error("MongoDB connection error:", err);
});

app.use('/api/auth', authRoutes);

// Cron job: runs every 30 seconds
cron.schedule('*/30 * * * * *', async () => {
  try {
    const users = await User.find();

    for (const user of users) {
      const newCode = generateRandomCode();
      user.authCode = newCode;
      await user.save();
      console.log(`✅ User ${user.username} authCode updated to ${newCode}`);
    }
  } catch (err) {
    console.error('Error updating auth codes:', err);
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
});



