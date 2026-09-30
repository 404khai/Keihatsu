import { INestApplication } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';

export function createSwaggerDocument(app: INestApplication) {
  const configuration = new DocumentBuilder()
    .setTitle('Keihatsu API')
    .setDescription(
      'Browse all Keihatsu endpoints and their request schemas. ' +
        'Use POST /auth/login or POST /auth/google to obtain an accessToken, ' +
        'then paste the token into Authorize. Admin operations require an ADMIN account. ' +
        'Trying write operations changes real data in the connected API database.',
    )
    .setVersion('1.0')
    .addBearerAuth({ type: 'http', scheme: 'bearer', bearerFormat: 'JWT' })
    .build();

  return SwaggerModule.createDocument(app, configuration, {
    autoTagControllers: false,
  });
}

export function setupSwagger(app: INestApplication) {
  if (app.get(ConfigService).get<string>('SWAGGER_ENABLED') === 'false') return;

  SwaggerModule.setup('docs', app, () => createSwaggerDocument(app), {
    jsonDocumentUrl: 'docs-json',
    raw: ['json'],
    customSiteTitle: 'Keihatsu API documentation',
    swaggerOptions: {
      filter: true,
      docExpansion: 'none',
      tagsSorter: 'alpha',
      operationsSorter: 'alpha',
      displayRequestDuration: true,
    },
  });
}
