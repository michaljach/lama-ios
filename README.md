# iA - AI Chat

A modern iOS chat application built with SwiftUI and The Composable Architecture that connects to [Groq API](https://console.groq.com/) for lightning-fast AI-powered conversations with web search and reasoning capabilities.

## Features

- 💬 **Multiple Chat Conversations** - Create and manage multiple chat sessions
- 🚀 **Real-time Streaming** - Lightning-fast streaming responses from Groq models
- 🧠 **AI Reasoning** - Support for models with advanced reasoning capabilities (GPT-OSS, Qwen 3)
- 🔍 **Web Search Integration** - Built-in web search using Groq's Compound models for current information
- 🖼️ **Vision Support** - Analyze and discuss images using vision-capable models
- ⚙️ **Configurable Settings** - Customize model, temperature, top-p, and max tokens
- 🎯 **Model Selection** - Choose from a variety of Groq models including:
  - Mixtral-8x7b (fast and efficient)
  - Qwen models with reasoning capabilities
  - GPT-OSS models with advanced reasoning
  - Llama models for vision tasks
- 🔐 **Secure Authentication** - Groq API key authentication
- 🎨 **Modern UI** - Clean, native SwiftUI interface with animated loading indicators
- 📱 **iOS Native** - Built for iOS 17.0+ with native SwiftUI components
- 🛑 **Stop Generation** - Stop ongoing AI responses
- 🌡️ **Advanced Parameters** - Fine-tune temperature, top-p, and token limits
- 💾 **Chat History** - Persistent chat management and navigation

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+
- A [Groq API](https://console.groq.com/) key (get one free at https://console.groq.com/)

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

### Getting a Groq API Key

1. Visit [https://console.groq.com/](https://console.groq.com/)
2. Sign up for a free account
3. Navigate to the API Keys section
4. Create a new API key and copy it

### API Key Configuration

To keep your Groq API key secure and prevent it from being committed to the repository:

1. **Edit the Settings in the app:**

   - Launch the app
   - Tap the Settings icon (⚙️) in the navigation bar
   - Paste your Groq API key in the "API Key" field
   - The key will be saved securely in your device's UserDefaults

**Note:** Your API key is stored locally on your device and never uploaded to any server except Groq's API servers.

### Configuring the App

1. Launch the app on your iOS device or simulator
2. Tap the Settings icon (⚙️) in the navigation bar
3. Configure your preferences:
   - **API Key**: Enter your Groq API key
   - **Default Model**: Choose your preferred model
   - **Temperature**: Adjust response creativity (0.0 - 2.0, default: 0.7)
   - **Max Tokens**: Set maximum response length (default: 1024)
4. Select your preferred model from the model picker when creating a new chat

### Available Models

The app supports various Groq models:

- **Mixtral-8x7b-32768** - Fast, general-purpose model (default)
- **Llama-3.1-70b** - Powerful reasoning and analysis
- **Gemma-7b** - Lightweight and efficient
- **Meta-Llama-Scout-17b** - Vision capabilities for image analysis
- **Qwen/Qwen3-32B** - Advanced reasoning and multilingual support
- **Mistral-8x7b** - Efficient and fast
- **GPT-OSS models** - Advanced reasoning capabilities

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
