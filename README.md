<div align="center">
  <img src="images/logo.jpg" alt="iA Logo" width="80" height="80" style="display: inline-block; margin-right: 20px; vertical-align: middle;" />
  <h1 style="display: inline-block; vertical-align: middle;">iA - AI Chat</h1>
</div>

A modern iOS chat application built with SwiftUI and The Composable Architecture that connects to [Google AI (Gemini)](https://ai.google.dev/) for AI-powered conversations with multimodal capabilities.

## Preview

<div align="center">
  <img src="images/preview.png" alt="iA App Preview" width="280" />
</div>

## Features

- 💬 **Multiple Chat Conversations** - Create and manage multiple chat sessions
- 🚀 **Google AI (Gemini)** - Powered by Google's Gemini models
- 🖼️ **Multimodal Support** - Send images along with text for vision-enabled models
- 🌐 **Web Search** - Optional grounding with Google Search for real-time information
- ⚡ **Real-time Streaming** - Token-by-token response streaming for instant feedback
- 🎯 **Model Selection** - Choose from latest Gemini models with friendly display names
- 🔗 **Source Citations** - View web sources with automatic URL resolution
- 🔐 **Secure Storage** - API key stored securely on device
- 🎨 **Modern UI** - Clean, native SwiftUI interface
- 📱 **iOS Native** - Built for iOS 17.0+
- ⚙️ **Configurable Settings** - Customize model, temperature, and token limits

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+
- A [Google AI Studio](https://aistudio.google.com/apikey) API key (free)

## Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/michaljach/lama-ios.git
   cd lama-ios
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
2. Sign in with your Google account
3. Click "Create API Key"
4. Copy the generated key

### API Key Configuration

1. Launch the app on your iOS device or simulator
2. Tap the Settings icon (⚙️)
3. Paste your API Key in the Google AI section
4. Select your preferred model
5. Configure optional settings (temperature, max tokens, web search)

**Note:** Your API key is stored locally on your device and only sent to Google's API servers.

## Usage

### Creating a New Chat

1. Tap the **+** button in the top-right corner
2. Select a model from the model picker
3. Start chatting!

### Sending Messages with Images

1. In a chat, tap the **+** button next to the input field
2. Select images from your photo library
3. Add optional text and send
4. The AI will analyze the images and respond

### Managing Chats

- **Delete a chat**: Swipe left on any chat in the list
- **Navigate to a chat**: Tap on any chat in the list
- **View settings**: Tap the gear icon (⚙️)

### During a Conversation

- **Send a message**: Type your message and tap send (↑) or press return
- **Attach images**: Tap the + button to select images
- **Stop generation**: Tap the stop button while a response is being generated
- **View sources**: Tap on the sources bar to see web citations

## Architecture

Built with **The Composable Architecture (TCA)** for predictable state management:

- **Predictable state management** - All state changes flow through reducers
- **Testability** - Business logic tested in isolation
- **Modularity** - Self-contained, composable features
- **Type safety** - Leverages Swift's type system

### Project Structure

```
iA/
├── Sources/
│   ├── Features/
│   │   ├── ChatFeature/           # Chat conversation with streaming
│   │   ├── ChatListFeature/       # Chat list management
│   │   ├── MessageFeature/        # Message display
│   │   ├── MessageInputFeature/   # Message input with image picker
│   │   ├── ModelPickerFeature/    # Model selection
│   │   ├── SettingsFeature/       # App settings
│   │   └── SourcesFeature/        # Web source citations
│   ├── Services/
│   │   ├── ChatService.swift      # Chat API with SSE streaming
│   │   ├── GoogleAIService.swift  # Google AI client
│   │   └── UserDefaultsService.swift
│   └── Components/
│       ├── LoadingIndicatorView.swift
│       ├── NoChatsMessage.swift
│       └── ReasoningView.swift
└── App.swift
```

### Key Features

- **ChatService**: Server-Sent Events (SSE) streaming for real-time responses
- **GoogleAIService**: Multimodal API support with inline image data
- **Feature Modules**: Self-contained TCA features with reducers, actions, and state
- **Web Sources**: Automatic redirect resolution for Google grounding URLs

## Technologies

- **SwiftUI** - Modern declarative UI framework
- **The Composable Architecture** - State management
- **Swift Concurrency** - Async/await for streaming
- **Google AI (Gemini)** - Multimodal AI models
- **PhotosUI** - Native image picker
- **MarkdownUI** - Rich text formatting

## Development

### Dependencies

Main Swift Package Manager dependencies:

- [swift-composable-architecture](https://github.com/pointfreeco/swift-composable-architecture)
- [swift-markdown-ui](https://github.com/gonzalezreal/swift-markdown-ui)
- [NetworkImage](https://github.com/gonzalezreal/NetworkImage)

### Building

```bash
# Build the project
xcodebuild -project iA.xcodeproj -scheme Ai -destination 'platform=macOS'

# Or build in Xcode (⌘B)
```

### Running Tests

```bash
# Run tests
./run_tests.sh

# Or in Xcode (⌘U)
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Repository

[https://github.com/michaljach/lama-ios](https://github.com/michaljach/lama-ios)

## License

This project is open source and available under the [MIT License](LICENSE).

## Acknowledgments

- Built with [The Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture) by [Point-Free](https://www.pointfree.co/)
- Powered by [Google AI (Gemini)](https://ai.google.dev/)
