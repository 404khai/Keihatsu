import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { AppModule } from './app.module';
import { NestExpressApplication } from '@nestjs/platform-express';
import { join } from 'path';
import { setupSwagger } from './swagger';

async function bootstrap() {
  if (process.env.NODE_ENV === 'production' &&
      (!process.env.JWT_SECRET || process.env.JWT_SECRET.length < 32)) {
    throw new Error('Production requires JWT_SECRET with at least 32 characters');
  }
  const app = await NestFactory.create<NestExpressApplication>(AppModule);
  // Exactly one trusted reverse proxy sits in front of the container.
  if (process.env.NODE_ENV === 'production') app.set('trust proxy', 1);
  app.enableShutdownHooks();
  const origins = (process.env.CORS_ORIGINS || '').split(',').map(s => s.trim()).filter(Boolean);
  if (origins.length) app.enableCors({ origin: origins });
  app.useGlobalPipes(new ValidationPipe({ whitelist: true }));
  setupSwagger(app);

  // Serve static files from the uploads directory
  app.useStaticAssets(join(__dirname, '..', 'uploads'), {
    prefix: '/uploads/',
  });

  const port = process.env.PORT ? Number(process.env.PORT) : 3000;
  await app.listen(port, '0.0.0.0');
}
bootstrap();
