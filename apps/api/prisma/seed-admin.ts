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
  const email = process.env.ADMIN_EMAIL || 'grvt8hq@gmail.com';
  // Use env var or default. IMPORTANT: Set ADMIN_PASSWORD in Railway variables!
  const password = process.env.ADMIN_PASSWORD || 'adminKeih@tsu26'; 
  const username = process.env.ADMIN_USERNAME || 'Admin';

  console.log(`Checking for admin user: ${email}...`);

  const existingUser = await prisma.user.findUnique({
    where: { email },
  });

  if (existingUser) {
    console.log(`User ${email} already exists.`);
    
    // Promote if not admin
    if (existingUser.role !== Role.ADMIN) {
      console.log(`Promoting ${email} to ADMIN...`);
      await prisma.user.update({
        where: { email },
        data: { role: Role.ADMIN },
      });
      console.log('User promoted successfully.');
    } else {
      console.log('User is already an ADMIN.');
    }
    
    // If password is provided in ENV, update it (useful for recovery)
    if (process.env.ADMIN_PASSWORD) {
       console.log('Updating password from environment variable...');
       const hashedPassword = await bcrypt.hash(password, 10);
       await prisma.user.update({
         where: { email },
         data: { password: hashedPassword },
       });
       console.log('Password updated.');
    }

  } else {
    console.log(`Creating new admin user: ${email}...`);
    const hashedPassword = await bcrypt.hash(password, 10);

    // Create user
    // Note: We need a unique username. If 'Admin' is taken, we might fail or need logic.
    // For now, let's try to create.
    try {
      await prisma.user.create({
        data: {
          email,
          username,
          password: hashedPassword,
          role: Role.ADMIN,
          isOnboarded: true,
        },
      });
      console.log(`Admin user ${email} created successfully.`);
    } catch (e) {
      if (e.code === 'P2002') { // Unique constraint failed
         console.log('Username already taken, trying email handle...');
         await prisma.user.create({
            data: {
              email,
              username: email.split('@')[0], // fallback username
              password: hashedPassword,
              role: Role.ADMIN,
              isOnboarded: true,
            },
         });
         console.log(`Admin user ${email} created successfully with fallback username.`);
      } else {
        throw e;
      }
    }
  }
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
    await pool.end();
  });
