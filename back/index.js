const express = require('express');
const cors = require('cors');
const mysql = require('mysql2');

const app = express();
app.use(cors());
app.use(express.json());

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

app.post('/user', (req, res) => {
  console.log("Received data:", req.body); // ดูข้อมูลจาก Flutter จริงๆ

  const { fullname, username, email, google_id } = req.body;

  const q = `INSERT INTO User (fullname, username, email, google_id)
             VALUES (?, ?, ?, ?)
             ON DUPLICATE KEY UPDATE 
               email = VALUES(email),
               google_id = VALUES(google_id)`;

  db.query(q, [fullname, username, email, google_id], (err) => {
    if (err) {
      console.error('❌ Error inserting user:', err);
      return res.status(500).send('Error saving user');
    }
    res.send('✅ User saved');
  });
});

const PORT = process.env.PORT || 8080;
app.listen(PORT, () => console.log(`API running on port ${PORT}`));
