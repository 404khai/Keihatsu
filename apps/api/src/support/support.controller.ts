import { Body, Controller, Post, UseGuards, Req } from '@nestjs/common';
import { SupportService } from './support.service';
import { ReportBugDto } from './dto/report-bug.dto';
import { OptionalJwtAuthGuard } from '../auth/guards/optional-jwt-auth.guard';

@Controller('support')
export class SupportController {
  constructor(private readonly supportService: SupportService) {}

  @Post('report-bug')
  @UseGuards(OptionalJwtAuthGuard)
  async reportBug(@Body() reportBugDto: ReportBugDto, @Req() req: any) {
    const userEmail = req.user?.email;
    return this.supportService.reportBug(reportBugDto, userEmail);
  }
}
