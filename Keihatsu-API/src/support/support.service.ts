import { Injectable, InternalServerErrorException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as nodemailer from 'nodemailer';
import { ReportBugDto } from './dto/report-bug.dto';

@Injectable()
export class SupportService {
  private transporter: nodemailer.Transporter;

  constructor(private configService: ConfigService) {
    this.transporter = nodemailer.createTransport({
      host: this.configService.get<string>('SMTP_HOST'),
      port: this.configService.get<number>('SMTP_PORT'),
      secure: this.configService.get<boolean>('SMTP_SECURE', true),
      auth: {
        user: this.configService.get<string>('SMTP_USER'),
        pass: this.configService.get<string>('SMTP_PASS'),
      },
    });
  }

  async reportBug(reportBugDto: ReportBugDto, userEmail?: string) {
    const { message } = reportBugDto;
    const recipient = 'grvt8hq@gmail.com';

    try {
      await this.transporter.sendMail({
        from: `"Keihatsu Support" <${this.configService.get<string>('SMTP_USER')}>`,
        to: recipient,
        subject: 'New Bug Report - Keihatsu',
        text: `Bug Report from: ${userEmail || 'Anonymous'}\n\nMessage:\n${message}`,
        html: `
          <h3>New Bug Report</h3>
          <p><strong>Reporter:</strong> ${userEmail || 'Anonymous'}</p>
          <p><strong>Message:</strong></p>
          <p style="white-space: pre-wrap;">${message}</p>
        `,
      });
      return { success: true, message: 'Bug report sent successfully' };
    } catch (error) {
      console.error('Error sending bug report email:', error);
      throw new InternalServerErrorException('Failed to send bug report');
    }
  }
}
