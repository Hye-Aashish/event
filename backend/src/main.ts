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
  app.useStaticAssets(path.resolve('D:\\event app\\app'), { prefix: '/app' });
  app.useStaticAssets(path.resolve('D:\\event app\\admin-panel'), { prefix: '/admin' });

  // Create uploads folder if missing
  const fs = require('fs');
  const uploadPath = path.resolve('D:\\event app\\backend\\uploads');
  if (!fs.existsSync(uploadPath)) fs.mkdirSync(uploadPath);
  app.useStaticAssets(uploadPath, { prefix: '/uploads' });

  app.useGlobalPipes(new ValidationPipe({ transform: true }));
  app.setGlobalPrefix('api');

  const port = process.env.PORT || 3000;
  await app.listen(port);

  console.log('\n🚀 Navratri Event System running!\n');
  console.log('📱 User App    → http://localhost:' + port + '/app/index.html');
  console.log('🖥️  Admin Panel → http://localhost:' + port + '/admin/index.html');
  console.log('🔌 API          → http://localhost:' + port + '/api\n');
}
bootstrap();
