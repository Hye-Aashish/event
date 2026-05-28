import * as dns from 'dns';
dns.setServers(['8.8.8.8', '8.8.4.4', '1.1.1.1']);

import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ValidationPipe } from '@nestjs/common';
import { NestExpressApplication } from '@nestjs/platform-express';
import * as path from 'path';

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);
  
  app.enableCors({ origin: '*' });

  // Serve static files BEFORE setting global prefix
  app.useStaticAssets(path.join(process.cwd(), '..', 'app'), { prefix: '/app' });
  app.useStaticAssets(path.join(process.cwd(), '..', 'admin-panel'), { prefix: '/admin' });

  // Create uploads folder if missing
  const fs = require('fs');
  const uploadPath = path.join(process.cwd(), 'uploads');
  if (!fs.existsSync(uploadPath)) fs.mkdirSync(uploadPath, { recursive: true });
  app.useStaticAssets(uploadPath, { prefix: '/uploads' });

  const port = process.env.PORT || 3000;
  
  // Increase body limits for large image uploads
  const express = require('express');
  app.use(express.json({ limit: '50mb' }));
  app.use(express.urlencoded({ limit: '50mb', extended: true }));

  app.useGlobalPipes(new ValidationPipe({ transform: true }));
  app.setGlobalPrefix('api');

  await app.listen(port);

  console.log('\n🚀 Navratri Event System running!\n');
  console.log('📱 User App    → http://localhost:' + port + '/app/index.html');
  console.log('🖥️  Admin Panel → http://localhost:' + port + '/admin/index.html');
  console.log('🔌 API          → http://localhost:' + port + '/api\n');
}
bootstrap();
