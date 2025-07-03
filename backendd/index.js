global.latestUploadedFilePath = null;


const express = require('express');
const cors = require('cors');
const path = require('path');
const apiRoutes = require('./routes/API');
const morgan = require('morgan');
const pool = require('./config/db');  
require('dotenv').config();


const swaggerJsdoc = require('swagger-jsdoc');
const swaggerUi = require('swagger-ui-express')

const sifreRoutes = require('./routes/passwordReset');
const uploadRoutes = require('./routes/upload');  //  YENİ EKLEDİK

const app = express();
const port = 3000;




// Middleware
app.use(morgan('dev'));
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, 'proje')));
app.use(express.static(path.join(__dirname, 'form')));
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));


// Route Kayıtları
app.use('/api', sifreRoutes);
app.use('/api', apiRoutes);
app.use('/api', uploadRoutes);

// Swagger ayarları
const swaggerOptions = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'Talep Şikayet API',
      version: '1.0.0',
      description: 'Talep Şikayet uygulaması API dökümantasyonu',
    },
    servers: [
      {
        url: `http://localhost:${port}`,
      },
    ],
  },
  apis: [path.join(__dirname, 'routes/*.js')],
};

console.log(' DEBUG Swagger apis path:', path.join(__dirname, 'routes/*.js'));

const swaggerSpec = swaggerJsdoc(swaggerOptions);
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));

app.get('/', (req, res) => {
  res.status(200).send({ message: 'Merhaba, bu bir Node.js uygulamasıdır!' });
});

// Hata yakalayıcı
app.use((err, req, res, next) => {
  console.error("HATA:", err.stack);
  res.status(500).json({ status: 'error', message: 'Sunucu hatası!' });
});

// Sunucuyu başlat
app.listen(port, () => {
  console.log(`Sunucu http://localhost:${port} üzerinde çalışıyor`);
});



//Bu dosya Node.js uygulamasının giriş noktasıdır.

//Temel middleware’ler kurulmuş, statik dosyalar servis ediliyor.

//Swagger ile otomatik API dökümantasyonu hazırlanmış.

//API rotaları /api altında kullanıma açılmış.

//Hatalar merkezi bir yerde yakalanıp yönetiliyor.

//Sunucu 3000 portunda başlatılıyor.