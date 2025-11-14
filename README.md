# PGPT (Private GPT) iOS

A modern iOS chat application built with SwiftUI and The Composable Architecture that connects to [Ollama](https://ollama.ai/) for AI-powered conversations with web search capabilities.

## Features

- 💬 **Multiple Chat Conversations** - Create and manage multiple chat sessions
- 🚀 **Streaming Responses** - Real-time streaming of AI responses as they're generated
- 🔍 **Web Search Integration** - Built-in web search functionality powered by Ollama
- ⚙️ **Configurable Settings** - Customize Ollama endpoint, model, temperature, and max tokens
- 🎯 **Model Selection** - Choose from available Ollama models
- 🔐 **Authentication Support** - Secure API token authentication
- 🎨 **Modern UI** - Clean, native SwiftUI interface with animated loading indicators
- 📱 **iOS Native** - Built specifically for iOS 17.0+ with native SwiftUI components
- 🛑 **Stop Generation** - Ability to stop ongoing AI responses
- 🔄 **Chat Management** - Create, delete, and navigate between conversations
- 🌡️ **Advanced Parameters** - Control temperature and token limits for fine-tuned responses

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+
- An [Ollama](https://ollama.ai/) server running locally or remotely

## Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/yourusername/lama.git
   cd lama
   ```

2. Open the project in Xcode:

   ```bash
   open lama.xcodeproj
   ```

3. Build and run the project in Xcode (⌘R)

The Swift Package Manager dependencies will be automatically resolved when you build the project.

## Setup

### Using Ollama Cloud or Local Server

The app works with both Ollama's cloud service and local installations:

#### Option 1: Ollama Cloud (Default)

The app comes pre-configured to use Ollama's cloud service at `https://ollama.com` with authentication included. No additional setup is required!

#### Option 2: Local Ollama Server

To use a local Ollama installation:

1. **Install Ollama**:

   - Visit [ollama.ai](https://ollama.ai/) and download Ollama for your system
   - Follow the installation instructions for your platform

2. **Pull a Model**:

   ```bash
   ollama pull llama2
   # or
   ollama pull mistral
   # or any other model you prefer
   ```

3. **Start Ollama Server**:
   ```bash
   ollama serve
   ```

### Configuring the App

1. Launch the app on your iOS device or simulator
2. Tap the settings gear icon (⚙️) in the top-left corner
3. Configure your preferences:
   - **Ollama Endpoint**: Set to `https://ollama.com` (default) or your local server URL
   - **Default Model**: Choose your preferred model (default: `gpt-oss:120b`)
   - **Temperature**: Adjust response creativity (0.0 - 1.0, default: 0.7)
   - **Max Tokens**: Set maximum response length (default: 640)
   - **Web Search**: Enable/disable web search functionality (default: enabled)
4. Select your preferred model from the model picker when creating a new chat

**Note**: If running on a simulator with a local Ollama server, make sure your Ollama server is accessible from the simulator's network. You may need to use your Mac's IP address instead of `localhost`.

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
lama/
├── Sources/
│   ├── Features/
│   │   ├── ChatFeature/           # Individual chat conversation
│   │   ├── ChatListFeature/       # List of all chats
│   │   ├── MessageFeature/        # Individual message display
│   │   ├── MessageInputFeature/   # Message input component
│   │   └── SettingsFeature/       # App settings and configuration
│   ├── Services/
│   │   ├── OllamaService.swift    # Ollama API client with streaming support
│   │   ├── OllamaModels.swift     # Ollama data models and types
│   │   └── UserDefaultsService.swift  # User preferences management
│   └── Components/
│       ├── ModelPicker.swift       # Model selection component
│       ├── NoChatsMessage.swift    # Empty state component
│       └── LoadingIndicatorView.swift  # Animated loading indicator
├── Environment.swift               # Dependency injection setup
└── lamaApp.swift                   # App entry point
```

### Key Components

- **OllamaService**: Actor-based service for communicating with the Ollama API, supporting:
  - Streaming and non-streaming chat completions
  - Text generation with context preservation
  - Model listing and information retrieval
  - Web search integration via Ollama's web search API
  - Bearer token authentication for secure API access
- **UserDefaultsService**: Manages user preferences including endpoint, model selection, temperature, max tokens, and web search settings
- **Feature Modules**: Each feature (Chat, ChatList, Settings, etc.) contains its own reducer and view following TCA patterns
- **Dependency Injection**: Uses TCA's dependency system for testability and modularity

## Technologies

- **SwiftUI** - Modern declarative UI framework for iOS 17.0+
- **The Composable Architecture** - State management and architecture framework
- **Swift Concurrency** - Async/await for asynchronous operations and actor-based services
- **Ollama API** - AI model inference with support for both cloud and local servers
- **Ollama Web Search API** - Integrated web search capabilities

## Development

### Dependencies

The project uses Swift Package Manager with the following main dependencies:

- [swift-composable-architecture](https://github.com/pointfreeco/swift-composable-architecture) - TCA framework

### Building

```bash
# Build the project
xcodebuild -project lama.xcodeproj -scheme lama -sdk iphonesimulator

# Or simply build in Xcode (⌘B)
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Repository

This project is hosted at: [https://github.com/michaljach/lama-ios](https://github.com/michaljach/lama-ios)

## License

This project is open source and available under the [MIT License](LICENSE).

## Acknowledgments

- Built with [The Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture) by [Point-Free](https://www.pointfree.co/)
- Powered by [Ollama](https://ollama.ai/) for local AI inference
