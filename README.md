# AI Tutor Learning Platform

A comprehensive AI-powered learning platform built with Ruby on Rails that provides personalized learning experiences with interactive tasks and progress tracking for students across different grades and subjects.

## 🚀 Features

### For Students
- **Interactive Learning Tasks**: AI-generated tasks with detailed concept explanations
- **Three-Panel Learning Interface**: Explanation panel, input panel, and results panel
- **Progress Tracking**: Visual progress bar showing completion percentage
- **Chapter-wise Learning**: AI-generated explanations for each chapter
- **Ask AI Doubts**: Get instant answers to questions in any subject
- **Grade → Subject → Chapter Navigation**: Easy navigation through curriculum
- **Personalized Experience**: Tailored responses based on your grade level

### For Admins
- **AI Task Generation**: Automatically create comprehensive learning tasks from chapter content
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
- **AI Task Generator**: Creates comprehensive learning tasks with explanations, questions, and answers
- **Three-Panel Learning Interface**: Modern UI with explanation, input, and results panels
- **Progress Tracking System**: Visual progress indicators and completion tracking
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
   git clone https://github.com/gyansingh18/ai-tutor-learning-platform.git
   cd ai-tutor-learning-platform
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
3. Access interactive learning tasks with three-panel interface:
   - **Left Panel**: Detailed concept explanations
   - **Middle Panel**: Input fields for answers
   - **Right Panel**: Results and feedback
4. Track your progress with the visual progress bar
5. Ask additional questions and get AI-powered answers
6. View your learning history

### For Admins
1. Log in with admin credentials
2. Upload PDF textbooks for specific chapters
3. Generate AI-powered learning tasks automatically
4. Monitor student activity and progress in the dashboard
5. Manage content and users

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

## 🧠 How AI Task Generation Works

1. **Content Analysis**: AI analyzes chapter content from uploaded PDFs
2. **Task Creation**: Generates 6-10 comprehensive learning tasks including:
   - Detailed concept explanations (2-3 paragraphs)
   - Progressive difficulty levels
   - Multiple question types (MCQ, fill-in-blank, true/false, etc.)
   - Correct answers with explanations
3. **Task Storage**: Tasks are stored in the database with student progress tracking
4. **Interactive Learning**: Students complete tasks through the three-panel interface
5. **Progress Tracking**: Visual progress bar shows completion percentage

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
│   ├── learning_controller.rb    # Learning tasks and progress
│   └── admin/           # Admin controllers
├── models/              # ActiveRecord models
│   ├── task.rb          # Learning tasks
│   ├── student_answer.rb # Student progress tracking
│   └── chapter.rb       # Chapter content
├── services/            # Business logic services
│   ├── task_generator_service.rb # AI task generation
│   ├── openai_service.rb
│   ├── pdf_processor_service.rb
│   └── rag_service.rb
├── helpers/             # View helpers
│   └── learning_helper.rb # Task content parsing
├── jobs/                # Background jobs
└── views/               # ERB templates
    └── learning/        # Learning interface views
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
