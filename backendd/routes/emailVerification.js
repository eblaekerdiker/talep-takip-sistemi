const express = require('express');
const router = express.Router();
const nodemailer = require('nodemailer');
require('dotenv').config(); // .env desteği

const verificationCodes = {}; // { email: code }

// Kod gönderme endpoint'i
router.post('/send-code', async (req, res) => {
  const { email } = req.body;
  console.log('Gelen email:', email);

  if (!email) {
    return res.status(400).json({ message: 'E-posta gerekli.' });
  }

  const code = Math.floor(100000 + Math.random() * 900000).toString();
  verificationCodes[email] = code;

  const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
      user: process.env.MAIL_USER,   // .env dosyasından
      pass: process.env.MAIL_PASS    // .env dosyasından
    }
  });

  const mailOptions = {
    from: process.env.MAIL_USER,
    to: email,
    subject: 'Doğrulama Kodunuz',
    text: `Doğrulama kodunuz: ${code}`
  };

  try {
    await transporter.sendMail(mailOptions);
    res.json({ status: 'success', message: 'Kod e-posta ile gönderildi.' });
  } catch (error) {
    console.error('Mail gönderme hatası:', error);
    res.status(500).json({ status: 'error', message: 'Sunucu hatası!' });
  }
});

// Kod doğrulama endpoint'i
router.post('/verify-code', (req, res) => {
  const { email, code } = req.body;

  if (verificationCodes[email] === code) {
    delete verificationCodes[email];
    return res.json({ status: 'success', message: 'E-posta doğrulandı.' });
  } else {
    return res.status(400).json({ status: 'error', message: 'Kod hatalı.' });
  }
});

module.exports = router;
