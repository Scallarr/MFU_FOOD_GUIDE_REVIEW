  const express = require('express');
  const cors = require('cors');
  const mysql = require('mysql2');
  const jwt = require('jsonwebtoken');
  const axios = require('axios');

  const app = express();
  app.use(cors());
  app.use(express.json());

  const SECRET_KEY = 'your_secret_key_here'; // 🔐 เปลี่ยนให้ปลอดภัย

  // ✅ เชื่อมต่อ MySQL
  const db = mysql.createPool({
    connectionLimit:10,
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
  console.log("restaurantId from params:", restaurantId);
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
         r.message_status,  -- ✅ ดึงสถานะด้วย
         u.username,u.email, p.picture_url,
         EXISTS (
           SELECT 1 FROM Review_Likes rl
           WHERE rl.Review_ID = r.Review_ID AND rl.User_ID = ?
         ) AS isLiked
  FROM Review r
  JOIN User u ON r.User_ID = u.User_ID
  LEFT JOIN user_Profile_Picture p 
    ON r.User_ID = p.User_ID AND p.is_active = 1
  WHERE r.restaurant_id = ? AND r.ai_evaluation = 'Safe'
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
        console.log(restaurant);
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


app.get('/leaderboard', async (req, res) => {
  try {
    const monthYear = req.query.month_year || '2025-08';

    const [topUsers] = await db.promise().query(`
      SELECT 
        u.User_ID,
        u.username,
        u.coins,
        u.email,
        COUNT(r.Review_ID) AS total_reviews,
        SUM(r.total_likes) AS total_likes,
        ROW_NUMBER() OVER (ORDER BY SUM(r.total_likes) DESC) AS \`rank\`,
        upp.picture_url AS profile_image
      FROM Review r
      JOIN User u ON r.User_ID = u.User_ID
      LEFT JOIN user_Profile_Picture upp ON upp.User_ID = u.User_ID AND upp.is_active = 1
      WHERE r.message_status = 'Posted' AND DATE_FORMAT(r.created_at, '%Y-%m') = ?
      GROUP BY u.User_ID
      ORDER BY total_likes DESC
      LIMIT 3
    `, [monthYear]);

    const [topRestaurants] = await db.promise().query(`
      SELECT 
        r.Restaurant_ID,
        res.restaurant_name,
        AVG(r.rating_overall) AS overall_rating,
        COUNT(r.Review_ID) AS total_reviews,
        res.photos AS restaurant_image,
        ROW_NUMBER() OVER (ORDER BY AVG(r.rating_overall) DESC) AS \`rank\`
      FROM Review r
      JOIN Restaurant res ON r.Restaurant_ID = res.Restaurant_ID
      WHERE r.message_status = 'Posted' AND DATE_FORMAT(r.created_at, '%Y-%m') = ?
      GROUP BY r.Restaurant_ID
      ORDER BY overall_rating DESC
      LIMIT 3
    `, [monthYear]);

    res.json({
      month_year: monthYear,
      topUsers,
      topRestaurants,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal server error' });
  }
});


app.post('/leaderboard/update-auto', async (req, res) => {
  try {
    const { month_year } = req.body;
    console.log(month_year);
    if (!month_year) return res.status(400).json({ error: 'Missing month_year' });

    const conn = await db.promise().getConnection();
    try {
      await conn.beginTransaction();

      // 1. ดึง top 3 user ที่ได้ไลค์เยอะสุดในเดือนนั้น
    const [topUsers] = await conn.query(`
  SELECT
    u.User_ID,
    u.fullname,
    u.username,
    u.email,
    u.google_id,
    u.bio,
    COALESCE(COUNT(DISTINCT rl.Like_ID), 0) AS total_likes,
    COALESCE(COUNT(DISTINCT r.Review_ID), 0) AS total_reviews
  FROM User u
LEFT JOIN Review r ON u.User_ID = r.User_ID AND DATE_FORMAT(r.created_at, '%Y-%m') = ? AND r.message_status = 'Post'
  LEFT JOIN Review_Likes rl ON rl.Review_ID IN (
   SELECT Review_ID FROM Review WHERE User_ID = u.User_ID AND status = 'Post'
 ) AND DATE_FORMAT(rl.Liked_At, '%Y-%m') = ?
  WHERE u.status = 'Active'
  GROUP BY u.User_ID, u.fullname, u.username, u.email, u.google_id, u.bio
  ORDER BY total_likes DESC
  LIMIT 3;
`, [month_year, month_year]);


      // ลบข้อมูล leaderboard user เดือนนั้นก่อน
      await conn.query('DELETE FROM Leaderboard_user_total_like WHERE month_year = ?', [month_year]);

      // Insert leaderboard user ใหม่
      let rank = 1;
      for (const user of topUsers) {
       await conn.query(`
  INSERT INTO Leaderboard_user_total_like
    (\`rank\`, User_ID, month_year, total_likes, total_reviews)
  VALUES (?, ?, ?, ?, ?)
`, [rank, user.User_ID, month_year, user.total_likes, user.total_reviews]);
        rank++;
      }

      // 2. ดึง top 3 restaurant ที่คะแนนเฉลี่ยรวมดีที่สุดในเดือนนั้น (ใช้ rating_overall_avg)
      // สมมติ rating_overall_avg มาจากตาราง Restaurant ตรงๆ (ไม่ต่อกับเดือน เพราะ rating คือค่าเฉลี่ยสะสม)
      // หากต้องการเฉพาะร้านที่มีรีวิวในเดือนนั้น ต้อง join กับรีวิวในเดือนนั้นด้วย (ปรับ SQL ตามต้องการ)
      const [topRestaurants] = await conn.query(`
        SELECT
          r.Restaurant_ID,
          r.restaurant_name,
          r.photos,
          r.rating_overall_avg,
          COALESCE(COUNT(rv.Review_ID), 0) AS total_reviews
        FROM Restaurant r
        LEFT JOIN Review rv ON r.Restaurant_ID = rv.Restaurant_ID
          AND DATE_FORMAT(rv.created_at, '%Y-%m') = ?
        GROUP BY r.Restaurant_ID
        ORDER BY r.rating_overall_avg DESC
        LIMIT 3
      `, [month_year]);

      // ลบข้อมูล leaderboard restaurant เดือนนั้นก่อน
      await conn.query('DELETE FROM Leaderboard_restaurant WHERE month_year = ?', [month_year]);

      // Insert leaderboard restaurant ใหม่
      rank = 1;
      for (const restaurant of topRestaurants) {
       await conn.query(`
  INSERT INTO Leaderboard_restaurant
    (\`rank\`, Restaurant_ID, month_year, overall_rating, total_reviews)
  VALUES (?, ?, ?, ?, ?)
`, [rank, restaurant.Restaurant_ID, month_year, restaurant.rating_overall_avg, restaurant.total_reviews]);

        rank++;
      }

      await conn.commit();
      res.json({
        message: 'Leaderboard updated successfully',
        topUsers,
        topRestaurants
      });

    } catch (err) {
      await conn.rollback();
      throw err;
    } finally {
      conn.release();
    }

  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal server error' });
  }
});
app.get('/profile-exchange/:userId', (req, res) => {
  const userId = req.params.userId;
  console.log("User ID:", userId); // ✅ ดูว่าได้ค่าไหม

  const sql = `
    SELECT 
  u.coins AS user_coins,
  p.Profile_Shop_ID,
  p.Profile_Name,
  p.Description,
  p.Image_URL,
  p.Required_Coins,
  p.Created_At,
  CASE WHEN pu.User_ID IS NOT NULL THEN 1 ELSE 0 END AS is_purchased
FROM User u
CROSS JOIN exchange_coin_Shop p
LEFT JOIN Profile_Purchase_History pu 
  ON p.Profile_Shop_ID = pu.Profile_Shop_ID AND pu.User_ID = u.User_ID
WHERE u.User_ID = ?
ORDER BY p.Created_At DESC;

  `;

  db.query(sql, [userId], (err, results) => {
    if (err) {
      console.error("DB ERROR:", err);
      return res.status(500).json({ error: 'Database error' });
    }

    console.log("Query Result:", results); // ✅ ดูว่าข้อมูลมาไหม
    res.json(results);
  });
});

app.post('/purchase_profile', (req, res) => {
  const { user_id, profile_id, coins_spent, image_url } = req.body;

  db.getConnection((err, connection) => {
    if (err) {
      console.error('Error getting connection:', err);
      return res.status(500).json({ error: 'Database connection error' });
    }

    connection.beginTransaction((err) => {
      if (err) {
        connection.release();
        return res.status(500).json({ error: 'Transaction error' });
      }

      // 1. ลบ coins จาก user
      connection.query(
        'UPDATE User SET coins = coins - ? WHERE User_ID = ? AND coins >= ?',
        [coins_spent, user_id, coins_spent],
        (err, result) => {
          if (err || result.affectedRows === 0) {
            return connection.rollback(() => {
              connection.release();
              return res.status(400).json({ error: 'Not enough coins or update failed' });
            });
          }

          // 2. เพิ่มข้อมูล profile picture ที่ซื้อ
        connection.query(
            'INSERT INTO user_Profile_Picture (User_ID, picture_url, is_active) VALUES (?, ?, 0)',
            [user_id, image_url],
            (err) => {
              if (err) {
                return connection.rollback(() => {
                  connection.release();
                  return res.status(500).json({ error: 'Insert profile failed' });
                });
              }

              // ✅ 3. เพิ่มประวัติการซื้อ
          connection.query(
              'INSERT INTO Profile_Purchase_History (User_ID, Profile_Shop_ID, Coins_Spent) VALUES (?, ?, ?)',
                [user_id, profile_id, coins_spent],
                (err) => {
                  if (err) {
                    return connection.rollback(() => {
                      connection.release();
                      return res.status(500).json({ error: 'Insert purchase history failed' });
                    });
                  }

                  // ✅ Commit ถ้าทุกขั้นตอนผ่าน
                  connection.commit((err) => {
                    if (err) {
                      return connection.rollback(() => {
                        connection.release();
                        return res.status(500).json({ error: 'Commit failed' });
                      });
                    }

                    connection.release();
                    return res.json({ message: 'Purchase successful' });
                  });
                }
              );
            }
          );
        }
      );
    });
  });
});

const PERSPECTIVE_API_KEY = 'AIzaSyDKHBzVBCLpeBbPlz18w2bM5eWkw-Kgne4'; // แทนที่ด้วย API Key ของคุณ

// เพิ่ม list คำหยาบภาษาไทย
const thaiBadWords = [
  'เหี้ย',
  'สัส',
  'ควย',
  'หี',
  'ควาย',
  'ตูด',
  'กรู',
  'แม่ง',
  'มึง',
  'บ้า',
  'โง่',
  'ซวย',
  'แดก',
  'ตาย',
  'ตีน',
  'ชิบหาย',
  'มึง',
  'กู',
  'ขยะ'
,
];

function checkThaiBadWords(comment) {
  if (!comment) return false;
  const text = comment.toLowerCase();
  return thaiBadWords.some(badword => text.includes(badword));
}

async function checkCommentAI(comment) {
  if (!comment) return 'Safe';

  // ตรวจคำหยาบภาษาไทยก่อน
  if (checkThaiBadWords(comment)) {
    console.log('พบคำหยาบภาษาไทย');
    return 'Inappropriate';
  }

  try {
    const url = `https://commentanalyzer.googleapis.com/v1alpha1/comments:analyze?key=${PERSPECTIVE_API_KEY}`;

    const requestBody = {
      comment: { text: comment },
      languages: ['en'], // ปรับถ้าคอมเมนต์เป็นภาษาอื่น
      requestedAttributes: {
        TOXICITY: {},
        PROFANITY: {},
        // หรือเพิ่ม attribute อื่นๆ เช่น SEXUALLY_EXPLICIT, INSULT, THREAT ตามที่ต้องการ
      },
    };

    const response = await axios.post(url, requestBody);

    const scores = response.data.attributeScores;

    // ดึงคะแนน toxicity และ profanity
    const toxicityScore = scores.TOXICITY.summaryScore.value;
    const profanityScore = scores.PROFANITY ? scores.PROFANITY.summaryScore.value : 0;

    // ตั้งเกณฑ์คะแนนที่พิจารณาว่า "ไม่เหมาะสม"
    const threshold = 0.4;

    console.log('Toxicity:', toxicityScore, 'Profanity:', profanityScore);

    if (toxicityScore >= threshold || profanityScore >= threshold) {
      return 'Inappropriate';
    }

    return 'Safe';

  } catch (error) {
    console.error('Error calling Perspective API:', error);
    // ถ้า API error, เราอาจปล่อยให้ผ่าน หรือจะตั้งเป็น Pending ก็ได้
    return 'Safe';
  }
}

app.post('/submit_reviews', async (req, res) => {
  const {
    User_ID,
    Restaurant_ID,
    rating_hygiene,
    rating_flavor,
    rating_service,
    comment,
  } = req.body;

  if (
    !User_ID ||
    !Restaurant_ID ||
    rating_hygiene == null ||
    rating_flavor == null ||
    rating_service == null
  ) {
    return res.status(400).json({ error: 'Missing required fields' });
  }

  try {
    const rating_overall =
      (Number(rating_hygiene) + Number(rating_flavor) + Number(rating_service)) / 3;

    const ai_evaluation = await checkCommentAI(comment || '');
    const message_status = ai_evaluation === 'Safe' ? 'Posted' : 'Pending';

    // Insert review
    const [insertResult] = await db.promise().execute(
      `INSERT INTO Review 
      (User_ID, Restaurant_ID, rating_overall, rating_hygiene, rating_flavor, rating_service, comment, total_likes, ai_evaluation, message_status)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        User_ID,
        Restaurant_ID,
        rating_overall.toFixed(1),
        rating_hygiene,
        rating_flavor,
        rating_service,
        comment || '',
        0,
        ai_evaluation,
        message_status,
      ]
    );

    const reviewId = insertResult.insertId;

    // อัพเดต total_reviews ของ User (นับจำนวนรีวิวทั้งหมดของ user นี้)
   await db.promise().execute(
  `UPDATE User SET total_reviews = (
     SELECT COUNT(*) FROM Review WHERE User_ID = ? AND message_status = 'Posted'
   )
   WHERE User_ID = ?`,
  [User_ID, User_ID]
);


    // คำนวณค่าเฉลี่ยใหม่ของร้านอาหาร
    const [avgRows] = await db.promise().execute(
      `SELECT 
        AVG(rating_hygiene) AS hygiene_avg,
        AVG(rating_flavor) AS flavor_avg,
        AVG(rating_service) AS service_avg,
        AVG(rating_overall) AS overall_avg
      FROM Review
      WHERE Restaurant_ID = ?  AND message_status = 'Posted'`,
      [Restaurant_ID]
    );

    const avg = avgRows[0] || {};

    await db.promise().execute(
      `UPDATE Restaurant SET 
        rating_overall_avg = ?,
        rating_hygiene_avg = ?,
        rating_flavor_avg = ?,
        rating_service_avg = ?
      WHERE Restaurant_ID = ?`,
      [
        Number(avg.overall_avg || 0).toFixed(2),
        Number(avg.hygiene_avg || 0).toFixed(2),
        Number(avg.flavor_avg || 0).toFixed(2),
        Number(avg.service_avg || 0).toFixed(2),
        Restaurant_ID,
      ]
    );

    // ถ้า AI บอกว่าไม่ปลอดภัย
    if (ai_evaluation !== 'Safe') {
      await db.promise().execute(
        `INSERT INTO Admin_check_inappropriate_review 
        (Review_ID, Admin_ID, admin_action_taken)
        VALUES (?, NULL, 'Pending')`,
        [reviewId]
      );
    }

    return res.json({
      message: 'Review submitted successfully',
      review_id: reviewId,
      ai_evaluation,
      message_status,
    });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: 'Server error' });
  }
});

app.get('/all_threads/:userId', async (req, res) => {
  const userId = req.params.userId;

  try {
    const [rows] = await db.promise().execute(`
    SELECT 
    T.Thread_ID, 
    T.message, 
    T.created_at, 
    T.User_ID,
    U.fullname, 
    U.username,
    U.email,
    P.picture_url,
    T.Total_likes AS total_likes,
    (
      SELECT COUNT(*) 
      FROM Thread_reply TR
      JOIN Thread TT ON TT.Thread_ID = TR.Thread_ID
      WHERE TR.Thread_ID = T.Thread_ID
        AND TR.admin_decision = 'Posted'
    ) AS total_comments,
    EXISTS (
      SELECT 1 
      FROM Thread_Likes 
      WHERE Thread_ID = T.Thread_ID 
        AND User_ID = ?
    ) AS is_liked
FROM Thread T
JOIN User U 
  ON T.User_ID = U.User_ID
LEFT JOIN user_Profile_Picture P 
  ON P.User_ID = U.User_ID 
  AND P.is_active = 1
WHERE T.admin_decision = 'Posted'
ORDER BY T.created_at DESC

    `, [userId]);

    res.json(rows);
    console.log(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

app.post('/like_thread', async (req, res) => {
  const { User_ID, Thread_ID, liked } = req.body;

  if (!User_ID || !Thread_ID || liked === undefined) {
    return res.status(400).json({ error: 'Missing required fields' });
  }

  try {
    if (liked) {
      // เพิ่มไลค์
      await db.promise().execute(
        `INSERT IGNORE INTO Thread_Likes (User_ID, Thread_ID) VALUES (?, ?)`,
        [User_ID, Thread_ID]
      );
    } else {
      // ลบไลค์
      await db.promise().execute(
        `DELETE FROM Thread_Likes WHERE User_ID = ? AND Thread_ID = ?`,
        [User_ID, Thread_ID]
      );
    }

    // อัปเดต Total_likes ของ Thread นั้น ๆ
    await db.promise().execute(
      `UPDATE Thread
       SET Total_likes = (
         SELECT COUNT(*) FROM Thread_Likes WHERE Thread_ID = ?
       )
       WHERE Thread_ID = ?`,
      [Thread_ID, Thread_ID]
    );

    res.json({ message: 'Like status and total likes updated' });
  } catch (error) {
    console.error('Error in /like_thread:', error);
    res.status(500).json({ error: 'Server error' });
  }
});



app.post('/unlike_thread', async (req, res) => {
  const { User_ID, Thread_ID } = req.body;

  await db.promise().execute(
    `DELETE FROM Thread_Likes WHERE User_ID = ? AND Thread_ID = ?`,
    [User_ID, Thread_ID]
  );

  await db.promise().execute(
    `UPDATE Thread SET Total_likes = Total_likes - 1 WHERE Thread_ID = ? AND Total_likes > 0`,
    [Thread_ID]
  );

  res.sendStatus(200);
});

app.post('/create_thread', async (req, res) => {
  try {
    const { User_ID, message } = req.body;
    if (!User_ID || !message) {
      return res.status(400).json({ error: 'Missing User_ID or message' });
    }

    const aiResult = await checkCommentAI(message);

    let ai_evaluation = 'Undetermined';
    let admin_decision = 'Pending';

    if (aiResult === 'Safe') {
      ai_evaluation = 'Safe';
      admin_decision = 'Posted';
    } else if (aiResult === 'Inappropriate') {
      ai_evaluation = 'Inappropriate';
      admin_decision = 'Pending';
    }

    const [result] = await db.promise().execute(
      `INSERT INTO Thread 
       (User_ID, message, ai_evaluation, admin_decision, created_at, Total_likes)
       VALUES (?, ?, ?, ?, NOW(), 0)`,
      [User_ID, message, ai_evaluation, admin_decision]
    );

    const newThreadId = result.insertId;

    if (aiResult === 'Inappropriate') {
     await db.promise().execute(
        `INSERT INTO Admin_check_inappropriate_thread
         (Thread_ID, Admin_ID, admin_action_taken)
         VALUES (?, NULL, 'Pending')`,
        [newThreadId]
      );
    }

     res.json({
      success: true,
      Thread_ID: newThreadId,
      ai_evaluation,
    });
console.log(ai_evaluation);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});


app.get('/api/thread_replies/:threadId', async (req, res) => {
  const threadId = req.params.threadId;

  try {
    const [rows] = await db.promise().execute(
      `SELECT
        tr.Thread_reply_ID,
        tr.Thread_ID,
        tr.User_ID,
        tr.message,
        tr.created_at,
        tr.total_likes,
        tr.ai_evaluation,
        u.fullname,
        u.username,
        upp.picture_url
      FROM Thread_reply tr
      JOIN User u ON tr.User_ID = u.User_ID
      LEFT JOIN user_Profile_Picture upp
        ON u.User_ID = upp.User_ID AND upp.is_active = 1
      WHERE tr.Thread_ID = ?
        AND tr.admin_decision = 'Posted'
      ORDER BY tr.created_at ASC`,
      [threadId]
    );

    res.json(rows);
    console.log(rows);
  } catch (error) {
    console.error('Error fetching thread replies:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});


app.post('/api/send_reply', async (req, res) => {
  const { User_ID, Thread_ID, message } = req.body;

  if (!User_ID || !Thread_ID || !message) {
    return res.status(400).json({ error: 'Missing required fields' });
  }

  try {
    const aiEvaluation = await checkCommentAI(message);
    const hasProfanity = aiEvaluation === 'Inappropriate';
    const adminDecision = hasProfanity ? 'Pending' : 'Posted';

    const conn = await db.promise().getConnection(); // ขอ connection จาก pool
    try {
      await conn.beginTransaction();

      const [result] = await conn.execute(
        `INSERT INTO Thread_reply
          (Thread_ID, User_ID, message, created_at, total_Likes, ai_evaluation, admin_decision)
          VALUES (?, ?, ?, NOW(), 0, ?, ?)`,
        [Thread_ID, User_ID, message, aiEvaluation, adminDecision]
      );

      const insertedId = result.insertId;

      if (hasProfanity) {
        await conn.execute(
          `INSERT INTO Admin_check_inappropriate_thread_reply
            (Thread_reply_ID, Admin_ID, admin_action_taken, admin_checked_at, reason_for_taken)
            VALUES (?, NULL, 'Pending', NULL, NULL)`,
          [insertedId]
        );
      }

      await conn.commit();
     res.json({
  message: 'Reply sent successfully',
  Thread_reply_ID: insertedId,
  ai_evaluation: aiEvaluation,
  admin_decision: adminDecision
});

    } catch (dbErr) {
      await conn.rollback();
      console.error(dbErr);
      res.status(500).json({ error: 'Database error' });
    } finally {
      conn.release(); // ปล่อย connection กลับ pool
    }
  } catch (err) {
    console.error('Error in AI checking:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.get('/api/all_users', (req, res) => {
  const sql = `
    SELECT 
      u.User_ID, 
      u.username, 
      p.picture_url
    FROM 
      User u
    LEFT JOIN 
      user_Profile_Picture p 
    ON 
      u.User_ID = p.User_ID AND p.is_active = 1
    WHERE 
      u.status = 'Active'
    ORDER BY 
      u.username ASC;
  `;

  db.query(sql, (err, results) => {
    if (err) {
      console.error('❌ Failed to fetch users with picture:', err);
      return res.status(500).json({ message: 'Internal Server Error' });
    }

    res.status(200).json(results);
  });
});


// ✅ API: คืนค่า URL ของรูปโปรไฟล์
app.get('/user_profile_picture/:userId', (req, res) => {
  const userId = req.params.userId;

  const sql = `
    SELECT picture_url 
    FROM user_Profile_Picture 
    WHERE User_ID = ? AND is_active = 1
    LIMIT 1
  `;

  db.query(sql, [userId], (err, results) => {
    if (err) {
      console.error('❌ Error fetching picture_url:', err);
      return res.status(500).json({ error: 'Internal Server Error' });
    }

   if (results.length > 0 && results[0].picture_url) {
  console.log(results[0].picture_url);  // log ก่อนส่ง
  return res.status(200).json({ picture_url: results[0].picture_url });
}
 else {
      // 🔄 ไม่เจอ → ส่ง default URL
      return res.status(200).json({
        picture_url: 'https://example.com/default-profile.jpg'
      });
    }
    
  });
});


app.put('/edit/restaurants/:id', async (req, res) => {
  const { id } = req.params;
  const { 
    restaurant_name, 
    location, 
    operating_hours, 
    phone_number, 
    category 
  } = req.body;

  // ตรวจสอบข้อมูลที่จำเป็น
  if (!restaurant_name || !location || !operating_hours || !phone_number || !category) {
    return res.status(400).json({ error: 'กรุณากรอกข้อมูลให้ครบถ้วน' });
  }

  try {
    // อัพเดทข้อมูลในฐานข้อมูล
    const [result] = await db.promise().execute(
      `UPDATE Restaurant SET 
        restaurant_name = ?, 
        location = ?, 
        operating_hours = ?, 
        phone_number = ?, 
        category = ?,
      WHERE Restaurant_ID = ?`,
      [restaurant_name, location, operating_hours, phone_number, category, id]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ error: 'ไม่พบร้านอาหาร' });
    }

    // ดึงข้อมูลร้านอาหารที่อัพเดทแล้ว
    const [updatedRestaurant] = await db.promise().execute(
      'SELECT * FROM restaurants WHERE Restaurant_ID = ?',
      [id]
    );

    res.json(updatedRestaurant[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'เกิดข้อผิดพลาดในการอัพเดทร้านอาหาร' });
  }
});





  // ✅ Start Server
  const PORT = process.env.PORT || 8080;
  app.listen(PORT, () => console.log(`🚀 API running on port ${PORT}`));