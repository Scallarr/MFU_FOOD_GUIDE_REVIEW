const express = require('express');
const cors = require('cors');
const mysql = require('mysql2');

const app = express();
app.use(cors());
app.use(express.json());

// ✅ เชื่อมต่อฐานข้อมูล Clever Cloud (เปลี่ยนค่าด้านล่างให้ตรงกับของคุณ)
const db = mysql.createConnection({
  host: 'byjsmg8vfii8dqlflpwy-mysql.services.clever-cloud.com',  // Hostname จาก Clever Cloud
  user: 'u6lkh5gfkkvbxdij',  // Username จาก Clever Cloud
  password: 'lunYpL9EDowPHBA02vkE', // ❗️ใส่รหัสผ่านจริงจากหน้า Configuration
  database: 'byjsmg8vfii8dqlflpwy',  // Database name จาก Clever Cloud
});

// ✅ สร้างตาราง User หากยังไม่มี
db.query(`CREATE TABLE IF NOT EXISTS User (
  User_ID INT AUTO_INCREMENT PRIMARY KEY,
  fullname VARCHAR(50) NOT NULL UNIQUE,
  username VARCHAR(50) NOT NULL UNIQUE,
  email VARCHAR(50) NOT NULL,
  google_id BIGINT NOT NULL,
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

// ✅ API สำหรับเพิ่ม/อัปเดตผู้ใช้
app.post('/user', (req, res) => {
  const { fullname, username, email, google_id } = req.body;

  const q = `INSERT INTO User (fullname, username, email, google_id)
             VALUES (?, ?, ?, ?)
             ON DUPLICATE KEY UPDATE 
               email = VALUES(email),
               google_id = VALUES(google_id)`;

  db.query(q, [fullname, username, email, google_id], (err, result) => {
    if (err) {
      console.error('❌ Error inserting user:', err);
      return res.status(500).send('Error saving user');
    }
    res.send('✅ User saved');
  });
});

// ✅ Start server
const PORT = process.env.PORT || 8080;
app.listen(PORT, () => console.log(`API running on port ${PORT}`));

