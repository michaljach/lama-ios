# LAMA iOS

A modern iOS chat application built with SwiftUI and The Composable Architecture that connects to [Ollama](https://ollama.ai/) for local AI-powered conversations.

## Features

- 💬 **Multiple Chat Conversations** - Create and manage multiple chat sessions
- 🚀 **Streaming Responses** - Real-time streaming of AI responses as they're generated
- ⚙️ **Configurable Ollama Endpoint** - Customize your Ollama server connection
- 🎯 **Model Selection** - Choose from available Ollama models
- 🎨 **Modern UI** - Clean, native SwiftUI interface
- 📱 **iOS Native** - Built specifically for iOS with native SwiftUI components
- 🛑 **Stop Generation** - Ability to stop ongoing AI responses
- 🔄 **Chat Management** - Create, delete, and navigate between conversations

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

### Installing Ollama

Before using the app, you need to have Ollama installed and running:

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
3. Configure your Ollama endpoint (default: `http://192.168.68.54:11434`)
4. Select your preferred model from the available models

**Note**: If running on a simulator, make sure your Ollama server is accessible from the simulator's network. You may need to use your Mac's IP address instead of `localhost`.

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
│   │   ├── ChatFeature/          # Individual chat conversation
│   │   ├── ChatListFeature/       # List of all chats
│   │   ├── MessageFeature/        # Individual message display
│   │   ├── MessageInputFeature/   # Message input component
│   │   └── SettingsFeature/       # App settings and configuration
│   ├── Services/
│   │   ├── OllamaService.swift    # Ollama API client
│   │   └── OllamaModels.swift     # Ollama data models
│   └── Components/
│       ├── ModelPicker.swift      # Model selection component
│       └── NoChatsMessage.swift   # Empty state component
├── Environment.swift              # Dependency injection setup
└── lamaApp.swift                  # App entry point
```

### Key Components

- **OllamaService**: Actor-based service for communicating with the Ollama API, supporting both streaming and non-streaming requests
- **Feature Modules**: Each feature (Chat, ChatList, Settings, etc.) contains its own reducer and view following TCA patterns
- **Dependency Injection**: Uses TCA's dependency system for testability

## Technologies

- **SwiftUI** - Modern declarative UI framework
- **The Composable Architecture** - State management and architecture framework
- **Swift Concurrency** - Async/await for asynchronous operations
- **Ollama API** - Local AI model inference

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

## License

This project is open source and available under the [MIT License](LICENSE).

## Acknowledgments

- Built with [The Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture) by [Point-Free](https://www.pointfree.co/)
- Powered by [Ollama](https://ollama.ai/) for local AI inference
