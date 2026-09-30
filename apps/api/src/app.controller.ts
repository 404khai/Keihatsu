import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { Controller, Get } from '@nestjs/common';
import { AppService } from './app.service';

@ApiTags('Service')
@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Get()
  @ApiOperation({ summary: 'Get service greeting' })
  getHello(): string {
    return this.appService.getHello();
  }
}
