const express = require('express');
const router = express.Router();
const multerConfig = require('../middleware/multerConfig');

router.post('/single', multerConfig.single('dosya'), (req, res) => {
  console.log(req)
  if (!req.file) {
    return res.status(400).json({ error: 'Dosya yüklenemedi.' });
  }

  global.latestUploadedFilePath = req.file.path;

  return res.status(200).json({
    message: 'Dosya başarıyla yüklendi.',
    path: req.file.path
  });
});

module.exports = router;
