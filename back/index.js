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
app.get('/user-profile-pictures/:userId', (req, res) => {
  const userId = parseInt(req.params.userId);
  const sql = `SELECT Picture_ID, picture_url, is_active 
               FROM user_Profile_Picture 
               WHERE User_ID = ?`;
  db.query(sql, [userId], (err, results) => {
    if (err) return res.status(500).json({ error: 'DB error' });
    res.json(results);
  });
});


app.post('/user-profile-pictures/set-active', (req, res) => {
  const { userId, pictureId } = req.body;

  const deactivate = `UPDATE user_Profile_Picture 
                      SET is_active = 0 
                      WHERE User_ID = ?`;

  const activate = `UPDATE user_Profile_Picture 
                    SET is_active = 1 
                    WHERE Picture_ID = ? AND User_ID = ?`;

  db.query(deactivate, [userId], (err1) => {
    if (err1) return res.status(500).json({ error: 'Deactivate error' });

    db.query(activate, [pictureId, userId], (err2) => {
      if (err2) return res.status(500).json({ error: 'Activate error' });
      res.json({ message: 'Profile picture updated' });
    });
  });
});






  app.get('/user-profile/:id', (req, res) => {
  const userId = parseInt(req.params.id, 10);

  if (!userId) {
    return res.status(400).json({ error: 'Missing or invalid userId' });
  }

  const sql = `
    SELECT 
      u.User_ID,
      u.fullname,
      u.username,
      u.email,
      u.google_id,
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
    LIMIT 1
  `;

  db.query(sql, [userId], (error, results) => {
    if (error) {
      console.error('Database error:', error);
      return res.status(500).json({ error: 'Database error' });
    }

    if (results.length > 0) {
      res.json(results[0]);
      console.log(results);
    } else {
      res.status(404).json({ error: 'User not found' });
    }
  });
  
});

app.get('/restaurant/:id', (req, res) => {
  const restaurantId = parseInt(req.params.id);
  const userId = parseInt(req.query.user_id); // รับ user_id จาก Flutter

  const restaurantQuery = `
    SELECT Restaurant_ID, restaurant_name, location, operating_hours,
           phone_number, photos, category, rating_overall_avg,
           rating_hygiene_avg, rating_flavor_avg, rating_service_avg
    FROM Restaurant
    WHERE Restaurant_ID = ?
  `;

  const reviewQuery = `
    SELECT r.Review_ID, r.rating_overall, r.rating_hygiene, r.rating_flavor,
           r.rating_service, r.comment, r.total_likes, r.created_at,
           u.username, p.picture_url,
           EXISTS (
             SELECT 1 FROM Review_Likes rl
             WHERE rl.Review_ID = r.Review_ID AND rl.User_ID = ?
           ) AS isLiked
    FROM Review r
    JOIN User u ON r.User_ID = u.User_ID
    LEFT JOIN user_Profile_Picture p 
      ON r.User_ID = p.User_ID AND p.is_active = 1
    WHERE r.restaurant_id = ?
    ORDER BY r.created_at DESC
  `;

  const menuQuery = `
    SELECT Menu_ID, menu_thai_name, menu_english_name, price, menu_img
    FROM Menu
    WHERE restaurant_id = ?
  `;

  db.query(restaurantQuery, [restaurantId], (err, restRes) => {
    if (err || restRes.length === 0) return res.status(500).json({ error: 'Error fetching restaurant' });

    const restaurant = restRes[0];
    db.query(reviewQuery, [userId, restaurantId], (err2, revRes) => {
      if (err2) return res.status(500).json({ error: 'Error fetching reviews' });

      db.query(menuQuery, [restaurantId], (err3, menuRes) => {
        if (err3) return res.status(500).json({ error: 'Error fetching menu' });

        restaurant.reviews = revRes.map(r => ({
          ...r,
          isLiked: !!r.isLiked
        }));
        restaurant.menus = menuRes;

        res.json(restaurant);
      });
    });
  });
});

// Like/Unlike route (toggle)
app.post('/review/:reviewId/like', (req, res) => {
  const reviewId = parseInt(req.params.reviewId);
  const userId = parseInt(req.body.user_id);
  if (!userId) return res.status(400).json({ message: 'user_id is required' });

  const check = 'SELECT * FROM Review_Likes WHERE Review_ID = ? AND User_ID = ?';
  db.query(check, [reviewId, userId], (e1, rows) => {
    if (e1) return res.status(500).json({ message: 'DB error' });

    // ดึง User_ID เจ้าของรีวิวก่อน
    const getOwner = 'SELECT User_ID FROM Review WHERE Review_ID = ?';
    db.query(getOwner, [reviewId], (e3, ownerRows) => {
      if (e3 || ownerRows.length === 0) return res.status(500).json({ message: 'DB error (owner)' });
      const ownerId = ownerRows[0].User_ID;

      if (rows.length > 0) {
        // ถ้ามีอยู่แล้ว = กำลังจะ unlike
        db.query('DELETE FROM Review_Likes WHERE Review_ID = ? AND User_ID = ?', [reviewId, userId], (e2) => {
          if (e2) return res.status(500).json({ message: 'DB error on unlike' });

          // ลด like ใน Review
          db.query('UPDATE Review SET total_likes = GREATEST(total_likes - 1, 0) WHERE Review_ID = ?', [reviewId]);

          // ลด like ใน User (เจ้าของรีวิว)
          db.query('UPDATE User SET total_likes = GREATEST(total_likes - 1, 0) WHERE User_ID = ?', [ownerId]);

          res.status(200).json({ message: 'Review unliked', liked: false });
        });
      } else {
        // ยังไม่เคยกด like
        db.query('INSERT INTO Review_Likes (Review_ID, User_ID) VALUES (?,?)', [reviewId, userId], (e2) => {
          if (e2) return res.status(500).json({ message: 'DB error on like' });

          // เพิ่ม like ใน Review
          db.query('UPDATE Review SET total_likes = total_likes + 1 WHERE Review_ID = ?', [reviewId]);

          // เพิ่ม like ใน User (เจ้าของรีวิว)
          db.query('UPDATE User SET total_likes = total_likes + 1 WHERE User_ID = ?', [ownerId]);

          res.status(200).json({ message: 'Review liked', liked: true });
        });
      }
    });
  });
});

// Express.js route example
app.put('/user-profile/update/:id', (req, res) => {
  const { id } = req.params;
  const { username, bio } = req.body;
   console.log("PUT /user-profile/update/:id", req.body); // ✅ ตรวจข้อมูลที่รับ


  const sql = `
    UPDATE User 
    SET username = ?, bio = ?
    WHERE User_ID = ?
  `;

  db.query(sql, [username, bio, id], (err, result) => {
    if (err) return res.status(500).json({ error: err });
    res.status(200).json({ message: 'Updated successfully' });
  });
});


// app.get('/restaurant/:id', (req, res) => {
//   const restaurantId = req.params.id;
//   const userId = parseInt(req.query.user_id); // 👈 รับ user_id จาก query param

//   const restaurantQuery = `
//     SELECT 
//       Restaurant_ID,
//       restaurant_name,
//       location,
//       operating_hours,
//       phone_number,
//       photos,
//       category,
//       rating_overall_avg,
//       rating_hygiene_avg,
//       rating_flavor_avg,
//       rating_service_avg
//     FROM Restaurant
//     WHERE restaurant_id = ?
//   `;

//   // ✅ เพิ่มเช็ค isLiked เข้าใน reviewQuery
//   const reviewQuery = `
//     SELECT 
//   r.Review_ID,
//   r.rating_overall,
//   r.comment,
//   r.total_likes,
//   r.created_at,
//   u.username,
//   p.picture_url,
//   EXISTS (
//     SELECT 1 FROM Review_Likes rl 
//     WHERE rl.Review_ID = r.Review_ID AND rl.User_ID = ?
//   ) AS is_liked
// FROM Review r
// JOIN User u ON r.User_ID = u.User_ID
// LEFT JOIN user_Profile_Picture p 
//   ON r.User_ID = p.User_ID AND p.is_active = 1
// WHERE r.restaurant_id = ?
// ORDER BY r.created_at DESC
//   `;

//   const menuQuery = `
//     SELECT 
//       Menu_ID,
//       menu_thai_name,
//       menu_english_name,
//       price,
//       menu_img
//     FROM Menu
//     WHERE restaurant_id = ?
//   `;

//   db.query(restaurantQuery, [restaurantId], (err, restaurantResults) => {
//     if (err) {
//       console.error('❌ Restaurant Query Error:', err);
//       return res.status(500).json({ error: 'Database error' });
//     }

//     if (restaurantResults.length === 0) {
//       return res.status(404).json({ error: 'Restaurant not found' });
//     }

//     const restaurant = restaurantResults[0];

//     // ✅ ใส่ userId และ restaurantId เป็นพารามิเตอร์
//     db.query(reviewQuery, [userId, restaurantId], (err, reviewResults) => {
//       if (err) {
//         console.error('❌ Review Query Error:', err);
//         return res.status(500).json({ error: 'Database error' });
//       }

//       db.query(menuQuery, [restaurantId], (err, menuResults) => {
//         if (err) {
//           console.error('❌ Menu Query Error:', err);
//           return res.status(500).json({ error: 'Database error' });
//         }

//         // ✅ แปลง isLiked จาก 0/1 หรือ 0/null → เป็น Boolean
//         const reviewsWithLikeStatus = reviewResults.map(r => ({
//           ...r,
//           isLiked: !!r.isLiked
//         }));

//         restaurant.reviews = reviewsWithLikeStatus;
//         restaurant.menus = menuResults;

//         res.json(restaurant);
//         console.log('✅ Sent restaurant with reviews and menus:', restaurant);
//       });
//     });
//   });
// });

// app.post('/review/:reviewId/like', (req, res) => {
//   const reviewId = parseInt(req.params.reviewId);
//   const userId = req.body.user_id;

//   if (!userId) {
//     return res.status(400).json({ message: 'user_id is required' });
//   }

//   const checkLikeQuery = `SELECT * FROM Review_Likes WHERE Review_ID = ? AND User_ID = ?`;
//   db.query(checkLikeQuery, [reviewId, userId], (err, rows) => {
//     if (err) return res.status(500).json({ message: 'DB error' });

//     if (rows.length > 0) {
//       // Unlike
//       db.query(`DELETE FROM Review_Likes WHERE Review_ID = ? AND User_ID = ?`,
//         [reviewId, userId], (err) => {
//           if (err) return res.status(500).json({ message: 'DB error on unlike' });

//           db.query(`UPDATE Review SET total_likes = GREATEST(total_likes - 1, 0) WHERE Review_ID = ?`,
//             [reviewId], (err) => {
//               if (err) return res.status(500).json({ message: 'DB error on update' });
//               return res.status(200).json({ message: 'Review unliked', liked: false });
//             });
//         });
//     } else {
//       // Like
//       db.query(`INSERT INTO Review_Likes (Review_ID, User_ID) VALUES (?, ?)`,
//         [reviewId, userId], (err) => {
//           if (err) return res.status(500).json({ message: 'DB error on like' });

//           db.query(`UPDATE Review SET total_likes = total_likes + 1 WHERE Review_ID = ?`,
//             [reviewId], (err) => {
//               if (err) return res.status(500).json({ message: 'DB error on update' });
//               return res.status(200).json({ message: 'Review liked', liked: true });
//             });
//         });
//     }
//   });
// });





  // ✅ Start Server
  const PORT = process.env.PORT || 8080;
  app.listen(PORT, () => console.log(`🚀 API running on port ${PORT}`));
