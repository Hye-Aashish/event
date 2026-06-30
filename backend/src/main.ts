import * as dns from 'dns';
dns.setServers(['8.8.8.8', '8.8.4.4', '1.1.1.1']);

import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ValidationPipe } from '@nestjs/common';
import { NestExpressApplication } from '@nestjs/platform-express';
import * as path from 'path';

async function bootstrap() {
  // ── Startup: Enforce required environment variables ─────────────────────
  const requiredEnv = ['JWT_SECRET', 'MONGODB_URI', 'QR_SECRET'];
  for (const key of requiredEnv) {
    if (!process.env[key]) {
      console.error(`\n❌ FATAL: Missing required environment variable: ${key}\n`);
      process.exit(1);
    }
  }

  const app = await NestFactory.create<NestExpressApplication>(AppModule);

  // ── CORS: Restrict to known origins only ────────────────────────────────
  const allowedOrigins = [
    'http://localhost:3000',
    'http://localhost:5173',
    'http://127.0.0.1:3000',
    'http://127.0.0.1:5173',
    'https://navratri-app-backend.onrender.com',
  ];
  app.enableCors({
    origin: (origin, callback) => {
      // Allow requests with no origin (mobile apps, Postman, server-to-server)
      if (!origin || allowedOrigins.includes(origin)) {
        callback(null, true);
      } else {
        callback(new Error('Not allowed by CORS'));
      }
    },
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    credentials: true,
  });

  // ── Security Headers via Helmet ─────────────────────────────────────────
  // eslint-disable-next-line @typescript-eslint/no-require-imports
  const helmet = require('helmet');
  app.use(helmet({
    contentSecurityPolicy: false, // Disabled to allow CDNs (like Chart.js) and inline assets in local development
    crossOriginResourcePolicy: { policy: 'cross-origin' }
  }));

  // Serve static files BEFORE setting global prefix if they exist
  // eslint-disable-next-line @typescript-eslint/no-require-imports
  const fs = require('fs');
  const appPath = path.join(process.cwd(), '..', 'app');
  if (fs.existsSync(appPath)) {
    app.useStaticAssets(appPath, { prefix: '/app' });
  }

  const adminPath = path.join(process.cwd(), '..', 'admin-panel');
  if (fs.existsSync(adminPath)) {
    app.useStaticAssets(adminPath, { prefix: '/admin' });
  }

  // Create uploads folder if missing
  const uploadPath = path.join(process.cwd(), 'uploads');
  if (!fs.existsSync(uploadPath)) fs.mkdirSync(uploadPath, { recursive: true });
  app.useStaticAssets(uploadPath, { prefix: '/uploads' });

  const port = process.env.PORT || 3000;
  
  // ── Body Limits ─────────────────────────────────────────────────────────
  // eslint-disable-next-line @typescript-eslint/no-require-imports
  const express = require('express');
  app.use(express.json({ limit: '10mb' }));
  app.use(express.urlencoded({ limit: '10mb', extended: true }));

  app.useGlobalPipes(new ValidationPipe({ transform: true, whitelist: true }));
  app.setGlobalPrefix('api');

  await app.listen(port);

  console.log('\n🚀 Navratri Event System running!\n');
  console.log('📱 User App    → http://localhost:' + port + '/app/index.html');
  console.log('🖥️  Admin Panel → http://localhost:' + port + '/admin/index.html');
  console.log('🔌 API          → http://localhost:' + port + '/api\n');
}
bootstrap();
