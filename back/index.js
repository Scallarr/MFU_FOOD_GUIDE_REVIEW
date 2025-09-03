  const express = require('express');
  const cors = require('cors');
  const mysql = require('mysql2');
  const jwt = require('jsonwebtoken');
  const axios = require('axios');
  const moment = require('moment-timezone');
  

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
    timezone: '+07:00',
  });





app.post('/user/login', (req, res) => {
  const { fullname, username, email, google_id, picture_url } = req.body;
  console.log('Login request:', req.body);

  // 1. ตรวจสอบว่ามีผู้ใช้อยู่แล้วหรือไม่โดยใช้ google_id
  const checkUserQuery = 'SELECT User_ID, fullname FROM User WHERE google_id = ?';
  
  db.query(checkUserQuery, [google_id], (err, userResults) => {
    if (err) {
      console.error('Database error checking user:', err);
      return res.status(500).json({ error: 'Database error checking user' });
    }

    if (userResults.length > 0) {
      // ผู้ใช้มีอยู่แล้ว - อัปเดตข้อมูล (ถ้าจำเป็น)
      const userId = userResults[0].User_ID;
      const currentFullname = userResults[0].fullname;
      
      // อัปเดตเฉพาะถ้า fullname ต่างจากเดิม
      if (currentFullname !== fullname) {
        const updateUserQuery = 'UPDATE User SET fullname = ? WHERE User_ID = ?';
        db.query(updateUserQuery, [fullname, userId], (err) => {
          if (err) console.error('Error updating user fullname:', err);
        });
      }
      
      // ดำเนินการต่อกับ profile picture และสร้าง token
      handleProfilePictureAndToken(userId, username, email, picture_url, res);
    } else {
      // ผู้ใช้ยังไม่มี - สร้างผู้ใช้ใหม่
      const createUserQuery = `
        INSERT INTO User (fullname, username, email, google_id)
        VALUES (?, ?, ?, ?)
      `;
      
      // สร้าง username ที่ไม่ซ้ำ
      const uniqueUsername = generateUniqueUsername(username);
      
      db.query(createUserQuery, [fullname, uniqueUsername, email, google_id], (err, result) => {
        if (err) {
          console.error('Error creating new user:', err);
          return res.status(500).json({ error: 'Error creating new user' });
        }
        
        const userId = result.insertId;
        console.log('New user created with ID:', userId);
        
        // ดำเนินการกับ profile picture และสร้าง token
        handleProfilePictureAndToken(userId, uniqueUsername, email, picture_url, res);
      });
    }
  });
});

// ฟังก์ชันช่วยจัดการ profile picture และสร้าง token (แก้ไขแล้ว)
function handleProfilePictureAndToken(userId, username, email, picture_url, res) {
  // ตรวจสอบว่ามีรูป profile อยู่แล้วหรือไม่
  const checkPictureQuery = 'SELECT * FROM user_Profile_Picture WHERE User_ID = ? LIMIT 1';
  
  db.query(checkPictureQuery, [userId], (err, picResults) => {
    if (err) {
      console.error('Error checking profile picture:', err);
      // ยังคงดำเนินการต่อแม้จะ error ในการตรวจสอบรูป
    }

    if (!picResults || picResults.length === 0) {
      // ถ้ายังไม่มีรูป ให้ insert
      const insertPicture = `
        INSERT INTO user_Profile_Picture (User_ID, picture_url, is_active)
        VALUES (?, ?, 1)
      `;
      db.query(insertPicture, [userId, picture_url], (err) => {
        if (err) console.error('Insert picture error:', err);
      });
    }

    // สร้าง token (ใช้ username และ email จากพารามิเตอร์)
    const token = jwt.sign(
      { userId, username, email },
      SECRET_KEY,
      { expiresIn: '7d' }
    );

    res.json({ 
      message: 'Login successful', 
      token, 
      userId,
      isNewUser: !picResults || picResults.length === 0
    });
  });
}

// ฟังก์ชันสร้าง username ที่ไม่ซ้ำ (เหมือนเดิม)
function generateUniqueUsername(baseUsername) {
  return `${baseUsername}${Math.floor(Math.random() * 1000)}`;
}
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
  const sql = `
    SELECT 
      r.Restaurant_ID,
      r.restaurant_name, 
      r.location, 
      r.operating_hours, 
      r.phone_number, 
      r.photos, 
      r.rating_overall_avg, 
      r.rating_hygiene_avg, 
      r.rating_flavor_avg, 
      r.rating_service_avg, 
      r.category,
      (SELECT COUNT(*) FROM Review WHERE Restaurant_id = r.Restaurant_ID AND message_status = 'Posted') AS posted_reviews_count,
      (SELECT COUNT(*) FROM Review WHERE Restaurant_id = r.Restaurant_ID AND message_status = 'Pending') AS pending_reviews_count,
      (SELECT COUNT(*) FROM Review WHERE Restaurant_id = r.Restaurant_ID AND message_status = 'Banned') AS banned_reviews_count,
      (SELECT COUNT(*) FROM Review WHERE Restaurant_id = r.Restaurant_ID) AS total_reviews_count
    FROM Restaurant r
  `;

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching restaurants:', err);
      return res.status(500).json({ error: 'Database query error' });
    }
    
    // แปลงผลลัพธ์ให้เหมาะสม
    const formattedResults = results.map(restaurant => ({
      ...restaurant,
      posted_reviews_count: parseInt(restaurant.posted_reviews_count) || 0,
      pending_reviews_count: parseInt(restaurant.pending_reviews_count) || 0,
      banned_reviews_count: parseInt(restaurant.banned_reviews_count) || 0,
      total_reviews_count: parseInt(restaurant.total_reviews_count) || 0
    }));

    res.json(formattedResults);
    console.log('Restaurants with review counts:', formattedResults);
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
  const userId = parseInt(req.query.user_id);

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
           r.message_status,r.ai_evaluation,
           u.username, u.email, p.picture_url,
           EXISTS (
             SELECT 1 FROM Review_Likes rl
             WHERE rl.Review_ID = r.Review_ID AND rl.User_ID = ?
           ) AS isLiked
    FROM Review r
    JOIN User u ON r.User_ID = u.User_ID
    LEFT JOIN user_Profile_Picture p 
      ON r.User_ID = p.User_ID AND p.is_active = 1
    WHERE r.restaurant_id = ? AND r.message_status = 'Posted'
    ORDER BY r.created_at DESC
  `;

  const pendingReviewCountQuery = `
    SELECT COUNT(*) AS pending_count
    FROM Review
    WHERE restaurant_id = ? AND message_status = 'Pending'
  `;

  const menuQuery = `
    SELECT Menu_ID, menu_thai_name, menu_english_name, price, menu_img
    FROM Menu
    WHERE restaurant_id = ?
  `;

  db.query(restaurantQuery, [restaurantId], (err, restRes) => {
    if (err || restRes.length === 0) return res.status(500).json({ error: 'Error fetching restaurant' });

    const restaurant = restRes[0];
    
    // Get pending review count
    db.query(pendingReviewCountQuery, [restaurantId], (errPending, pendingRes) => {
      if (errPending) return res.status(500).json({ error: 'Error fetching pending reviews count' });

      const pendingCount = pendingRes[0].pending_count || 0;
      restaurant.pending_reviews_count = pendingCount;

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

// GET /api/admin_review_history/:userId
// Returns review approval history for an admin user
// GET /api/admin_review_history/:userId
// Returns review approval history for an admin user
app.get('/api/admin_review_history/:userId', async (req, res) => {
  let connection;
  try {
    connection = await db.promise().getConnection();
    await connection.beginTransaction();
    
    const userId = req.params.userId;
    
    const query = `
      SELECT 
        r.Review_ID, r.Restaurant_ID, r.rating_overall, r.rating_hygiene, 
        r.rating_flavor, r.rating_service, r.comment, r.total_likes, 
        r.created_at, r.ai_evaluation, r.message_status,
        res.restaurant_name, res.location, res.photos, res.category, 
        res.operating_hours, res.phone_number,
        u.User_ID as user_id, u.username as user_username, u.email as user_email, 
        u.fullname as user_fullname,
        up.picture_url as user_picture,
        a.User_ID as admin_id, a.username as admin_username, 
        a.fullname as admin_fullname,
        ap.picture_url as admin_picture,
        ac.admin_action_taken, ac.admin_checked_at, ac.reason_for_taken
      FROM Admin_check_inappropriate_review ac
      INNER JOIN Review r ON ac.Review_ID = r.Review_ID
      INNER JOIN Restaurant res ON r.Restaurant_ID = res.Restaurant_ID
      INNER JOIN User u ON r.User_ID = u.User_ID
      LEFT JOIN User a ON ac.Admin_ID = a.User_ID
      LEFT JOIN user_Profile_Picture up ON u.User_ID = up.User_ID AND up.is_active = 1
      LEFT JOIN user_Profile_Picture ap ON a.User_ID = ap.User_ID AND ap.is_active = 1
      WHERE ac.Admin_ID = ?
      ORDER BY ac.admin_checked_at DESC
    `;
    
    const [results] = await connection.execute(query, [userId]);
    
    await connection.commit();
    res.json(results);
    
  } catch (error) {
    if (connection) await connection.rollback();
    console.error('Error fetching admin review history:', error);
    res.status(500).json({ error: 'Internal server error' });
  } finally {
    if (connection) connection.release();
  }
});



// Returns Pending Review of all restaurant
app.get('/Pending_review-all-restaurants', async (req, res) => {
  let connection;
  try {
    connection = await db.promise().getConnection();
    await connection.beginTransaction();
    

    
    const query = `
      SELECT 
        r.Review_ID, r.Restaurant_ID, r.rating_overall, r.rating_hygiene, 
        r.rating_flavor, r.rating_service, r.comment, r.total_likes, 
        r.created_at, r.ai_evaluation, r.message_status,
        res.restaurant_name, res.location, res.photos, res.category, 
        res.operating_hours, res.phone_number,
        u.User_ID as user_id, u.username as user_username, u.email as user_email, 
        u.fullname as user_fullname,
        up.picture_url as user_picture,
        a.User_ID as admin_id, a.username as admin_username, 
        a.fullname as admin_fullname,
        ap.picture_url as admin_picture,
        ac.admin_action_taken, ac.admin_checked_at, ac.reason_for_taken
      FROM Admin_check_inappropriate_review ac
      INNER JOIN Review r ON ac.Review_ID = r.Review_ID
      INNER JOIN Restaurant res ON r.Restaurant_ID = res.Restaurant_ID
      INNER JOIN User u ON r.User_ID = u.User_ID
      LEFT JOIN User a ON ac.Admin_ID = a.User_ID
      LEFT JOIN user_Profile_Picture up ON u.User_ID = up.User_ID AND up.is_active = 1
      LEFT JOIN user_Profile_Picture ap ON a.User_ID = ap.User_ID AND ap.is_active = 1
      WHERE r.message_status = 'pending'
      ORDER BY r.created_at DESC
    `;
    
    const [results] = await connection.execute(query);
    
    await connection.commit();
    res.json(results);
    
  } catch (error) {
    if (connection) await connection.rollback();
    console.error('Error fetching Peding:', error);
    res.status(500).json({ error: 'Internal server error' });
  } finally {
    if (connection) connection.release();
  }
});
// GET /api/my_reviews/:userId
// Returns all reviews by a specific user
// GET /api/my_reviews/:userId
// Returns all reviews by a specific user
app.get('/api/my_reviews/:userId', async (req, res) => {
  let connection;
  try {
    connection = await db.promise().getConnection();
    await connection.beginTransaction();

    const userId = req.params.userId;

    const query = `
      SELECT 
        r.Review_ID, r.Restaurant_ID, r.rating_overall, r.rating_hygiene, 
        r.rating_flavor, r.rating_service, r.comment, r.total_likes, 
        r.created_at, r.ai_evaluation, r.message_status,
        res.restaurant_name, res.location, res.photos, res.category, 
        res.operating_hours, res.phone_number,
        ac.admin_action_taken, ac.admin_checked_at, ac.reason_for_taken,
        a.username as admin_username,
        u.User_ID as user_id, u.username as user_username, u.email as user_email, 
        u.fullname as user_fullname,
        up.picture_url as user_picture
      FROM Review r
      INNER JOIN Restaurant res ON r.Restaurant_ID = res.Restaurant_ID
      LEFT JOIN (
          SELECT * FROM (
              SELECT *, ROW_NUMBER() OVER(PARTITION BY Review_ID ORDER BY admin_checked_at DESC) as rn
              FROM Admin_check_inappropriate_review 
          ) tmp
          WHERE rn = 1
      ) ac ON r.Review_ID = ac.Review_ID
      LEFT JOIN User a ON ac.Admin_ID = a.User_ID
      INNER JOIN User u ON r.User_ID = u.User_ID
      LEFT JOIN user_Profile_Picture up ON u.User_ID = up.User_ID AND up.is_active = 1
      WHERE r.User_ID = ?
      ORDER BY r.created_at DESC
    `;

    const [results] = await connection.execute(query, [userId]);

    await connection.commit();
    res.json(results);

  } catch (error) {
    if (connection) await connection.rollback();
    console.error('Error fetching user reviews:', error);
    res.status(500).json({ error: 'Internal server error' });
  } finally {
    if (connection) connection.release();
  }
});



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
    const now = moment().tz("Asia/Bangkok").toDate(); // เวลาไทยแบบ JS Date
    const rating_overall =
      (Number(rating_hygiene) + Number(rating_flavor) + Number(rating_service)) / 3;

    const ai_evaluation = await checkCommentAI(comment || '');
    const message_status = ai_evaluation === 'Safe' ? 'Posted' : 'Pending';

    // Insert review
 const [insertResult] = await db.promise().execute(
  `INSERT INTO Review 
  (User_ID, Restaurant_ID, rating_overall, rating_hygiene, rating_flavor, rating_service, comment, total_likes, ai_evaluation, message_status, created_at)
  VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
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
    now // เพิ่มตรงนี้
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
      (Review_ID,admin_action_taken, admin_checked_at)
     VALUES (?,'Pending', ?)`,
    [reviewId,now] // 1 = admin placeholder
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

// Get single thread by ID
app.get('/thread/:threadId/:userId', async (req, res) => {
  const threadId = req.params.threadId;
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
      JOIN User U ON T.User_ID = U.User_ID
      LEFT JOIN user_Profile_Picture P ON P.User_ID = U.User_ID AND P.is_active = 1
      WHERE T.Thread_ID = ?
        AND T.admin_decision = 'Posted'
    `, [userId, threadId]);

    if (rows.length === 0) {
      return res.status(404).json({ error: 'Thread not found' });
    }

    res.json(rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});


// Get count of pending replies for a specific thread
app.get('/api/pending_replies_count/:threadId', async (req, res) => {
  const threadId = req.params.threadId;

  try {
    const [rows] = await db.promise().execute(`
      SELECT COUNT(*) as count 
      FROM Thread_reply 
      WHERE Thread_ID = ? 
        AND admin_decision = 'Pending'
    `, [threadId]);

    res.json({ count: rows[0].count });
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
const now = moment().tz("Asia/Bangkok").toDate(); // แปลงเป็น JS Date object


    const [result] = await db.promise().execute(
      `INSERT INTO Thread 
       (User_ID, message, ai_evaluation, admin_decision, created_at, Total_likes)
       VALUES (?, ?, ?, ?, ?, 0)`,
      [User_ID, message, ai_evaluation, admin_decision,now]
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

const now = moment().tz("Asia/Bangkok").toDate(); // แปลงเป็น JS Date object

      const [result] = await conn.execute(
        `INSERT INTO Thread_reply
          (Thread_ID, User_ID, message, created_at, total_Likes, ai_evaluation, admin_decision)
          VALUES (?, ?, ?, ?, 0, ?, ?)`,
        [Thread_ID, User_ID, message, now,aiEvaluation, adminDecision]
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
    category ,
    image_url
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
        photos = ?
      WHERE Restaurant_ID = ?`,
      [restaurant_name, location, operating_hours, phone_number, category,image_url, id]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ error: 'ไม่พบร้านอาหาร' });
    }

    // ดึงข้อมูลร้านอาหารที่อัพเดทแล้ว
    const [updatedRestaurant] = await db.promise().execute(
      'SELECT * FROM Restaurant WHERE Restaurant_ID = ?',
      [id]
    );

    res.json(updatedRestaurant[0]);
    console.log(updatedRestaurant[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'เกิดข้อผิดพลาดในการอัพเดทร้านอาหาร' });
  }
});

// DELETE /Delete/restaurants/:id
// app.delete('/Delete/restaurants/:id', async (req, res) => {
//   const { id } = req.params;

//   try {
//     // 1. ตรวจสอบว่ามีร้านอาหารนี้อยู่จริงหรือไม่
//     const [checkResult] = await db.promise().execute(
//       'SELECT * FROM Restaurant WHERE Restaurant_ID = ?',
//       [id]
//     );

//     if (checkResult.length === 0) {
//       return res.status(404).json({ 
//         success: false,
//         message: 'ไม่พบร้านอาหารที่ต้องการลบ' 
//       });
//     }

//     // 2. ทำการลบร้านอาหาร
//     const [deleteResult] = await db.promise().execute(
//       'DELETE FROM Restaurant WHERE Restaurant_ID = ?',
//       [id]
//     );

//     // 3. ตรวจสอบว่าลบสำเร็จหรือไม่
//     if (deleteResult.affectedRows === 0) {
//       return res.status(400).json({
//         success: false,
//         message: 'Delete Restaurant Failed'
//       });
//     }

//     // 4. ส่ง response กลับ
//     res.status(200).json({
//       success: true,
//       message: 'Delete Restaurant Successfull',
//       deletedId: id
//     });

//   } catch (err) {
//     console.error('Error deleting restaurant:', err);
//     res.status(500).json({
//       success: false,
//       message: 'เกิดข้อผิดพลาดในการลบร้านอาหาร',
//       error: err.message
//     });
//   }
// });

app.delete('/Delete/restaurants/:id', async (req, res) => {
  const { id } = req.params;
  const connection = await db.promise().getConnection();

  try {
    await connection.beginTransaction();

    // 1. Check if restaurant exists
    const [checkResult] = await connection.execute(
      'SELECT * FROM Restaurant WHERE Restaurant_ID = ?',
      [id]
    );

    if (checkResult.length === 0) {
      connection.release();
      return res.status(404).json({ 
        success: false,
        message: 'ไม่พบร้านอาหารที่ต้องการลบ' 
      });
    }

    // 2. Get all users who reviewed this restaurant
    const [reviewers] = await connection.execute(
      'SELECT DISTINCT User_ID FROM Review WHERE Restaurant_ID = ?',
      [id]
    );

    // 3. Get all users who liked reviews of this restaurant
    const [likers] = await connection.execute(
      `SELECT DISTINCT l.User_ID 
       FROM Review_Likes l
       JOIN Review r ON l.Review_ID = r.Review_ID
       WHERE r.Restaurant_ID = ?`,
      [id]
    );

    // 4. Delete all likes for reviews of this restaurant
    await connection.execute(
      `DELETE l FROM Review_Likes l
       JOIN Review r ON l.Review_ID = r.Review_ID
       WHERE r.Restaurant_ID = ?`,
      [id]
    );

    // 5. Delete all reviews for this restaurant
    const [deleteReviewsResult] = await connection.execute(
      'DELETE FROM Review WHERE Restaurant_ID = ?',
      [id]
    );

    // 6. Delete the restaurant
    const [deleteResult] = await connection.execute(
      'DELETE FROM Restaurant WHERE Restaurant_ID = ?',
      [id]
    );

    if (deleteResult.affectedRows === 0) {
      await connection.rollback();
      connection.release();
      return res.status(400).json({
        success: false,
        message: 'Delete Restaurant Failed'
      });
    }

    // 7. Update review counts for all affected users
    for (const user of reviewers) {
      const [countResult] = await connection.execute(
        'SELECT COUNT(*) AS reviewCount FROM Review WHERE User_ID = ? AND message_status = "Posted"',
        [user.User_ID]
      );
      
      await connection.execute(
        'UPDATE User SET total_reviews = ? WHERE User_ID = ?',
        [countResult[0].reviewCount, user.User_ID]
      );
    }

    // 8. Update like counts for all affected users
    for (const user of likers) {
      const [countResult] = await connection.execute(
        `SELECT COUNT(*) AS likeCount 
         FROM Review_Likes l
         JOIN Review r ON l.Review_ID = r.Review_ID
         WHERE l.User_ID = ? AND r.message_status = "Posted"`,
        [user.User_ID]
      );
      
      await connection.execute(
        'UPDATE User SET total_likes = ? WHERE User_ID = ?',
        [countResult[0].likeCount, user.User_ID]
      );
    }

    await connection.commit();
    connection.release();

    res.status(200).json({
      success: true,
      message: 'Delete Restaurant Successfully',
      deletedId: id,
      deletedReviews: deleteReviewsResult.affectedRows,
      affectedUsers: {
        reviewers: reviewers.length,
        likers: likers.length
      }
    });

  } catch (err) {
    await connection.rollback();
    connection.release();
    console.error('Error deleting restaurant:', err);
    res.status(500).json({
      success: false,
      message: 'เกิดข้อผิดพลาดในการลบร้านอาหาร',
      error: err.message
    });
  }
});


// Add Restaurant Endpoint
app.post('/Add/restaurants', async (req, res) => {
  const {
    restaurant_name,
    location,
    operating_hours,
    phone_number,
    photos,
    category,
    added_by
  } = req.body;

  // Validate required fields
  if (!restaurant_name || !location || !category || !photos) {
    return res.status(400).json({ 
      error: 'Missing required fields: name, location, category, and photo are required' 
    });
  }


   
    
    try {
      // Insert new restaurant
      const [result] = await db.promise().execute(
        `INSERT INTO Restaurant 
        (restaurant_name, location, operating_hours, phone_number, photos, category) 
        VALUES (?, ?, ?, ?, ?, ?)`,
        [restaurant_name, location, operating_hours, phone_number, photos, category]
      );

      // Get the newly created restaurant
      const [rows] = await db.promise().execute(
        `SELECT 
          Restaurant_ID as id,
          restaurant_name as name,
          location,
          operating_hours as operatingHours,
          phone_number as phoneNumber,
          photos as photoUrl,
          category,
          rating_overall_avg as ratingOverall,
          rating_hygiene_avg as ratingHygiene,
          rating_flavor_avg as ratingFlavor,
          rating_service_avg as ratingService,
          0 as pendingReviewsCount,
          0 as postedReviewsCount
        FROM Restaurant WHERE Restaurant_ID = ?`,
        [result.insertId]
      );

      res.status(201).json(rows[0]);
    } 
   catch (err) {
    console.error(err);
    res.status(500).json({ error: 'เกิดข้อผิดพลาดในการอัพเดทร้านอาหาร' });
  }
})

// Error handling middleware

// GET /reviews/pending?restaurantId={restaurantId}
app.get('/reviews/pending', async (req, res) => {
  const { restaurantId } = req.query;

  try {
    const query = `
      SELECT 
        r.Review_ID,
        r.rating_overall,
        r.rating_hygiene,
        r.rating_flavor,
        r.rating_service,
        r.comment,
        r.created_at,
        r.ai_evaluation,
        r.message_status,
        u.User_ID,
        u.fullname,
        u.username,
        u.email,
        p.picture_url,
        res.restaurant_name,
        res.location,
        res.photos,
        res.category
      FROM 
        Review r
      JOIN 
        User u ON r.User_ID = u.User_ID
      LEFT JOIN 
        user_Profile_Picture p ON u.User_ID = p.User_ID AND p.is_active = 1
      JOIN
        Restaurant res ON r.Restaurant_ID = res.Restaurant_ID
      WHERE 
        r.Restaurant_ID = ? 
        AND r.message_status = 'Pending'
      ORDER BY 
        r.created_at DESC
    `;

    const [results] = await db.promise().execute(query, [restaurantId]);

    res.json(results);
  } catch (err) {
    console.error('Error fetching pending reviews:', err);
    res.status(500).json({ error: 'Failed to fetch pending reviews' });
  }
});



// Approve review endpoint
app.post('/api/reviews/approve', async (req, res) => {
  const { reviewId, adminId } = req.body;
  
  if (!reviewId) {
    return res.status(400).json({ success: false, message: 'Review ID is required' });
  }

  const connection = await db.promise().getConnection();

  try {
    await connection.beginTransaction();
const now = moment().tz("Asia/Bangkok").toDate(); // แปลงเป็น JS Date object
    // 1. Get review details including restaurant ID
    const [reviewResult] = await connection.execute(
      `SELECT User_ID, Restaurant_ID, rating_overall, rating_hygiene, rating_flavor, rating_service 
       FROM Review WHERE Review_ID = ?`,
      [reviewId]
    );

    if (reviewResult.length === 0) {
      connection.release();
      return res.status(404).json({ success: false, message: 'Review not found' });
    }

    const { User_ID: userId, Restaurant_ID: restaurantId } = reviewResult[0];

    // 2. Update review status to 'Posted'
    const [updateResult] = await connection.execute(
      `UPDATE Review 
       SET message_status = 'Posted', created_at = ?
       WHERE Review_ID = ?`, 
      [now,reviewId ]
    );

    if (updateResult.affectedRows === 0) {
      await connection.rollback();
      connection.release();
      return res.status(404).json({ success: false, message: 'Review not found' });
    }

    // 3. Count all posted reviews for this user
    const [countResult] = await connection.execute(
      `SELECT COUNT(*) AS totalPostedReviews 
       FROM Review 
       WHERE User_ID = ? AND message_status = 'Posted'`,
      [userId]
    );

    const totalPostedReviews = countResult[0].totalPostedReviews;

    // 4. Update user's total_reviews count
    await connection.execute(
      `UPDATE User 
       SET total_reviews = ? 
       WHERE User_ID = ?`,
      [totalPostedReviews, userId]
    );

    // 5. Calculate new averages for the restaurant
    const [avgResult] = await connection.execute(
      `SELECT 
        AVG(rating_overall) AS avg_overall,
        AVG(rating_hygiene) AS avg_hygiene,
        AVG(rating_flavor) AS avg_flavor,
        AVG(rating_service) AS avg_service
       FROM Review 
       WHERE Restaurant_ID = ? AND message_status = 'Posted'`,
      [restaurantId]
    );

    // 6. Update restaurant averages
    await connection.execute(
      `UPDATE Restaurant SET
        rating_overall_avg = ?,
        rating_hygiene_avg = ?,
        rating_flavor_avg = ?,
        rating_service_avg = ?
       WHERE Restaurant_ID = ?`,
      [
        avgResult[0].avg_overall || 0,
        avgResult[0].avg_hygiene || 0,
        avgResult[0].avg_flavor || 0,
        avgResult[0].avg_service || 0,
        restaurantId
      ]
    );

    // 7. Update existing admin action record instead of inserting
    const [updateAdminResult] = await connection.execute(
      `UPDATE Admin_check_inappropriate_review 
       SET admin_action_taken = 'Safe',
           admin_checked_at = ?,
           reason_for_taken = 'Appropriate message',
           Admin_ID = ?
       WHERE Review_ID = ?`,
      [now,adminId || 1, reviewId]
    );

    // If no existing record was found, insert a new one
    if (updateAdminResult.affectedRows === 0) {
      await connection.execute(
        `INSERT INTO Admin_check_inappropriate_review 
         (Review_ID, Admin_ID, admin_action_taken, admin_checked_at, reason_for_taken)
         VALUES (?, ?, 'Safe', ?, 'Appropriate message')`,
        [reviewId, adminId || 1,now]
      );
    }

    await connection.commit();
    connection.release();
    
    res.status(200).json({ 
      success: true, 
      message: 'Review approved successfully',
      totalPostedReviews: totalPostedReviews,
      restaurantId: restaurantId,
      newAverages: {
        overall: avgResult[0].avg_overall,
        hygiene: avgResult[0].avg_hygiene,
        flavor: avgResult[0].avg_flavor,
        service: avgResult[0].avg_service
      }
    });
  } catch (error) {
    await connection.rollback();
    connection.release();
    console.error('Approval error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Failed to approve review',
      error: error.message 
    });
  }
});

app.post('/api/reviews/reject', async (req, res) => {
  const { reviewId, adminId, reason } = req.body;

  if (!reviewId) {
    return res.status(400).json({ success: false, message: 'Review ID is required' });
  }

  const connection = await db.promise().getConnection();

  try {
    await connection.beginTransaction();

    const now = moment().tz("Asia/Bangkok").toDate(); // เวลาไทย กำหนดครั้งเดียว

    // 1. Get review details
    const [reviewDetails] = await connection.execute(
      `SELECT User_ID, Restaurant_ID FROM Review WHERE Review_ID = ?`,
      [reviewId]
    );

    if (reviewDetails.length === 0) {
      await connection.rollback();
      connection.release();
      return res.status(404).json({ success: false, message: 'Review not found' });
    }

    const userId = reviewDetails[0].User_ID;
    const restaurantId = reviewDetails[0].Restaurant_ID;

    // 2. Update review status
    await connection.execute(
      `UPDATE Review SET message_status = 'Banned', created_at = ? WHERE Review_ID = ?`, 
      [now,reviewId]
    );

    // 3. Update or insert admin action with time
    const [updateAdminResult] = await connection.execute(
      `UPDATE Admin_check_inappropriate_review 
       SET admin_action_taken = 'Banned',
           admin_checked_at = ?,
           reason_for_taken = ?,
           Admin_ID = ?
       WHERE Review_ID = ?`,
      [now, reason || 'Inappropriate message', adminId || 1, reviewId]
    );

    if (updateAdminResult.affectedRows === 0) {
      await connection.execute(
        `INSERT INTO Admin_check_inappropriate_review 
         (Review_ID, Admin_ID, admin_action_taken, admin_checked_at, reason_for_taken)
         VALUES (?, ?, 'Banned', ?, ?)`,
        [reviewId, adminId || 1, now, reason || 'Inappropriate message']
      );
    }

    // 4. Count posted reviews
    const [countResult] = await connection.execute(
      `SELECT COUNT(*) AS totalPostedReviews 
       FROM Review 
       WHERE User_ID = ? AND message_status = 'Posted'`,
      [userId]
    );

    const totalPostedReviews = countResult[0].totalPostedReviews;

    // 5. Update user's total_reviews
    await connection.execute(
      `UPDATE User SET total_reviews = ? WHERE User_ID = ?`,
      [totalPostedReviews, userId]
    );

    // 6. Update restaurant averages
    const [avgResult] = await connection.execute(
      `SELECT 
        AVG(rating_overall) AS avg_overall,
        AVG(rating_hygiene) AS avg_hygiene,
        AVG(rating_flavor) AS avg_flavor,
        AVG(rating_service) AS avg_service
       FROM Review 
       WHERE Restaurant_ID = ? AND message_status = 'Posted'`,
      [restaurantId]
    );

    await connection.execute(
      `UPDATE Restaurant SET
        rating_overall_avg = ?,
        rating_hygiene_avg = ?,
        rating_flavor_avg = ?,
        rating_service_avg = ?
       WHERE Restaurant_ID = ?`,
      [
        avgResult[0].avg_overall || 0,
        avgResult[0].avg_hygiene || 0,
        avgResult[0].avg_flavor || 0,
        avgResult[0].avg_service || 0,
        restaurantId
      ]
    );

    await connection.commit();
    connection.release();

    res.status(200).json({ 
      success: true, 
      message: 'Review rejected successfully',
      userId,
      restaurantId,
      newReviewCount: totalPostedReviews,
      newAverages: {
        overall: avgResult[0].avg_overall,
        hygiene: avgResult[0].avg_hygiene,
        flavor: avgResult[0].avg_flavor,
        service: avgResult[0].avg_service
      }
    });
  } catch (error) {
    await connection.rollback();
    connection.release();
    console.error('Rejection error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Failed to reject review',
      error: error.message 
    });
  }
});

// API บันทึกเมนู
app.post('/Add/menus', async (req, res) => {
  // ตรวจสอบข้อมูลที่จำเป็น
  const { restaurantId, menuThaiName, menuEnglishName, price, menuImage } = req.body;

  // ตรวจสอบว่ามีข้อมูลครบถ้วน
  if (!restaurantId || !menuThaiName || !price || !menuImage) {
    return res.status(400).json({ 
      success: false, 
      error: 'Missing required fields (restaurantId, menuThaiName, price, menuImage)' 
    });
  }

  // ตรวจสอบว่า price เป็นตัวเลข
  if (isNaN(parseFloat(price))) {
    return res.status(400).json({ 
      success: false, 
      error: 'Price must be a number' 
    });
  }

  const connection = await db.promise().getConnection();
  
  try {
    await connection.beginTransaction();
    
    // ตรวจสอบว่า restaurant มีอยู่จริง
    const [restaurantRows] = await connection.execute(
      'SELECT 1 FROM Restaurant WHERE Restaurant_ID = ? LIMIT 1',
      [restaurantId]
    );
    
    if (restaurantRows.length === 0) {
      return res.status(404).json({ 
        success: false, 
        error: 'Restaurant not found' 
      });
    }

    // เพิ่มเมนูใหม่
    const [result] = await connection.execute(
      `INSERT INTO Menu (
        Restaurant_ID,
        menu_thai_name,
        menu_english_name,
        price,
        menu_img
      ) VALUES (?, ?, ?, ?, ?)`,
      [restaurantId, menuThaiName, menuEnglishName || null, parseFloat(price), menuImage]
    );

    await connection.commit();
    
    // ส่งข้อมูลเมนูที่เพิ่งสร้างกลับไป
    const [newMenu] = await connection.execute(
      'SELECT * FROM Menu WHERE Menu_ID = ?',
      [result.insertId]
    );

    res.status(201).json({ 
      success: true,
      menu: newMenu[0]
    });
  } catch (error) {
    await connection.rollback();
    console.error('Error adding menu:', error);
    
    // ตรวจสอบว่าเป็น error จาก MySQL
    if (error.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({ 
        success: false, 
        error: 'Menu already exists for this restaurant' 
      });
    }
    
    res.status(500).json({ 
      success: false, 
      error: 'Internal server error',
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  } finally {
    connection.release();
  }
});

// API ลบเมนู (ใช้ DELETE)
app.delete('/Delete/menus/:id', async (req, res) => {
  const connection = await db.promise().getConnection();
  
  try {
    const menuId = req.params.id;
    
    // ตรวจสอบ ID
    if (!menuId || isNaN(menuId)) {
      connection.release();
      return res.status(400).json({ 
        success: false,
        message: 'รหัสเมนูไม่ถูกต้อง' 
      });
    }

    await connection.beginTransaction();

    // เช็คว่าเมนูมีอยู่จริง
    const [checkMenu] = await connection.execute(
      'SELECT Menu_ID, menu_thai_name FROM Menu WHERE Menu_ID = ?',
      [menuId]
    );

    if (checkMenu.length === 0) {
      await connection.rollback();
      connection.release();
      return res.status(404).json({ 
        success: false,
        message: 'ไม่พบเมนูนี้ในระบบ' 
      });
    }

    // ลบเมนูจากฐานข้อมูล
    const [result] = await connection.execute(
      'DELETE FROM Menu WHERE Menu_ID = ?',
      [menuId]
    );

    if (result.affectedRows === 0) {
      await connection.rollback();
      connection.release();
      return res.status(500).json({ 
        success: false,
        message: 'ลบเมนูไม่สำเร็จ' 
      });
    }

    await connection.commit();
    connection.release();

    res.status(200).json({ 
      success: true,
      message: `ลบเมนู "${checkMenu[0].menu_thai_name}" สำเร็จแล้ว`
    });

  } catch (error) {
    console.error('Error deleting menu:', error);
    try {
      await connection.rollback();
    } catch (rollbackError) {
      console.error('Rollback failed:', rollbackError);
    }
    connection.release();
    res.status(500).json({ 
      success: false,
      message: 'เกิดข้อผิดพลาดในการลบเมนู' 
    });
  }
});

// แก้ไขเมนู (ใช้ PUT)
app.put('/Edit/Menu/:menuId', async (req, res) => {
  const { menuId } = req.params;
  const { 
    restaurantId,
    menuThaiName, 
    menuEnglishName, 
    price, 
    menuImage 
  } = req.body;

  // Validate input
  if (!menuThaiName || !price || isNaN(price)) {
    return res.status(400).json({ 
      success: false,
      message: 'กรุณากรอกข้อมูลให้ครบถ้วน'
    });
  }

  const connection = await db.promise().getConnection();
  try {
    await connection.beginTransaction();

    // ตรวจสอบว่าเมนูมีอยู่จริง
    const [existingMenu] = await connection.execute(
      'SELECT * FROM Menu WHERE Menu_ID = ?', 
      [menuId]
    );

    if (existingMenu.length === 0) {
      await connection.rollback();
      connection.release();
      return res.status(404).json({ 
        success: false,
        message: 'ไม่พบเมนูนี้ในระบบ'
      });
    }

    // อัพเดทข้อมูลใน MySQL
    const [result] = await connection.execute(
      `UPDATE Menu SET 
        Restaurant_ID = ?,
        menu_thai_name = ?,
        menu_english_name = ?,
        price = ?,
        menu_img = ?
      WHERE Menu_ID = ?`,
      [
        restaurantId,
        menuThaiName,
        menuEnglishName || null,
        parseFloat(price),
        menuImage,
        menuId
      ]
    );

    if (result.affectedRows === 0) {
      await connection.rollback();
      connection.release();
      return res.status(500).json({ 
        success: false,
        message: 'อัพเดทเมนูไม่สำเร็จ'
      });
    }

    // ดึงข้อมูลเมนูที่อัพเดทแล้ว
    const [updatedMenu] = await connection.execute(
      'SELECT * FROM Menu WHERE Menu_ID = ?',
      [menuId]
    );

    await connection.commit();
    connection.release();

    res.status(200).json({
      success: true,
      data: updatedMenu[0]
    });

  } catch (error) {
    console.error('Error updating menu:', error);
    try {
      await connection.rollback();
    } catch (rollbackError) {
      console.error('Rollback failed:', rollbackError);
    }
    connection.release();
    res.status(500).json({ 
      success: false,
      message: 'เกิดข้อผิดพลาดในการอัพเดทเมนู'
    });
  }
});




// POST endpoint สำหรับเพิ่มโปรไฟล์ใหม่ (รับ URL รูปภาพจาก Frontend)
app.post('/Add/profiles', async (req, res) => {
  const connection = await db.promise().getConnection();
  
  try {
    await connection.beginTransaction();
    const now = moment().tz("Asia/Bangkok").toDate(); // แปลงเป็น JS Date object
    const { profileName, description, imageUrl, requiredCoins } = req.body;

    // ตรวจสอบข้อมูลที่จำเป็น
    if (!profileName || !description || !imageUrl || !requiredCoins) {
      await connection.rollback();
      connection.release();
      return res.status(400).json({ 
        error: 'Missing required fields: profileName, description, imageUrl, requiredCoins' 
      });
    }

    // เพิ่มข้อมูลลงฐานข้อมูล
    const [result] = await connection.execute(
      `INSERT INTO exchange_coin_Shop 
       (Profile_Name, Description, Image_URL, Required_Coins, Created_At)
       VALUES (?, ?, ?, ?, ?)`,
      [profileName, description, imageUrl, requiredCoins,now]
    );

    // ดึงข้อมูลโปรไฟล์ที่เพิ่งสร้างเพื่อส่งกลับ
    const [newProfile] = await connection.execute(
      'SELECT * FROM exchange_coin_Shop WHERE Profile_Shop_ID = ?',
      [result.insertId]
    );

    await connection.commit();
    connection.release();
    
    res.status(201).json(newProfile[0]);
  } catch (error) {
    await connection.rollback();
    connection.release();
    
    console.error('Error creating profile:', error);
    res.status(500).json({ 
      error: 'Internal server error',
      details: error.message 
    });
  }
});

app.delete('/delete_profile/:id', async (req, res) => {
 const connection = await db.promise().getConnection();
  
  try {
    await connection.beginTransaction();
    
    const { id } = req.params;
    
    // 1. ลบข้อมูลโปรไฟล์
    await connection.execute(
      'DELETE FROM exchange_coin_Shop WHERE Profile_Shop_ID = ?',
      [id]
    );
    
    // 2. ลบข้อมูลที่เกี่ยวข้อง (ถ้ามี)
    // เช่น ลบประวัติการซื้อโปรไฟล์นี้
    await connection.execute(
      'DELETE FROM user_Profile_Picture WHERE Picture_ID = ?',
      [id]
    );
    
    await connection.commit();
    connection.release();
    
    res.status(200).json({ 
      success: true,
      message: 'Profile deleted successfully'
    });
  } catch (error) {
    await connection.rollback();
    connection.release();
    
    console.error('Error deleting profile:', error);
    res.status(500).json({ 
      success: false,
      error: 'Internal server error',
      details: error.message 
    });
  }
});


app.put('/api/profiles/:id', async (req, res) => {
  const connection = await db.promise().getConnection();
  
  try {
    await connection.beginTransaction();
    
    const { id } = req.params;
    const { profileName, description, imageUrl, requiredCoins } = req.body;

    // ตรวจสอบข้อมูลที่จำเป็น
    if (!profileName || !description || !imageUrl || !requiredCoins) {
      await connection.rollback();
      connection.release();
      return res.status(400).json({ 
        error: 'Missing required fields: profileName, description, imageUrl, requiredCoins' 
      });
    }

    // อัพเดทข้อมูลในฐานข้อมูล
    const [result] = await connection.execute(
      `UPDATE exchange_coin_Shop 
       SET Profile_Name = ?, Description = ?, Image_URL = ?, Required_Coins = ?
       WHERE Profile_Shop_ID = ?`,
      [profileName, description, imageUrl, requiredCoins, id]
    );

    // ตรวจสอบว่ามีแถวถูกอัพเดทหรือไม่
    if (result.affectedRows === 0) {
      await connection.rollback();
      connection.release();
      return res.status(404).json({ error: 'Profile not found' });
    }

    await connection.commit();
    connection.release();
    
    res.status(200).json({ 
      success: true,
      message: 'Profile updated successfully',
      updatedProfile: {
        id,
        profileName,
        description,
        imageUrl,
        requiredCoins
      }
    });
  } catch (error) {
    await connection.rollback();
    connection.release();
    
    console.error('Error updating profile:', error);
    res.status(500).json({ 
      success: false,
      error: 'Internal server error',
      details: error.message 
    });
  }
});

// GET /threads/pending
app.get('/threads/pending', async (req, res) => {
  try {
    const connection = await db.promise().getConnection();
    const [rows] = await connection.execute(`
      SELECT t.Thread_ID, t.User_ID, u.username, 
             upp.picture_url, t.message, t.created_at, 
             t.Total_likes, t.ai_evaluation, t.admin_decision
      FROM Thread t
      JOIN User u ON t.User_ID = u.User_ID
      LEFT JOIN user_Profile_Picture upp ON u.User_ID = upp.User_ID AND upp.is_active = 1
      WHERE t.admin_decision = 'Pending'
      ORDER BY t.created_at DESC
    `);
    connection.release();
    res.json(rows);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// POST /threads/approve
app.post('/threads/approve', async (req, res) => {
  const { threadId, adminId } = req.body;
  
  try {
    const connection = await db.promise().getConnection();
    const now = moment().tz("Asia/Bangkok").toDate(); // แปลงเป็น JS Date object
    await connection.beginTransaction();

    
    // Update thread status in Thread table
    await connection.execute(
      'UPDATE Thread SET  created_at= ? , admin_decision = "Posted" WHERE Thread_ID = ?',
      [now,threadId]
    );
    
    // Update or create record in Admin_check_inappropriate_thread table
    const [existingCheck] = await connection.execute(
      'SELECT * FROM Admin_check_inappropriate_thread WHERE Thread_ID = ?',
      [threadId]
    );
    
    if (existingCheck.length > 0) {
      // Update existing record
      await connection.execute(
        `UPDATE Admin_check_inappropriate_thread 
         SET Admin_ID = ?, admin_action_taken = 'Safe', admin_checked_at = ?
         WHERE Thread_ID = ?`,
        [adminId, now,threadId]
      );
    } else {
      // Create new record
      await connection.execute(
        `INSERT INTO Admin_check_inappropriate_thread 
         (Thread_ID, Admin_ID, admin_action_taken, admin_checked_at) 
         VALUES (?, ?, 'Safe', ?)`,
        [threadId, adminId,now]
      );
    }
    
    await connection.commit();
    connection.release();
    
    res.json({ success: true, message: 'Thread approved successfully' });
  } catch (error) {
    console.error(error);
    if (connection) await connection.rollback();
    res.status(500).json({ error: 'Failed to approve thread' });
  }
});

// POST /threads/reject
app.post('/threads/reject', async (req, res) => {
  const { threadId, adminId, reason } = req.body;
  
  try {
   const connection = await db.promise().getConnection();
   const now = moment().tz("Asia/Bangkok").toDate(); // แปลงเป็น JS Date object
    await connection.beginTransaction();
    
    // Update thread status in Thread table
    await connection.execute(
      'UPDATE Thread SET  created_at= ?,  admin_decision = "Banned" WHERE Thread_ID = ?',
      [now,threadId]
    );
    
    // Update or create record in Admin_check_inappropriate_thread table
    const [existingCheck] = await connection.execute(
      'SELECT * FROM Admin_check_inappropriate_thread WHERE Thread_ID = ?',
      [threadId]
    );
    
    if (existingCheck.length > 0) {
      // Update existing record
      await connection.execute(
        `UPDATE Admin_check_inappropriate_thread 
         SET Admin_ID = ?, admin_action_taken = 'Banned', 
         admin_checked_at = ?, reason_for_taken = ? 
         WHERE Thread_ID = ?`,
        [adminId, now,reason, threadId]
      );
    } else {
      // Create new record
      await connection.execute(
        `INSERT INTO Admin_check_inappropriate_thread 
         (Thread_ID, Admin_ID, admin_action_taken, admin_checked_at, reason_for_taken) 
         VALUES (?, ?, 'Banned', ?, ?)`,
        [threadId, adminId, now,reason]
      );
    }
    
    await connection.commit();
    connection.release();
    
    res.json({ success: true, message: 'Thread rejected successfully' });
  } catch (error) {
    console.error(error);
    if (connection) await connection.rollback();
    res.status(500).json({ error: 'Failed to reject thread' });
  }
});
app.post('/threads/AdminManual-check/reject', async (req, res) => {
  const { threadId, adminId, reason } = req.body;
  
  try {
   const connection = await db.promise().getConnection();
   const now = moment().tz("Asia/Bangkok").toDate(); // แปลงเป็น JS Date object
    await connection.beginTransaction();
    
    // Update thread status in Thread table
    await connection.execute(
      'UPDATE Thread SET  created_at= ?,  admin_decision = "Banned" WHERE Thread_ID = ?',
      [now,threadId]
    );
    
    // Update or create record in Admin_check_inappropriate_thread table

    
 
  
      // Create new record
      await connection.execute(
        `INSERT INTO Admin_check_inappropriate_thread 
         (Thread_ID, Admin_ID, admin_action_taken, admin_checked_at, reason_for_taken) 
         VALUES (?, ?, 'Banned', ?, ?)`,
        [threadId, adminId, now,reason]
      );
   
    
    await connection.commit();
    connection.release();
    
    res.json({ success: true, message: 'Thread rejected successfully' });
  } catch (error) {
    console.error(error);
    if (connection) await connection.rollback();
    res.status(500).json({ error: 'Failed to reject thread' });
  }
});
app.post('/review/AdminManual-check/reject', async (req, res) => {
  const { rewiewId, adminId, reason } = req.body;
  
  try {
   const connection = await db.promise().getConnection();
   const now = moment().tz("Asia/Bangkok").toDate(); // แปลงเป็น JS Date object
    await connection.beginTransaction();
    
    // Update thread status in Thread table
    await connection.execute(
      'UPDATE Review SET  created_at= ?,  message_status = "Banned" WHERE Review_ID = ?',
      [now,rewiewId]
    );
    
    // Update or create record in Admin_check_inappropriate_thread table

    
 
  
      // Create new record
      await connection.execute(
        `INSERT INTO Admin_check_inappropriate_review 
         (Review_ID, Admin_ID, admin_action_taken, admin_checked_at, reason_for_taken) 
         VALUES (?, ?, 'Banned', ?, ?)`,
        [rewiewId, adminId, now,reason]
      );
   
    
    await connection.commit();
    connection.release();
    
    res.json({ success: true, message: 'Banned Review successfully' });
  } catch (error) {
    console.error(error);
    if (connection) await connection.rollback();
    res.status(500).json({ error: 'Failed to Banned Review' });
  }
});


// GET /threads-replied/pending/:threadId
app.get('/threads-replied/pending/:threadId', async (req, res) => {
  try {
    const threadId = req.params.threadId;
    const connection = await db.promise().getConnection();
    
    const [rows] = await connection.execute(`
      SELECT 
        tr.Thread_reply_ID,
        tr.Thread_ID,
        tr.User_ID,
        u.username,
        upp.picture_url,
        tr.message,
        tr.created_at,
        tr.total_Likes,
        tr.ai_evaluation,
        tr.admin_decision,
        t.Thread_ID as original_thread_id,
        tu.username as replied_to_username
      FROM Thread_reply tr
      JOIN User u ON tr.User_ID = u.User_ID
      JOIN Thread t ON tr.Thread_ID = t.Thread_ID
      JOIN User tu ON t.User_ID = tu.User_ID
      LEFT JOIN user_Profile_Picture upp ON u.User_ID = upp.User_ID AND upp.is_active = 1
      WHERE tr.admin_decision = 'Pending' AND tr.Thread_ID = ?
      ORDER BY tr.created_at DESC
    `, [threadId]);
    
    connection.release();
    res.json(rows);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Internal server error' });
  }
});



// GET /threads/pending
app.get('/threads-replied/pending', async (req, res) => {
  try {
    const connection = await db.promise().getConnection();
    const [rows] = await connection.execute(`
     SELECT 
    tr.Thread_reply_ID,
    tr.Thread_ID,
    tr.User_ID,
    u.username,
    upp.picture_url,
    tr.message,
    tr.created_at,
    tr.total_Likes,
    tr.ai_evaluation,
    tr.admin_decision,
    t.Thread_ID as original_thread_id,
    tu.username as replied_to_username
FROM Thread_reply tr
JOIN User u ON tr.User_ID = u.User_ID
JOIN Thread t ON tr.Thread_ID = t.Thread_ID
JOIN User tu ON t.User_ID = tu.User_ID
LEFT JOIN user_Profile_Picture upp ON u.User_ID = upp.User_ID AND upp.is_active = 1
WHERE tr.admin_decision = 'Pending'
ORDER BY tr.created_at DESC
    `);
    connection.release();
    res.json(rows);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// POST /threads/approve
app.post('/threads-replied/approve', async (req, res) => {
  const { threadId, adminId } = req.body;
  
  try {
    const now = moment().tz("Asia/Bangkok").toDate(); // JS Date object
    const connection = await db.promise().getConnection();
    await connection.beginTransaction();
    
    // Update thread status in Thread_reply table
    await connection.execute(
      'UPDATE Thread_reply SET created_at = ?, admin_decision = "Posted" WHERE Thread_reply_ID = ?',
      [now, threadId]
    );
    
    // Check if record already exists
    const [existingCheck] = await connection.execute(
      'SELECT * FROM Admin_check_inappropriate_thread_reply WHERE Thread_reply_ID = ?',
      [threadId]
    );
    
    if (existingCheck.length > 0) {
      // Update existing record
      await connection.execute(
        `UPDATE Admin_check_inappropriate_thread_reply 
         SET Admin_ID = ?, admin_action_taken = 'Safe', admin_checked_at = ?, reason_for_taken = ? 
         WHERE Thread_reply_ID = ?`,
        [adminId, now, "No inappropriate words found", threadId]
      );
    } else {
      // Insert new record
      await connection.execute(
        `INSERT INTO Admin_check_inappropriate_thread_reply 
         (Thread_reply_ID, Admin_ID, admin_action_taken, admin_checked_at, reason_for_taken) 
         VALUES (?, ?, 'Safe', ?, ?)`,
        [threadId, adminId, now, "No inappropriate words found"]
      );
    }
    
    await connection.commit();
    connection.release();
    
    res.json({ success: true, message: 'Thread approved successfully' });
  } catch (error) {
    console.error(error);
    if (connection) await connection.rollback();
    res.status(500).json({ error: 'Failed to approve thread' });
  }
});

// POST /threads/reject
app.post('/threads-replied/reject', async (req, res) => {
  const { threadId, adminId, reason } = req.body;
  
  try {
    const connection = await db.promise().getConnection();
    const now = moment().tz("Asia/Bangkok").toDate(); // แปลงเป็น JS Date object
    await connection.beginTransaction();
    
    // Update thread status in Thread table
    await connection.execute(
      'UPDATE Thread_reply SET  created_at= ? , admin_decision = "Banned" WHERE Thread_reply_ID = ?',
      [now,threadId]
    );
    
    // Update or create record in Admin_check_inappropriate_thread table
    const [existingCheck] = await connection.execute(
      'SELECT * FROM Admin_check_inappropriate_thread_reply WHERE Thread_reply_ID = ?',
      [threadId]
    );
    
    if (existingCheck.length > 0) {
      // Update existing record
      await connection.execute(
      `UPDATE Admin_check_inappropriate_thread_reply 
         SET Admin_ID = ?, admin_action_taken = 'Banned', reason_for_taken = ?, admin_checked_at = ?
         WHERE Thread_reply_ID = ?`,
        [adminId, reason, now,threadId]
      );
    } else {
      // Create new record
      await connection.execute(
          `INSERT INTO Admin_check_inappropriate_thread_reply 
         (Thread_reply_ID, Admin_ID, admin_action_taken, reason_for_taken, admin_checked_at) 
         VALUES (?, ?, 'Banned', ?, ?)`,
        [threadId, adminId, reason,now]
      );
    }
    
    await connection.commit();
    connection.release();
    
    res.json({ success: true, message: 'Thread approved successfully' });
  } catch (error) {
    console.error(error);
    if (connection) await connection.rollback();
    res.status(500).json({ error: 'Failed to approve thread' });
  }
});
// POST /threads/reject
app.post('/threads-replied/AdminManual-check/reject', async (req, res) => {
  const { threadId, adminId, reason } = req.body;
  
  try {
    const connection = await db.promise().getConnection();
    const now = moment().tz("Asia/Bangkok").toDate(); // แปลงเป็น JS Date object
    await connection.beginTransaction();
    
    // Update thread status in Thread table
    await connection.execute(
      'UPDATE Thread_reply SET  created_at= ? , admin_decision = "Banned" WHERE Thread_reply_ID = ?',
      [now,threadId]
    );
    
    // Update or create record in Admin_check_inappropriate_thread table
    const [existingCheck] = await connection.execute(
      'SELECT * FROM Admin_check_inappropriate_thread_reply WHERE Thread_reply_ID = ?',
      [threadId]
    );
    
 
      // Create new record
      await connection.execute(
          `INSERT INTO Admin_check_inappropriate_thread_reply 
         (Thread_reply_ID, Admin_ID, admin_action_taken, reason_for_taken, admin_checked_at) 
         VALUES (?, ?, 'Banned', ?, ?)`,
        [threadId, adminId, reason,now]
      );
    
    
    await connection.commit();
    connection.release();
    
    res.json({ success: true, message: 'Thread approved successfully' });
  } catch (error) {
    console.error(error);
    if (connection) await connection.rollback();
    res.status(500).json({ error: 'Failed to approve thread' });
  }
});

// API สำหรับดึงประวัติการตรวจสอบ threads ของ admin
app.get('/api/admin_thread_history/:adminId', async (req, res) => {
  const adminId = req.params.adminId;

  try {
    const [rows] = await db.promise().execute(`
      SELECT 
        t.Thread_ID,
        t.message as thread_message,
        t.ai_evaluation,
        t.Total_likes ,
        t.admin_decision,

        -- การตรวจสอบของ admin
        act.admin_action_taken,
        act.admin_checked_at,
        act.reason_for_taken,

        -- เจ้าของ thread
        u.User_ID as thread_author_id,
        u.username as thread_author_username,
        u.fullname as thread_author_fullname,
        u.email as thread_author_email,
        upp.picture_url as thread_author_picture,

        -- แอดมินผู้แบน
        admin_user.User_ID as admin_id,
        admin_user.username as admin_username,
        admin_user.fullname as admin_fullname,
        admin_pp.picture_url as admin_picture

      FROM Admin_check_inappropriate_thread act
      JOIN Thread t 
           ON act.Thread_ID = t.Thread_ID
      JOIN User u 
           ON t.User_ID = u.User_ID
      LEFT JOIN user_Profile_Picture upp 
           ON u.User_ID = upp.User_ID AND upp.is_active = 1
      JOIN User admin_user 
           ON act.Admin_ID = admin_user.User_ID
      LEFT JOIN user_Profile_Picture admin_pp
           ON admin_user.User_ID = admin_pp.User_ID AND admin_pp.is_active = 1
      WHERE act.Admin_ID = ?
      ORDER BY act.admin_checked_at DESC
    `, [adminId]);

    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});


// API สำหรับดึง replies ที่ admin จัดการ พร้อมข้อมูลครบ
app.get('/api/my_admin_thread_replies/:adminId', async (req, res) => {
  const adminId = req.params.adminId;

  try {
    const [rows] = await db.promise().execute(`
      SELECT 
        tr.Thread_reply_ID,
        tr.Thread_ID,
        tr.message as reply_message,
        tr.created_at as reply_created_at,
        tr.total_Likes as reply_total_Likes,
        tr.ai_evaluation as reply_ai_evaluation,
        tr.admin_decision as reply_admin_decision,

        -- author of reply
        u.User_ID as reply_author_id,
        u.username as reply_author_username,
        u.email as reply_author_email,
        u.fullname as reply_author_fullname,
        upp.picture_url as reply_author_picture,

        -- info of parent thread
        t.Thread_ID as thread_id,
        t.message as thread_message,
        t.created_at as thread_created_at,
        t.admin_decision as thread_admin_decision,
        t.Total_likes as thread_total_like,
        thread_owner.User_ID as thread_author_id,
        thread_owner.username as thread_author_username,
        thread_owner.fullname as thread_author_fullname,
        thread_pp.picture_url as thread_author_picture,

        -- admin moderation info
        act.admin_action_taken,
        act.admin_checked_at,
        act.reason_for_taken,
        admin_user.User_ID as admin_id,
        admin_user.username as admin_username,
        admin_user.fullname as admin_fullname,
        admin_pp.picture_url as admin_picture

      FROM Admin_check_inappropriate_thread_reply act
      JOIN Thread_reply tr 
           ON act.Thread_reply_ID = tr.Thread_reply_ID
      JOIN User u 
           ON tr.User_ID = u.User_ID
      LEFT JOIN user_Profile_Picture upp 
           ON u.User_ID = upp.User_ID AND upp.is_active = 1

      -- join parent thread
      JOIN Thread t 
           ON tr.Thread_ID = t.Thread_ID
      JOIN User thread_owner 
           ON t.User_ID = thread_owner.User_ID
      LEFT JOIN user_Profile_Picture thread_pp
           ON thread_owner.User_ID = thread_pp.User_ID AND thread_pp.is_active = 1

      -- admin info
      JOIN User admin_user 
           ON act.Admin_ID = admin_user.User_ID
      LEFT JOIN user_Profile_Picture admin_pp
           ON admin_user.User_ID = admin_pp.User_ID AND admin_pp.is_active = 1

      WHERE act.Admin_ID = ?
      ORDER BY act.admin_checked_at DESC
    `, [adminId]);

    // format output
    const formattedRows = rows.map(row => {
      const baseData = {
        Thread_reply_ID: row.Thread_reply_ID,
        Thread_ID: row.Thread_ID,
        reply_message: row.reply_message,
        reply_created_at: row.reply_created_at,
        reply_total_Likes: row.reply_total_Likes,
        reply_ai_evaluation: row.reply_ai_evaluation,
        reply_admin_decision: row.reply_admin_decision,

        reply_author_id: row.reply_author_id,
        reply_author_username: row.reply_author_username,
        reply_author_email: row.reply_author_email,
        reply_author_fullname: row.reply_author_fullname,
        reply_author_picture: row.reply_author_picture,

        thread_id: row.thread_id,
        thread_message: row.thread_message,
        thread_created_at: row.thread_created_at,
        thread_admin_decision: row.thread_admin_decision,
        thread_author_id: row.thread_author_id,
        thread_author_username: row.thread_author_username,
        thread_author_fullname: row.thread_author_fullname,
        thread_author_picture: row.thread_author_picture,
        thread_totallikes: row.thread_total_like
      };

      // เพิ่มข้อมูล admin ถ้า action มีค่า
      if (row.admin_action_taken) {
        return {
          ...baseData,
          admin_id: row.admin_id,
          admin_username: row.admin_username,
          admin_fullname: row.admin_fullname,
          admin_picture: row.admin_picture,
          admin_action_taken: (row.admin_action_taken === 'Safe') ? 'Posted' : row.admin_action_taken,
          admin_checked_at: row.admin_checked_at,
          reason_for_taken: row.reason_for_taken
        };
      }

      return baseData;
    });

    res.json(formattedRows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});



// Theads post history
app.get('/api/my_threads/:userId', async (req, res) => {
  const userId = req.params.userId;

  try {
    const [rows] = await db.promise().execute(`
  SELECT 
    t.Thread_ID,
    t.message,
    t.created_at,
    t.Total_likes,
    t.ai_evaluation,
    t.admin_decision,
    (SELECT COUNT(*) FROM Thread_reply WHERE Thread_ID = t.Thread_ID) as reply_count,
    u.username as author_username,
    u.email as author_email,
    upp.picture_url as author_picture,
    act.admin_action_taken,
    act.admin_checked_at,
    act.reason_for_taken,
    admin_user.username as admin_username
FROM Thread t
LEFT JOIN User u ON t.User_ID = u.User_ID
LEFT JOIN user_Profile_Picture upp ON u.User_ID = upp.User_ID AND upp.is_active = 1
LEFT JOIN (
    SELECT * FROM (
        SELECT *, ROW_NUMBER() OVER(PARTITION BY Thread_ID ORDER BY admin_checked_at DESC) as rn
        FROM Admin_check_inappropriate_thread
    ) tmp
    WHERE rn = 1
) act ON t.Thread_ID = act.Thread_ID
LEFT JOIN User admin_user ON act.Admin_ID = admin_user.User_ID
WHERE t.User_ID = ?
ORDER BY t.created_at DESC

    `, [userId]);

    // จัดรูปแบบข้อมูลให้ตรงกับ requirement
    const formattedRows = rows.map(row => {
      const baseData = {
        Thread_ID: row.Thread_ID,
        message: row.message,
        created_at: row.created_at,
        Total_likes: row.Total_likes,
        reply_count: row.reply_count,
        ai_evaluation: row.ai_evaluation,
        admin_decision: row.admin_decision,
        author_username: row.author_username,
        author_email: row.author_email,
        author_picture: row.author_picture
      };

      // ถ้าโพสต์ถูกแบน ให้เพิ่มข้อมูล admin
      if (row.admin_action_taken === 'Banned'|| row.admin_action_taken === 'Safe' )  {
        return {
          ...baseData,
          admin_username: row.admin_username,
          admin_action_taken: row.admin_action_taken,
          admin_checked_at: row.admin_checked_at,
          reason_for_taken: row.reason_for_taken
        };
      }

      return baseData;
    });

    res.json(formattedRows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  } 
});

// API สำหรับดึง replies ของผู้ใช้
app.get('/api/my_thread_replies/:userId', async (req, res) => {
  const userId = req.params.userId;

  try {
    const [rows] = await db.promise().execute(`
      SELECT 
        tr.Thread_reply_ID,
        tr.Thread_ID,
        tr.message as reply_message,
        tr.created_at as reply_created_at,
        tr.total_Likes as reply_total_Likes,
        tr.ai_evaluation as reply_ai_evaluation,
        tr.admin_decision as reply_admin_decision,

        -- author of reply
        u.username as reply_author_username,
        u.email as reply_author_email,
        upp.picture_url as reply_author_picture,

        -- info of parent thread
        t.message as thread_message,
        t.created_at as thread_created_at,
        t.admin_decision as thread_admin_decision,
        t.Total_likes  as thread_Total_likes,
        thread_owner.username as thread_author_username,
        thread_owner.fullname as thread_author_fullname,
        thread_pp.picture_url as thread_author_picture,

        -- admin moderation info for reply
        act.admin_action_taken,
        act.admin_checked_at,
        act.reason_for_taken,
        admin_user.username as admin_username

      FROM Thread_reply tr
      LEFT JOIN User u 
             ON tr.User_ID = u.User_ID
      LEFT JOIN user_Profile_Picture upp 
             ON u.User_ID = upp.User_ID AND upp.is_active = 1

      -- join parent Thread
      LEFT JOIN Thread t 
             ON tr.Thread_ID = t.Thread_ID
      LEFT JOIN User thread_owner 
             ON t.User_ID = thread_owner.User_ID
      LEFT JOIN user_Profile_Picture thread_pp
             ON thread_owner.User_ID = thread_pp.User_ID AND thread_pp.is_active = 1

      -- join admin moderation for reply
     LEFT JOIN (
    SELECT * FROM (
        SELECT *, ROW_NUMBER() OVER(PARTITION BY Thread_reply_ID ORDER BY admin_checked_at DESC) as rn
        FROM Admin_check_inappropriate_thread_reply
    ) tmp
    WHERE rn = 1
) act ON tr.Thread_reply_ID = act.Thread_reply_ID
      LEFT JOIN User admin_user 
             ON act.Admin_ID = admin_user.User_ID

      WHERE tr.User_ID = ?
      ORDER BY tr.created_at DESC
    `, [userId]);

    // format output
    const formattedRows = rows.map(row => {
      const baseData = {
        Thread_reply_ID: row.Thread_reply_ID,
        Thread_ID: row.Thread_ID,
        reply_message: row.reply_message,
        reply_created_at: row.reply_created_at,
        reply_total_Likes: row.reply_total_Likes,
        reply_ai_evaluation: row.reply_ai_evaluation,
        reply_admin_decision: row.reply_admin_decision,

        reply_author_username: row.reply_author_username,
        reply_author_email: row.reply_author_email,
        reply_author_picture: row.reply_author_picture,

        thread_message: row.thread_message,
        thread_created_at: row.thread_created_at,
        thread_admin_decision: row.thread_admin_decision,
        thread_total_like: row.thread_Total_likes,
        thread_author_username: row.thread_author_username,
        thread_author_fullname: row.thread_author_fullname,
        thread_author_picture: row.thread_author_picture
      };

  if (row.admin_action_taken === 'Banned' || row.admin_action_taken === 'Safe') {
  return {
    ...baseData,
    admin_username: row.admin_username,
    admin_action_taken: row.admin_action_taken,
    admin_checked_at: row.admin_checked_at,
    reason_for_taken: row.reason_for_taken
  };
}


      return baseData;
    });

    res.json(formattedRows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});





  // ✅ Start Server
  const PORT = process.env.PORT || 8080;
  app.listen(PORT, () => console.log(`🚀 API running on port ${PORT}`));