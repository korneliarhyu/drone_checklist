import { 
    Injectable,
    OnModuleInit,
    OnModuleDestroy, 
} from '@nestjs/common';
// Connecting the prisma with PostgreSQL adapter
import { PrismaPg } from '@prisma/adapter-pg';
// Generating query builder for PostgreSQL
import { PrismaClient } from '../generated/prisma/client.js';

@Injectable()
export class PrismaService
  extends PrismaClient
  implements OnModuleInit, OnModuleDestroy
{  constructor() {
        const connectionString = process.env.DATABASE_URL;

        if (!connectionString) {
            throw new Error('DATABASE_URL environment variable is not set.');
        }

        const adapter = new PrismaPg({ connectionString });
        super({ adapter });
    }

    // Connect to the database when the module is initialized
    async onModuleInit() {
        await this.$connect();
        console.log('Database Connected.');
    }

    // Disconnect from the database when the application is shutting down
    async onModuleDestroy() {
        await this.$disconnect();
        console.log('Database Disconnected.');
    }
}
