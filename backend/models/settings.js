// models/Settings.js
import mongoose from 'mongoose';

const SettingsSchema = new mongoose.Schema({
  codeCycleStart: { type: Date, default: Date.now },
});

export default mongoose.model('Settings', SettingsSchema);
