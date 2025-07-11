const express = require('express');
const router = express.Router();
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const validator = require('validator');
const authenticateToken = require('../middleware/auth');
const upload = require('../middleware/multerConfig');  // multer ayarları
const pool = require('../config/db');
require('dotenv').config();



const SECRET_KEY = process.env.JWT_SECRET;

// Genel hata yanıtı fonksiyonu
const hataYaniti = (res, mesaj = "Sunucu hatası") => res.status(500).json({ status: "error", message: mesaj });

// Kayıt olma endpointi
router.post('/register', (req, res) => {
  const { kullanici_adi, sifre, eposta, tam_adi, telefon } = req.body;

  if (!kullanici_adi || !sifre || !eposta || !tam_adi) {
    return res.status(400).json({ status: "error", message: "Lütfen tüm zorunlu alanları doldurun." });
  }
  if (!validator.isEmail(eposta)) {
    return res.status(400).json({ status: "error", message: "Geçerli bir e-posta girin." });
  }
  const sifreRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[^\s]{8,}$/;
  if (!sifreRegex.test(sifre)) {
    return res.status(400).json({ status: "error", message: "Şifre en az 8 karakter, 1 büyük harf, 1 küçük harf ve 1 sayı içermeli. Boşluk içeremez." });
  }
  const kullaniciRegex = /^[a-zA-Z0-9]{4,}$/;
  if (!kullaniciRegex.test(kullanici_adi)) {
    return res.status(400).json({ status: "error", message: "Kullanıcı adı en az 4 karakter ve sadece harf/rakam içermeli." });
  }

  const kontrolQuery = "SELECT * FROM kullanici WHERE kullanici_adi = ? OR eposta = ?";
  pool.query(kontrolQuery, [kullanici_adi, eposta], (err, result) => {
    if (err) return hataYaniti(res, "Veritabanı hatası.");

    if (result.length > 0) {
      return res.status(409).json({ status: "error", message: "Bu kullanıcı adı veya e-posta zaten kayıtlı." });
    }

    bcrypt.hash(sifre, 10, (err, hash) => {
      if (err) return hataYaniti(res, "Şifre işlenemedi.");

      const kayitQuery = 'INSERT INTO kullanici (kullanici_adi, sifre_hash, eposta, tam_adi, telefon) VALUES (?, ?, ?, ?, ?)';
      pool.query(kayitQuery, [kullanici_adi, hash, eposta, tam_adi, telefon || null], (err) => {
        if (err) return hataYaniti(res, "Kayıt sırasında hata oluştu.");

        return res.json({ status: "success", message: "Kayıt başarılı!" });
      });
    });
  });
});

// Giriş endpointi
router.post('/login', (req, res) => {
  const { kullanici_adi, sifre } = req.body;

  if (!kullanici_adi || !sifre) {
    return res.status(400).json({ basarili: false, mesaj: "Kullanıcı adı ve şifre gereklidir." });
  }

  const sorgu = "SELECT * FROM kullanici WHERE kullanici_adi = ?";
  pool.query(sorgu, [kullanici_adi], (err, results) => {
    if (err) return hataYaniti(res);

    if (results.length === 0) {
      return res.json({ basarili: false, mesaj: "Kullanıcı bulunamadı." });
    }

    const user = results[0];
    bcrypt.compare(sifre, user.sifre_hash, (err, isMatch) => {
      if (err) return hataYaniti(res);

      if (isMatch) {
        const token = jwt.sign({ id: user.id, kullanici_adi: user.kullanici_adi }, SECRET_KEY, { expiresIn: '2h' });
        return res.status(200).json({ basarili: true, token, user: user, mesaj: "Giriş başarılı." });
      } else {
        return res.status(401).json({ basarili: false, mesaj: "Şifre yanlış." });
      }
    });
  });
});

// Kullanıcıları listele
router.get('/kullanici', (req, res) => {
  pool.query('SELECT * FROM kullanici', (err, results) => {
    if (err) return res.status(500).send(err);
    res.json(results);
  });
});

// Veri ekle (dosya yükleme dahil)

router.post('/veri-ekle', authenticateToken, upload.single('dosya'), (req, res) => {
  console.log('BODY:', req.body);
  console.log('FILE:', req.file);

  const {  basvuru_tipi, icerik, kullanici_id ,konu } = req.body;
 //const isim=
  if ( !basvuru_tipi || !icerik || !konu) {
    return res.status(400).json({ status: "error", message: "Lütfen tüm alanları doldurun." });
  }

  const dosya_yolu = req.file ? `http://localhost:3000/uploads/${req.file.filename}` : null;

  const ekleQuery = `
  INSERT INTO veriler 
  ( basvuru_tipi, icerik, kullanici_id, konu, adres, dosya_yolu)
  VALUES (?, ?, ?, ?, ?, ?)`;

  pool.query(
  ekleQuery,
  [ basvuru_tipi, icerik, kullanici_id, konu, 'adres', dosya_yolu],
  (err, result) => {
    if (err) {
      console.error('INSERT HATASI:', err);
      return hataYaniti(res, "Veri eklenemedi.");
    }


      return res.json({ 
        status: "success", 
        message: "Başvuru başarıyla kaydedildi.", 
        id: result.insertId,
        dosya_yolu
      });
    }
  );
});



// Tüm verileri listele
router.get('/veriler', (req, res) => {
  pool.query('SELECT * FROM veriler', (err, results) => {
    if (err) return res.status(500).json({ status: "error", message: "Veri çekilemedi" });
    res.json(results);
  });
});

// Başvuru durumu güncelle
// Flutter'dan gelen "tamamlandı" güncelleme isteği için
router.put('/veriler/:ID', (req, res) => {
  const id = req.params.id;
  const { basvuru_durumu } = req.body;  // ya da tamamlandi ise, onu burada yakala

  if (typeof basvuru_durumu === 'undefined') {
    return res.status(400).json({ status: "error", message: "basvuru_durumu alanı eksik" });
  }

  const query = 'UPDATE veriler SET basvuru_durumu = ? WHERE ID = ?';
  pool.query(query, [basvuru_durumu, id], (err, result) => {
    if (err) {
      console.error('Güncelleme hatası:', err);
      return res.status(500).json({ status: "error", message: "Güncelleme hatası" });
    }

    if (result.affectedRows === 0) {
      return res.status(404).json({ status: "error", message: "Kayıt bulunamadı" });
    }

    res.json({ status: "success", message: "Başarıyla güncellendi" });
  });
});


// Başvuru sil
router.delete('/veri-sil/:id', (req, res) => {
  const { id } = req.params;

  const query = 'DELETE FROM veriler WHERE ID = ?';
  pool.query(query, [id], (err) => {
    if (err) return res.status(500).json({ status: "error", message: "Silme hatası" });
    res.json({ status: "success", message: "Başvuru silindi" });
  });
});

module.exports = router;
