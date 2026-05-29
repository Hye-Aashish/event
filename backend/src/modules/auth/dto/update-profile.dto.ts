import { IsString, IsEmail, IsOptional, IsEnum } from 'class-validator';

export class UpdateProfileDto {
  @IsOptional()
  @IsString()
  name?: string;

  @IsOptional()
  @IsEmail()
  email?: string;

  @IsOptional()
  @IsString()
  @IsEnum(['user', 'scanner'])
  role?: string;
}
