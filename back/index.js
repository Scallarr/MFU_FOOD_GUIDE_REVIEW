const express = require('express');
const cors = require('cors');
const mysql = require('mysql2');
const jwt = require('jsonwebtoken');

const app = express();
app.use(cors());
app.use(express.json());

const SECRET_KEY = 'your_secret_key_here'; // 🔐 เปลี่ยนให้ปลอดภัย

// ✅ เชื่อมต่อ MySQL
const db = mysql.createConnection({
  host: 'byjsmg8vfii8dqlflpwy-mysql.services.clever-cloud.com',
  user: 'u6lkh5gfkkvbxdij',
  password: 'lunYpL9EDowPHBA02vkE',
  database: 'byjsmg8vfii8dqlflpwy',
});

// ✅ สร้าง Table หากยังไม่มี
db.query(`
  CREATE TABLE IF NOT EXISTS User (
    User_ID INT AUTO_INCREMENT PRIMARY KEY,
    fullname VARCHAR(50) NOT NULL UNIQUE,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(50) NOT NULL,
    google_id VARCHAR(50) NOT NULL,
    bio TEXT,
    total_likes INT DEFAULT 0,
    total_reviews INT DEFAULT 0,
    coins INT DEFAULT 0,
    role ENUM('User', 'Admin') DEFAULT 'User',
    status ENUM('Active', 'Suspended', 'Banned') DEFAULT 'Active'
);`, (err) => {
  if (err) {
    console.error("❌ Failed to create table:", err);
  } else {
    console.log("✅ User table ready");
  }
});


// ✅ Login Route (POST)
app.post('/user/login', (req, res) => {
  const { fullname, username, email, google_id, picture_url } = req.body;

  const insertOrUpdateUser = `
    INSERT INTO User (fullname, username, email, google_id)
    VALUES (?, ?, ?, ?)
    ON DUPLICATE KEY UPDATE fullname = VALUES(fullname), email = VALUES(email)
  `;

  db.query(insertOrUpdateUser, [fullname, username, email, google_id], (err) => {
    if (err) return res.status(500).json({ error: 'Database error' });

    const selectUserId = 'SELECT User_ID FROM User WHERE google_id = ?';
    db.query(selectUserId, [google_id], (err, results) => {
      if (err) return res.status(500).json({ error: 'DB error' });
      if (results.length === 0) return res.status(404).json({ error: 'User not found' });

      const userId = results[0].User_ID;

      // Reset all old pictures to is_active = 0
      const resetOldPictures = `UPDATE user_Profile_Picture SET is_active = 0 WHERE User_ID = ?`;
      db.query(resetOldPictures, [userId], (err) => {
        if (err) console.error('Reset old pictures error:', err);
      });

      // Insert new picture as active
      const insertPicture = `
        INSERT INTO user_Profile_Picture (User_ID, picture_url, is_active)
        VALUES (?, ?, 1)
      `;
      db.query(insertPicture, [userId, picture_url], (err) => {
        if (err) console.error('Insert picture error:', err);
      });

      // Create token
      const token = jwt.sign(
        { userId, google_id, username, email },
        SECRET_KEY,
        { expiresIn: '7d' }
      );

      res.json({ message: 'Login successful', token, userId });
    });
  });
});



// ✅ Get User Info Route (GET)
app.get('/user/info/:id', (req, res) => {
  const userId = req.params.id;

  const q = `SELECT fullname, username, email, bio, total_likes, total_reviews, coins, role, status 
             FROM User WHERE User_ID = ?`;

  db.query(q, [userId], (err, results) => {
    if (err) return res.status(500).json({ error: 'DB error' });
    if (results.length === 0) return res.status(404).json({ error: 'User not found' });

    res.json(results[0]);
  });
});


// ✅ Start Server
const PORT = process.env.PORT || 8080;
app.listen(PORT, () => console.log(`🚀 API running on port ${PORT}`));
