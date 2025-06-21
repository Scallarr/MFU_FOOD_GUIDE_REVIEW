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
  console.log(req.body);
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

        // ✅ เช็คว่ามีรูปอยู่แล้วหรือยัง
        const checkPictureQuery = `
          SELECT * FROM user_Profile_Picture WHERE User_ID = ? LIMIT 1
        `;
        db.query(checkPictureQuery, [userId], (err, picResults) => {
          if (err) {
            console.error('Error checking profile picture:', err);
          }

          if (picResults.length === 0) {
            // ❇️ ถ้ายังไม่มีรูป ให้ insert
            const insertPicture = `
              INSERT INTO user_Profile_Picture (User_ID, picture_url, is_active)
              VALUES (?, ?, 1)
            `;
            db.query(insertPicture, [userId, picture_url], (err) => {
              if (err) console.error('Insert picture error:', err);
            });
          } else {
            // 🔕 มีรูปแล้ว ไม่ต้องทำอะไร
          }
        });

        // ✅ สร้าง token ส่งกลับ
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

    const query = `
      SELECT 
        u.fullname, 
        u.username, 
        u.email, 
        u.bio, 
        u.total_likes, 
        u.total_reviews, 
        u.coins, 
        u.role, 
        u.status,
        p.picture_url
      FROM User u
      LEFT JOIN user_Profile_Picture p 
        ON u.User_ID = p.User_ID AND p.is_active = 1
      WHERE u.User_ID = ?
    `;

    db.query(query, [userId], (err, results) => {
      if (err) {
        console.error('❌ DB Error:', err);
        return res.status(500).json({ error: 'Database error' });
      }

      if (results.length === 0) {
        return res.status(404).json({ error: 'User not found' });
      }

      res.json(results[0]);
    });
  });
  app.get('/restaurants', (req, res) => {
    const sql = `SELECT Restaurant_ID,restaurant_name, location, operating_hours, phone_number, photos, 
                        rating_overall_avg, rating_hygiene_avg, rating_flavor_avg, rating_service_avg, category 
                FROM Restaurant`;

    db.query(sql, (err, results) => {
      if (err) {
        console.error('Error fetching restaurants:', err);
        return res.status(500).json({ error: 'Database query error' });
      }
      res.json(results);
      console.log(results);
    });
  });






  app.get('/user-profile/:id', (req, res) => {
    const userId = parseInt(req.params.id, 10);

    if (!userId) {
      return res.status(400).json({ error: 'Missing or invalid userId' });
    }

    const sql = `
      SELECT picture_url 
      FROM user_Profile_Picture 
      WHERE User_ID = ? AND is_active = 1 
      LIMIT 1
    `;

    db.query(sql, [userId], (error, results) => {
      if (error) {
        console.error('Database error:', error);
        return res.status(500).json({ error: 'Database error' });
      }

      if (results.length > 0) {
        res.json({ picture_url: results[0].picture_url });
      } else {
        res.json({ picture_url: null });
      }
    });
  });

 app.get('/restaurant/:id', (req, res) => {
  const restaurantId = req.params.id;

  const restaurantQuery = `
    SELECT 
      Restaurant_ID,
      restaurant_name,
      location,
      operating_hours,
      phone_number,
      photos,
      category,
      rating_overall_avg,
      rating_hygiene_avg,
      rating_flavor_avg,
      rating_service_avg
    FROM Restaurant
    WHERE restaurant_id = ?
  `;

  const reviewQuery = `
    SELECT 
      r.Review_ID,
      r.rating_overall,
      r.rating_hygiene,
      r.rating_flavor,
      r.rating_service,
      r.comment,
      r.total_likes,
      r.created_at,
      u.username,
      p.picture_url
    FROM Review r
    JOIN User u ON r.User_ID = u.User_ID
    LEFT JOIN user_Profile_Picture p 
      ON r.User_ID = p.User_ID AND p.is_active = 1
    WHERE r.restaurant_id = ?
    ORDER BY r.created_at DESC
  `;

  const menuQuery = `
    SELECT 
      Menu_ID,
      menu_thai_name,
      menu_english_name,
      price,
      menu_img
    FROM Menu
    WHERE restaurant_id = ?
  `;

  db.query(restaurantQuery, [restaurantId], (err, restaurantResults) => {
    if (err) {
      console.error('❌ Restaurant Query Error:', err);
      return res.status(500).json({ error: 'Database error' });
    }

    if (restaurantResults.length === 0) {
      return res.status(404).json({ error: 'Restaurant not found' });
    }

    const restaurant = restaurantResults[0];

    db.query(reviewQuery, [restaurantId], (err, reviewResults) => {
      if (err) {
        console.error('❌ Review Query Error:', err);
        return res.status(500).json({ error: 'Database error' });
      }

      db.query(menuQuery, [restaurantId], (err, menuResults) => {
        if (err) {
          console.error('❌ Menu Query Error:', err);
          return res.status(500).json({ error: 'Database error' });
        }

        restaurant.reviews = reviewResults;
        restaurant.menus = menuResults;

        res.json(restaurant);
        console.log('✅ Sent restaurant with reviews and menus:', restaurant);
      });
    });
  });
});
app.post('/review/:reviewId/like', (req, res) => {
  const reviewId = parseInt(req.params.reviewId);
  const userId = req.body.user_id;

  if (!userId) {
    return res.status(400).json({ message: 'user_id is required' });
  }

  const checkLikeQuery = `SELECT * FROM Review_Likes WHERE Review_ID = ? AND User_ID = ?`;
  db.query(checkLikeQuery, [reviewId, userId], (err, rows) => {
    if (err) return res.status(500).json({ message: 'DB error' });

    if (rows.length > 0) {
      // Unlike
      db.query(`DELETE FROM Review_Likes WHERE Review_ID = ? AND User_ID = ?`,
        [reviewId, userId], (err) => {
          if (err) return res.status(500).json({ message: 'DB error on unlike' });

          db.query(`UPDATE Review SET total_likes = GREATEST(total_likes - 1, 0) WHERE Review_ID = ?`,
            [reviewId], (err) => {
              if (err) return res.status(500).json({ message: 'DB error on update' });
              return res.status(200).json({ message: 'Review unliked', liked: false });
            });
        });
    } else {
      // Like
      db.query(`INSERT INTO Review_Likes (Review_ID, User_ID) VALUES (?, ?)`,
        [reviewId, userId], (err) => {
          if (err) return res.status(500).json({ message: 'DB error on like' });

          db.query(`UPDATE Review SET total_likes = total_likes + 1 WHERE Review_ID = ?`,
            [reviewId], (err) => {
              if (err) return res.status(500).json({ message: 'DB error on update' });
              return res.status(200).json({ message: 'Review liked', liked: true });
            });
        });
    }
  });
});





  // ✅ Start Server
  const PORT = process.env.PORT || 8080;
  app.listen(PORT, () => console.log(`🚀 API running on port ${PORT}`));
