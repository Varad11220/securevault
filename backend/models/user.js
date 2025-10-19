import mongoose from 'mongoose';

const userSchema = new mongoose.Schema({
  userId: { type: Number, unique: true, required: true },
  username: { type: String, unique: true, required: true },
  email: { type: String, unique: true, required: true },
  password: { type: String, required: true },
  authCode: { type: String, default: '' },
  biometricLogin: {
    status: { type: String, enum: ['none', 'pending', 'approved', 'denied'], default: 'none' },
    requestedAt: { type: Date },
    sessionId: { type: String }
  }
});

export default mongoose.models.User || mongoose.model('User', userSchema);
