<div align="center">
  <img src="images/logo.jpg" alt="iA Logo" width="80" height="80" style="display: inline-block; margin-right: 20px; vertical-align: middle;" />
  <h1 style="display: inline-block; vertical-align: middle;">iA - AI Chat</h1>
</div>

A modern iOS chat application built with SwiftUI and The Composable Architecture that connects to [Google AI (Gemini)](https://ai.google.dev/) for lightning-fast AI-powered conversations with advanced reasoning capabilities.

## Preview

<div align="center">
  <img src="images/preview.png" alt="iA App Preview" width="280" />
</div>

## Features

- 💬 **Multiple Chat Conversations** - Create and manage multiple chat sessions
- 🚀 **Google AI (Gemini)** - Use Google's most powerful AI models
- 🧠 **Advanced Reasoning** - Access Gemini's advanced reasoning capabilities
- ⚙️ **Configurable Settings** - Customize model, temperature, and max tokens
- 🎯 **Model Selection** - Choose from latest Gemini models:
  - **Gemini 2.5 Flash** - Fast and efficient
  - **Gemini 2.5 Pro** - Advanced reasoning
  - **Gemini 3 Flash** - Frontier-class performance
  - **Gemini 3 Pro** - Most intelligent model
- 🔐 **Secure Authentication** - API key authentication with local device storage only
- 🎨 **Modern UI** - Clean, native SwiftUI interface with animated loading indicators
- 📱 **iOS Native** - Built for iOS 17.0+ with native SwiftUI components
- 🛑 **Stop Generation** - Stop ongoing AI responses
- 🌡️ **Advanced Parameters** - Fine-tune temperature and token limits
- 💾 **Chat History** - Persistent chat management and navigation

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+
- A [Google AI Studio](https://aistudio.google.com/apikey) API key (free at https://aistudio.google.com/apikey)

## Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/yourusername/iA.git
   cd iA
   ```

2. Open the project in Xcode:

   ```bash
   open iA.xcodeproj
   ```

3. Build and run the project in Xcode (⌘R)

The Swift Package Manager dependencies will be automatically resolved when you build the project.

## Setup

### Getting a Google AI API Key

1. Visit [https://aistudio.google.com/apikey](https://aistudio.google.com/apikey)
2. Sign in with your Google account (create one if needed)
3. Click "Create API Key"
4. Copy the generated key

### API Key Configuration

To configure your API key in the app:

1. **Launch the app** on your iOS device or simulator
2. **Tap the Settings icon** (⚙️) in the navigation bar
3. **Paste your API Key** in the Google AI section
4. **Select your preferred model**
5. **The key will be saved** securely in your device's UserDefaults

**Note:** Your API key is stored locally on your device and never uploaded to any server except Google's API servers.

### Configuring the App

1. Launch the app on your iOS device or simulator
2. Tap the Settings icon (⚙️) in the navigation bar
3. Configure your preferences:
   - **API Key**: Paste your Google AI API key
   - **Default Model**: Choose your preferred Gemini model
   - **Temperature**: Adjust response creativity (0.0 - 2.0, default: 0.7)
   - **Max Tokens**: Set maximum response length (default: 1024)
4. Create a new chat and start messaging

### Available Models

- **gemini-2.5-flash** - Fast and efficient (recommended for most tasks)
- **gemini-2.5-pro** - Advanced reasoning and analysis
- **gemini-3-flash** - Frontier-class performance
- **gemini-3-pro** - Most intelligent with advanced reasoning

See [Google AI Integration Guide](GOOGLE_AI_INTEGRATION.md) for more details on using Google AI.

## Usage

### Creating a New Chat

1. Tap the **+** button in the top-right corner
2. Select a model from the model picker
3. Start chatting!

### Managing Chats

- **Delete a chat**: Swipe left on any chat in the list and tap delete
- **Navigate to a chat**: Tap on any chat in the list
- **View settings**: Tap the gear icon (⚙️) in the top-left corner

### During a Conversation

- **Send a message**: Type your message and tap the send button (↑) or press return
- **Stop generation**: Tap the stop button (⏹) while a response is being generated
- **Multi-line input**: The input field automatically expands for longer messages

## Architecture

This project is built using **The Composable Architecture (TCA)**, a powerful state management library for Swift applications. The architecture promotes:

- **Predictable state management** - All state changes flow through reducers
- **Testability** - Easy to test business logic in isolation
- **Modularity** - Features are self-contained and composable
- **Type safety** - Leverages Swift's type system for safety

### Project Structure

```
iA/
├── Sources/
│   ├── Features/
│   │   ├── ChatFeature/           # Individual chat conversation with streaming
│   │   ├── ChatListFeature/       # List of all chats
│   │   ├── MessageFeature/        # Individual message display with reasoning
│   │   ├── MessageInputFeature/   # Message input component
│   │   └── SettingsFeature/       # App settings and API configuration
│   ├── Services/
│   │   ├── GroqService.swift      # Groq API client with streaming & web search
│   │   ├── GroqModels.swift       # API data models and types
│   │   └── UserDefaultsService.swift  # User preferences management
│   └── Components/
│       ├── ModelPicker.swift       # Model selection component
│       ├── LoadingIndicatorView.swift  # Animated loading indicator
│       ├── ReasoningView.swift    # Display reasoning from models
│       ├── WebSearchSourcesView.swift # Display web search results
│       └── NoChatsMessage.swift    # Empty state component
├── Environment.swift               # Dependency injection setup
└── App.swift                       # App entry point
```

### Key Features

- **GroqService**: Actor-based service for Groq API communication with:
  - Streaming and non-streaming chat completions
  - Automatic model selection for different capabilities (vision, reasoning, web search)
  - Web search integration via Groq's Compound models
  - Reasoning support for advanced models
  - Bearer token authentication
- **UserDefaultsService**: Manages user preferences including API key, model selection, temperature, and token limits

- **Feature Modules**: Each feature (Chat, ChatList, Settings, etc.) is self-contained following TCA patterns

- **Composable Architecture**: Uses TCA for predictable state management and testability

## Technologies

- **SwiftUI** - Modern declarative UI framework for iOS 17.0+
- **The Composable Architecture** - State management and architecture framework
- **Swift Concurrency** - Async/await for asynchronous operations and actor-based services
- **Groq API** - Lightning-fast AI inference with multiple model options
- **Web Search** - Built-in web search via Groq's Compound models

## Development

### Dependencies

The project uses Swift Package Manager with the following main dependencies:

- [swift-composable-architecture](https://github.com/pointfreeco/swift-composable-architecture) - TCA framework

### Building

```bash
# Build the project
xcodebuild -project iA.xcodeproj -scheme iA -sdk iphonesimulator

# Or simply build in Xcode (⌘B)
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Repository

This project is hosted at: [https://github.com/michaljach/iA-ios](https://github.com/michaljach/iA-ios)

## License

This project is open source and available under the [MIT License](LICENSE).

## Acknowledgments

- Built with [The Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture) by [Point-Free](https://www.pointfree.co/)
- Powered by [Groq](https://groq.com/) for lightning-fast AI inference
