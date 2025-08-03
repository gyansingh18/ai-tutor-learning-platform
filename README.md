# AI Tutor App

A comprehensive AI-powered tutoring application built with Ruby on Rails that provides personalized learning experiences for students across different grades and subjects.

## 🚀 Features

### For Students
- **Ask AI Doubts**: Get instant answers to questions in any subject
- **Chapter-wise Learning**: AI-generated explanations for each chapter
- **Progress Tracking**: View your learning history and progress
- **Grade → Subject → Chapter Navigation**: Easy navigation through curriculum
- **Personalized Experience**: Tailored responses based on your grade level

### For Admins
- **PDF Upload**: Upload school textbooks for RAG (Retrieval-Augmented Generation)
- **Content Management**: Manage grades, subjects, and chapters
- **User Management**: Monitor student activity and progress
- **Analytics Dashboard**: View usage statistics and insights

## 🏗️ Architecture

### Tech Stack
- **Backend**: Ruby on Rails 7.1
- **Database**: PostgreSQL with PgVector for vector storage
- **Authentication**: Devise
- **AI Integration**: OpenAI GPT-3.5-turbo + text-embedding-3-small
- **File Storage**: Active Storage (local/S3)
- **Background Jobs**: Sidekiq
- **Frontend**: Bootstrap 5 + Hotwire

### Key Components
- **RAG System**: PDF text extraction → Vector embeddings → Similarity search → AI answers
- **Role-based Access**: Admin-only PDF upload, student question asking
- **Real-time Processing**: Background job processing for PDF analysis

## 🛠️ Setup Instructions

### Prerequisites
- Ruby 3.3.5
- PostgreSQL 14+
- Redis (for background jobs)
- OpenAI API key

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd ai_tutor_g
   ```

2. **Install dependencies**
   ```bash
   bundle install
   ```

3. **Set up environment variables**
   ```bash
   cp config/env.example .env
   ```

   Edit `.env` and add your OpenAI API key:
   ```
   OPENAI_API_KEY=your_openai_api_key_here
   ```

4. **Set up database**
   ```bash
   # Start PostgreSQL
   brew services start postgresql@14

   # Create databases
   createdb ai_tutor_g_development
   createdb ai_tutor_g_test

   # Run migrations
   rails db:migrate

   # Seed the database
   rails db:seed
   ```

5. **Start Redis** (for background jobs)
   ```bash
   brew services start redis
   ```

6. **Start the application**
   ```bash
   rails server
   ```

7. **Start Sidekiq** (in a new terminal)
   ```bash
   bundle exec sidekiq
   ```

### Default Users

After running seeds, you'll have these default users:

- **Admin**: `admin@aitutor.com` / `password123`
- **Student**: `student@aitutor.com` / `password123`

## 📚 Usage

### For Students
1. Log in with student credentials
2. Select your Grade → Subject → Chapter
3. Ask questions and get AI-powered answers
4. View your learning history

### For Admins
1. Log in with admin credentials
2. Upload PDF textbooks for specific chapters
3. Monitor student activity in the dashboard
4. Manage content and users

## 🔧 Configuration

### OpenAI API
- Get your API key from [OpenAI Platform](https://platform.openai.com/)
- Add it to your `.env` file
- The app uses GPT-3.5-turbo for answers and text-embedding-3-small for embeddings

### File Storage
- Development: Local storage
- Production: Configure S3 in `config/storage.yml`

### Database
- Development: PostgreSQL with PgVector
- Production: Configure your production database URL

## 🧠 How RAG Works

1. **PDF Upload**: Admin uploads textbook PDF
2. **Text Extraction**: PDF text is extracted and cleaned
3. **Chunking**: Text is split into manageable chunks
4. **Embedding**: Each chunk is converted to vector embeddings
5. **Storage**: Embeddings stored in PostgreSQL with PgVector
6. **Query**: Student asks question
7. **Similarity Search**: Question embedding compared to stored chunks
8. **Answer Generation**: Relevant chunks + question sent to GPT for answer

## 📁 Project Structure

```
app/
├── controllers/          # MVC controllers
├── models/              # ActiveRecord models
├── services/            # Business logic services
│   ├── openai_service.rb
│   ├── pdf_processor_service.rb
│   └── rag_service.rb
├── jobs/                # Background jobs
└── views/               # ERB templates

config/
├── routes.rb            # Application routes
├── database.yml         # Database configuration
└── env.example          # Environment variables template
```

## 🚀 Deployment

### Heroku
1. Create Heroku app
2. Add PostgreSQL addon
3. Add Redis addon
4. Set environment variables
5. Deploy with `git push heroku main`

### Docker
1. Build image: `docker build -t ai-tutor .`
2. Run container: `docker run -p 3000:3000 ai-tutor`

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License.

## 🆘 Support

For support, please open an issue on GitHub or contact the development team.

---

**Note**: Make sure to add your OpenAI API key to the `.env` file before running the application. The app requires an active internet connection for AI functionality.
