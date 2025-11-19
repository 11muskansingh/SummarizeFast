# SummarizeFast 🚀

AI-powered document & image summarization with Google Gemini 2.5 Flash

## 📖 Description

Transform your PDFs, documents, and images into concise, intelligent summaries with AI technology. Upload, process, and get structured summaries in seconds with iterative refinement capabilities.

## ✨ Features

- 📄 **Multi-Format Support**: PDF, Word, images, text files, and more
- 🤖 **Gemini 2.5 Flash AI**: Latest Google AI model for intelligent summarization
- 📏 **Flexible Summary Sizes**: Short, Medium, or Long summaries
- 🔄 **Iterative Refinement**: Unlimited refinement loop with conversation context
- 📱 **Cross-Platform**: Android, iOS, and Web support
- 💾 **Multiple Export Formats**: PDF, Markdown, HTML
- 🎨 **Modern Dark UI**: Glassmorphism design with smooth animations

## 🛠️ Setup Instructions

### Prerequisites
- Flutter SDK (3.5.0 or higher)
- Dart SDK (3.5.0 or higher)
- Google AI API Key

### Installation

1. **Clone the repository**
```bash
git clone <repository-url>
cd summarize_fast
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Configure API Key**
   - Copy `.env.example` to `.env`
   - Get your API key from [Google AI Studio](https://aistudio.google.com/apikey)
   - Add your key to `.env`:
   ```
   GOOGLE_AI_API_KEY=your_actual_api_key_here
   ```

4. **Run the app**
```bash
flutter run
```

## 📁 Project Structure

```
lib/
├── models/          # Data models
├── services/        # API services (Gemini, File operations)
├── providers/       # Riverpod state management
├── screens/         # App screens
├── widgets/         # Reusable widgets
└── utils/           # Helper functions and constants
```

## 🔑 Getting Google AI API Key

1. Visit [Google AI Studio](https://aistudio.google.com/apikey)
2. Sign in with your Google account
3. Click "Create API Key"
4. Copy the generated key
5. Paste it in your `.env` file

**Note**: The API key has a free tier with generous limits for development.

## 🚀 Development

This project uses:
- **State Management**: Riverpod
- **AI Model**: Gemini 2.5 Flash
- **Architecture**: Clean Architecture with separation of concerns

## 📝 License

This project is for educational and demonstration purposes.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

---

Built with ❤️ using Flutter and Google Gemini AI
