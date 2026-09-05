import { PrismaClient, Role } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { Pool } from 'pg';
import * as bcrypt from 'bcrypt';
import * as dotenv from 'dotenv';

dotenv.config();

const connectionString = `${process.env.DATABASE_URL}`;
const pool = new Pool({ connectionString });
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

async function main() {
  const email = process.argv[2];
  const password = process.argv[3];

  if (!email || !password) {
    console.error('Usage: npm run set-admin-password <email> <password>');
    process.exit(1);
  }

  try {
    // 1. Check if user exists
    const user = await prisma.user.findUnique({ where: { email } });
    
    if (!user) {
      console.error(`User with email ${email} not found.`);
      process.exit(1);
    }

    // 2. Ensure user is ADMIN
    if (user.role !== Role.ADMIN) {
      console.error(`User ${email} is not an ADMIN. Please promote them first using 'npm run promote ${email}'.`);
      process.exit(1);
    }

    // 3. Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // 4. Update user
    await prisma.user.update({
      where: { email },
      data: { password: hashedPassword },
    });

    console.log(`Password set successfully for admin user ${email}.`);
  } catch (error) {
    console.error('Error setting password:', error);
  } finally {
    await prisma.$disconnect();
    await pool.end();
  }
}

main();
