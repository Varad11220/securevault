import express from "express";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import User from "../models/user.js";      
import Settings from '../models/settings.js';
import Counter from '../models/counter.js'; 
import LoginLog from '../models/loginLog.js';
import { generateRandomCode } from '../utils/codeGenerator.js';  

const router = express.Router();

async function getNextSequence(name) {
  const counter = await Counter.findOneAndUpdate(
    { id: name },
    { $inc: { seq: 1 } },
    { new: true, upsert: true }
  );
  return counter.seq;
}
//
router.get('/code-cycle-start', async (req, res) => {
  try {
    let settings = await Settings.findOne();
    if (!settings) {
      settings = new Settings({ codeCycleStart: new Date() });
      await settings.save();
    }
    res.json({ success: true, codeCycleStart: settings.codeCycleStart });
  } catch (err) {
    console.error('Error in /code-cycle-start:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});


// Register
router.post("/register", async (req, res) => {
  try {
    const { username, email, password } = req.body;

    const existingUser = await User.findOne({
      $or: [{ username }, { email }],
    });
    if (existingUser) {
      return res.status(400).json({ success: false, message: "Username or email already exists" });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const userId = await getNextSequence("userId");
    const authCode = generateRandomCode();  // Generate authCode on registration

    const newUser = new User({
      userId,
      username,
      email,
      password: hashedPassword,
      authCode
    });

    await newUser.save();

    res.status(201).json({ success: true, message: "User registered", userId, authCode });
  } catch (err) {
    console.error("Register error:", err);
    res.status(500).json({ success: false, message: err.message });
  }
});

// Login
router.post("/login", async (req, res) => {
  try {
    const { username, password } = req.body;

    const user = await User.findOne({ username }); // find by username only
    if (!user) {
      return res
        .status(400)
        .json({ success: false, message: "Invalid credentials" });
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res
        .status(400)
        .json({ success: false, message: "Invalid credentials" });
    }

    const token = jwt.sign(
      { userId: user.userId, username: user.username },
      process.env.JWT_SECRET,
      { expiresIn: "1h" }
    );

    res.json({
      success: true,
      token,
      userId: user.userId,
      username: user.username,
    });
  } catch (err) {
    console.error("Login error:", err);
    res.status(500).json({ success: false, message: err.message });
  }
});
function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  if (!authHeader) return res.status(401).json({ success: false, message: 'No token provided' });

  const token = authHeader.split(' ')[1];
  if (!token) return res.status(401).json({ success: false, message: 'Token missing' });

  jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
    if (err) return res.status(403).json({ success: false, message: 'Invalid token' });
    req.user = user; // userId and username embedded in token
    next();
  });
}

// GET /api/auth/code - returns current authCode of logged in user
router.get('/code', authenticateToken, async (req, res) => {
  try {
    const { userId } = req.user;
    const user = await User.findOne({ userId });
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    const biometricRequest = user.biometricLogin && user.biometricLogin.status === 'pending';

    res.json({ success: true, code: user.authCode || '', biometricRequest });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

router.get('/code/:code', async (req, res) => {
  try {
    const { code } = req.params;
    const user = await User.findOne({ authCode: code });

    if (!user) {
      return res.status(404).json({ success: false, message: 'invalid' });
    }

    res.json({ success: true, username: user.username });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// Browser initiates login with auth code
router.post('/browser-login', async (req, res) => {
  try {
      const { authCode } = req.body;
      const user = await User.findOne({ authCode });

      if (!user) {
          return res.status(404).json({ success: false, message: 'Invalid authentication code.' });
      }

      // Generate a unique session ID for this login attempt
      const sessionId = `login_${user.userId}_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
      
      user.biometricLogin = { 
          status: 'pending', 
          requestedAt: new Date(),
          sessionId: sessionId
      };
      await user.save();

      res.json({ 
          success: true, 
          message: 'Biometric verification initiated.', 
          username: user.username,
          sessionId: sessionId
      });
  } catch (error) {
      console.error("Browser login init error:", error);
      res.status(500).json({ success: false, message: error.message });
  }
});

// Mobile app resolves biometric auth
router.post('/resolve-biometric-auth', authenticateToken, async (req, res) => {
  try {
      const { approved } = req.body;
      const user = await User.findOne({ userId: req.user.userId });

      if (!user || user.biometricLogin.status !== 'pending') {
          return res.status(400).json({ success: false, message: 'No pending biometric request.' });
      }

      user.biometricLogin.status = approved ? 'approved' : 'denied';
      await user.save();
      
      res.json({ success: true, message: 'Biometric status updated.' });
  } catch (error) {
      console.error("Resolve biometric auth error:", error);
      res.status(500).json({ success: false, message: error.message });
  }
});

// Browser polls for login status using sessionId
router.get('/browser-login/status/:sessionId', async (req, res) => {
  try {
      const { sessionId } = req.params;
      
      // Find user by sessionId instead of auth code
      const user = await User.findOne({ 
          'biometricLogin.sessionId': sessionId,
          'biometricLogin.status': { $in: ['pending', 'approved', 'denied'] }
      });

      if (!user || !user.biometricLogin) {
          return res.status(404).json({ success: false, status: 'invalid_session' });
      }

      const status = user.biometricLogin.status;
      
      // Check if the biometric request is too old (more than 5 minutes)
      const requestAge = Date.now() - new Date(user.biometricLogin.requestedAt).getTime();
      const maxAge = 5 * 60 * 1000; // 5 minutes
      
      if (requestAge > maxAge && status === 'pending') {
          // Expire the biometric request
          user.biometricLogin.status = 'none';
          user.biometricLogin.sessionId = undefined;
          await user.save();
          return res.status(404).json({ success: false, status: 'expired' });
      }
      
      if (status === 'approved' || status === 'denied') {
          const isSuccess = status === 'approved';
          
          const log = new LoginLog({
              userId: user.userId,
              username: user.username,
              ip_address: req.ip,
              user_agent: req.headers['user-agent'] || 'Unknown',
              success: isSuccess,
          });
          await log.save();

          // Clear the biometric login data
          user.biometricLogin.status = 'none';
          user.biometricLogin.sessionId = undefined;
          await user.save();

          if (isSuccess) {
              const token = jwt.sign(
                  { userId: user.userId, username: user.username },
                  process.env.JWT_SECRET,
                  { expiresIn: '1h' }
              );
              return res.json({ success: true, status: 'approved', token });
          } else {
              return res.json({ success: false, status: 'denied' });
          }
      }

      res.json({ success: true, status });
  } catch (error) {
      console.error("Browser login status error:", error);
      res.status(500).json({ success: false, message: error.message });
  }
});

// Mobile gets login logs
router.get('/logs', authenticateToken, async (req, res) => {
  try {
      const logs = await LoginLog.find({ userId: req.user.userId }).sort({ timestamp: -1 }).limit(50);
      res.json({ success: true, logs });
  } catch (error) {
      console.error("Fetch logs error:", error);
      res.status(500).json({ success: false, message: error.message });
  }
});

export default router;
