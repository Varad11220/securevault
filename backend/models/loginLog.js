import mongoose from 'mongoose';

const loginLogSchema = new mongoose.Schema({
  userId: { type: Number, required: true },
  username: { type: String, required: true },
  timestamp: { type: Date, default: Date.now },
  ip_address: { type: String, required: true },
  user_agent: { type: String, required: true },
  success: { type: Boolean, required: true }
});

export default mongoose.models.LoginLog || mongoose.model('LoginLog', loginLogSchema);
