import { IsString, IsEmail, IsOptional } from 'class-validator';

export class UpdateProfileDto {
  @IsOptional()
  @IsString()
  name?: string;

  @IsOptional()
  @IsEmail()
  email?: string;
  // NOTE: role is intentionally excluded — use admin panel to change user roles
}
