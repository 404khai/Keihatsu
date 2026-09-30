import { Module } from '@nestjs/common';
import { ServeStaticModule } from '@nestjs/serve-static';
import { join } from 'path';
import { ConfigModule } from '@nestjs/config';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { PrismaModule } from './prisma/prisma.module';
import { UsersModule } from './users/users.module';
import { AuthModule } from './auth/auth.module';
import { SourcesModule } from './sources/sources.module';

import { CommentsModule } from './comments/comments.module';
import { LibraryModule } from './library/library.module';
import { CategoriesModule } from './categories/categories.module';
import { CloudinaryModule } from './cloudinary/cloudinary.module';
import { DownloadsModule } from './downloads/downloads.module';
import { HistoryModule } from './history/history.module';
import { SupportModule } from './support/support.module';
import { AdminModule } from './admin/admin.module';
import { NotificationsModule } from './notifications/notifications.module';
import { ThrottlerModule } from '@nestjs/throttler';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
    }),
    ThrottlerModule.forRoot([{ ttl: 60000, limit: 30 }]),
    ServeStaticModule.forRoot(
      {
        rootPath: join(process.cwd(), 'src', 'images'),
        serveRoot: '/images',
      },
      {
        rootPath: join(process.cwd(), 'uploads'),
        serveRoot: '/uploads',
      },
    ),
    // PrismaModule,
    UsersModule,
    AuthModule,
    PrismaModule,
    CommentsModule,
    SourcesModule,
    LibraryModule,
    CategoriesModule,
    CloudinaryModule,
    DownloadsModule,
    HistoryModule,
    SupportModule,
    AdminModule,
    NotificationsModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
