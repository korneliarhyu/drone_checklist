import { Module } from '@nestjs/common';
import { PrismaService } from './prisma.service.js';

@Module({
  providers: [PrismaService],
  // Make this services can be used for other modules
  exports: [PrismaService], 
})
export class PrismaModule {}
