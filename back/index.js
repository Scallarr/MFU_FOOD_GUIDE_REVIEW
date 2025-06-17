// backend/index.js
const express = require('express');
const cors = require('cors');
const mysql = require('mysql2');
const jwt = require('jsonwebtoken');

const app = express();
app.use(cors());
app.use(express.json());

const SECRET_KEY = 'your_secret_key_here';  // เปลี่ยนเป็นคีย์ลับของคุณ

const db = mysql.createConnection({
  host: 'byjsmg8vfii8dqlflpwy-mysql.services.clever-cloud.com',
  user: 'u6lkh5gfkkvbxdij',
  password: 'lunYpL9EDowPHBA02vkE',
  database: 'byjsmg8vfii8dqlflpwy',
});

db.query(`CREATE TABLE IF NOT EXISTS User (
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
  status ENUM('Active', 'Suspended','Banned') DEFAULT 'Active'
);`, (err) => {
  if (err) {
    console.error("❌ Failed to create table:", err);
  } else {
    console.log("✅ User table ready");
  }
});

// Route login + upsert user, ส่งกลับ token + userId
app.post('/user/login', (req, res) => {
  const { fullname, username, email, google_id } = req.body;

  const q = `INSERT INTO User (fullname, username, email, google_id)
             VALUES (?, ?, ?, ?)
             ON DUPLICATE KEY UPDATE 
               fullname = VALUES(fullname),
               email = VALUES(email)`;

  db.query(q, [fullname, username, email, google_id], (err) => {
    if (err) {
      console.error(err);
      return res.status(500).send('Database error');
    }

    const selectQuery = 'SELECT User_ID FROM User WHERE google_id = ?';
    db.query(selectQuery, [google_id], (err, results) => {
      if (err) return res.status(500).send('DB error');
      if (results.length === 0) return res.status(404).send('User not found');

      const userId = results[0].User_ID;

      const token = jwt.sign(
        { userId, google_id, username, email },
        SECRET_KEY,
        { expiresIn: '7d' }
      );

      res.json({ message: 'Login successful', token, userId });
    });
  });
});

const PORT = process.env.PORT || 8080;
app.listen(PORT, () => console.log(`API running on port ${PORT}`));
