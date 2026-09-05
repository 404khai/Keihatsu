# Keihatsu API 🚀

A progressive and scalable manga aggregation backend built with **NestJS**, **Prisma**, and **PostgreSQL**. This API serves as the central hub for the Keihatsu ecosystem, handling content aggregation, user synchronization, and community features.

## 🌟 Features

- **Auth & Security**: Google OAuth 2.0 integration with JWT-based session management.
- **Manga Aggregator**: Extension-based architecture to fetch and scrape manga metadata from multiple sources using Puppeteer.
- **Library Sync**: Cross-device synchronization for manga libraries, custom categories, and reading history.
- **Social Features**: High-performance nested commenting system (up to 3 levels) with voting and attachments.
- **Media Management**: Automated image processing and hosting via Cloudinary integration.
- **Offline Support**: Robust background synchronization for reading status and bookmarks.
- **Support System**: Built-in bug reporting system with automated email notifications via SMTP.

## 🛠️ Tech Stack

- **Framework**: [NestJS](https://nestjs.com/)
- **Database**: [PostgreSQL](https://www.postgresql.org/) with [Prisma ORM](https://www.prisma.io/)
- **Storage**: [Cloudinary](https://cloudinary.com/) for user media
- **Email**: [Nodemailer](https://nodemailer.com/)
- **Scraping**: [Puppeteer Stealth](https://github.com/berstend/puppeteer-extra/tree/master/packages/puppeteer-extra-plugin-stealth)
- **Validation**: [Class-validator](https://github.com/typestack/class-validator) & [Class-transformer](https://github.com/typestack/class-transformer)

## 🚀 Getting Started

### Prerequisites

- Node.js (v18+)
- PostgreSQL instance
- Cloudinary Account
- Google Cloud Console Project (for OAuth)

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   npm install
   ```
3. Set up your environment variables:
   ```bash
   cp .env.example .env
   ```
   *Fill in your database credentials, JWT secret, Cloudinary keys, and SMTP settings.*

4. Run database migrations:
   ```bash
   npx prisma migrate dev
   ```

5. Start the server:
   ```bash
   # development
   npm run start:dev
   ```

## 📂 Project Structure

```text
src/
├── auth/           # OAuth and JWT Logic
├── users/          # Profile and Preference Management
├── sources/        # Manga Scraping Engines (Extensions)
├── library/        # User Collection Logic
├── comments/       # Community Interactions
├── history/        # Reading Progress Tracking
├── cloudinary/     # Media Upload Service
├── support/        # Bug Reporting & Help Desk
└── prisma/         # Database Schema & Service
```

## 🛡️ License

MIT License. See [LICENSE](LICENSE) for details.
