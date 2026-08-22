import { IsNotEmpty, IsString, MaxLength } from 'class-validator';

export class ReportBugDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(2000)
  message: string;
}
