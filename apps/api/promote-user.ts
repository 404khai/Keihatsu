import { PrismaClient, Role } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { Pool } from 'pg';
import * as dotenv from 'dotenv';

dotenv.config();

const connectionString = `${process.env.DATABASE_URL}`;
const pool = new Pool({ connectionString });
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

async function main() {
  const email = process.argv[2];

  if (!email) {
    console.error('Please provide an email address: npm run promote <email>');
    process.exit(1);
  }

  try {
    const user = await prisma.user.update({
      where: { email },
      data: { role: Role.ADMIN },
    });
    console.log(`User ${user.email} promoted to ADMIN successfully.`);
  } catch (error) {
    console.error('Error promoting user:', error.message);
  } finally {
    await prisma.$disconnect();
    await pool.end();
  }
}

main();
