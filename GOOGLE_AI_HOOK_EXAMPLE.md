# Google AI API Integration - Chat Reducer Example

This document shows how the Google AI API is hooked into the Chat Reducer for your iA application.

## Architecture Overview

```
ChatView (UI)
    ↓
ChatReducer (State Management)
    ↓ @Dependency injection
ChatService (API Router)
    ↓
GoogleAIService (Google AI Implementation)
    ↓
Google AI API (Gemini Models)
```

## Chat Reducer Integration

### 1. Dependency Injection

The ChatReducer now declares a dependency on `chatService`:

```swift
@Reducer
struct Chat {
  @Dependency(\.chatService) var chatService
  
  // ... rest of reducer
}
```

This allows the reducer to call the ChatService without knowing implementation details.

### 2. State Management

The Chat state includes:

```swift
@ObservableState
struct State: Equatable, Identifiable {
  let id: UUID
  var messageInputState = MessageInput.State()
  var modelPickerState = ModelPicker.State()
  var messages: [ChatMessage] = []
  var isLoading: Bool = false
  var errorMessage: String?
  var loadingState: LoadingState = .idle
  var model: String = "gemini-2.5-flash"
  var isShowingWebSearchUI: Bool = false
  
  enum LoadingState: Equatable {
    case idle
    case loading
    case error(String)
  }
}
```

### 3. Actions

The reducer handles these actions:

```swift
enum Action {
  case messageInput(MessageInput.Action)      // Input field actions
  case modelPicker(ModelPicker.Action)        // Model selection
  case sendMessage(String)                    // Send message action
  case messageSent(String)                    // Message confirmed sent
  case messageReceived(String)                // Response from API
  case messageError(String)                   // Error handling
  case clearError                             // Clear error message
  case modelSelected(String)                  // Model selection action
}
```

### 4. Message Flow

When a user sends a message:

**Step 1: User Input**
```swift
case .messageInput(.delegate(.sendMessage)):
  let messageText = state.messageInputState.inputText
    .trimmingCharacters(in: .whitespacesAndNewlines)
  guard !messageText.isEmpty else { return .none }
```

**Step 2: Update State**
```swift
state.isLoading = true
state.loadingState = .loading
state.errorMessage = nil

let userMessage = ChatMessage(role: "user", content: messageText)
state.messages.append(userMessage)
```

**Step 3: Call ChatService**
```swift
return .run { [messages = state.messages, model = state.modelPickerState.selectedModel] send in
  await send(.messageSent(messageText))
  do {
    let response = try await chatService.sendMessage(
      messages: messages,
      model: model,
      temperature: 0.7,
      maxTokens: 1024
    )
    await send(.messageReceived(response))
  } catch {
    await send(.messageError(error.localizedDescription))
  }
}
```

**Step 4: Handle Response**
```swift
case .messageReceived(let response):
  state.isLoading = false
  state.loadingState = .idle
  let assistantMessage = ChatMessage(role: "assistant", content: response)
  state.messages.append(assistantMessage)
  return .none
```

**Step 5: Handle Errors**
```swift
case .messageError(let error):
  state.isLoading = false
  state.loadingState = .error(error)
  state.errorMessage = error
  return .none
```

## ChatService Implementation

The ChatService routes to Google AI:

```swift
extension ChatService: DependencyKey {
  static let liveValue = Self(
    sendMessage: { messages, model, temperature, maxTokens in
      return try await sendGoogleAIMessage(
        messages: messages,
        model: model,
        temperature: temperature,
        maxTokens: maxTokens
      )
    }
  )
}
```

## Google AI API Call

The actual API implementation:

```swift
private func sendGoogleAIMessage(
  messages: [ChatMessage],
  model: String,
  temperature: Double,
  maxTokens: Int
) async throws -> String {
  let apiKey = UserDefaults.standard.string(forKey: "googleAIAPIKey") ?? ""
  guard !apiKey.isEmpty else {
    throw ChatError.noAPIKey
  }
  
  let apiModel = model.contains("/") ? model : "models/\(model)"
  
  let url = URL(string: 
    "https://generativelanguage.googleapis.com/v1beta/models/\(apiModel):generateContent?key=\(apiKey)"
  )!
  
  var request = URLRequest(url: url)
  request.httpMethod = "POST"
  request.setValue("application/json", forHTTPHeaderField: "Content-Type")
  
  // Convert chat messages to Google AI format
  var googleMessages: [GoogleAIMessage] = []
  for message in messages {
    let googleRole = message.role == "user" ? "user" : "model"
    googleMessages.append(
      GoogleAIMessage(
        role: googleRole,
        parts: [GoogleAIMessage.Part(text: message.content)]
      )
    )
  }
  
  let googleRequest = GoogleAIRequest(
    contents: googleMessages,
    generationConfig: GoogleAIRequest.GenerationConfig(
      temperature: temperature,
      maxOutputTokens: maxTokens
    )
  )
  
  request.httpBody = try JSONEncoder().encode(googleRequest)
  
  let (data, response) = try await URLSession.shared.data(for: request)
  
  guard let httpResponse = response as? HTTPURLResponse else {
    throw ChatError.invalidResponse
  }
  
  if httpResponse.statusCode != 200 {
    let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
    throw ChatError.apiError("Status code: \(httpResponse.statusCode)")
  }
  
  let googleResponse = try JSONDecoder().decode(GoogleAIResponse.self, from: data)
  
  guard let text = googleResponse.candidates.first?.content.parts.first?.text else {
    throw ChatError.invalidResponse
  }
  
  return text
}
```

## Message Format Conversion

The reducer works with `ChatMessage` (universal format):

```swift
struct ChatMessage: Equatable, Identifiable {
  let id = UUID()
  let role: String  // "user" or "assistant"
  let content: String
}
```

The ChatService converts to Google AI format:

```swift
struct GoogleAIMessage: Codable {
  let role: String                    // "user" or "model"
  let parts: [Part]
  
  struct Part: Codable {
    let text: String
  }
}
```

## Available Google AI Models

The application supports:

- `gemini-2.5-flash` - Fast and efficient
- `gemini-2.5-pro` - More capable
- `gemini-3-flash` - Latest frontier-class
- `gemini-3-pro` - Most intelligent

## Configuration in Settings

Users can:

1. Select API Provider (Groq or Google AI)
2. Enter Google AI API Key
3. Select model from available options
4. Adjust temperature and max tokens

## Error Handling

The reducer handles several error cases:

- **No API Key**: `ChatError.noAPIKey`
- **Network Error**: `ChatError.networkError(String)`
- **Invalid Response**: `ChatError.invalidResponse`
- **API Error**: `ChatError.apiError(String)`

Errors are stored in `state.errorMessage` and `state.loadingState`.

## Testing

To test the Google AI integration:

```swift
let store = TestStore(
  initialState: Chat.State(id: UUID()),
  reducer: { Chat() },
  withDependencies: { deps in
    deps.chatService = .testValue  // Uses mock response
  }
)

await store.send(.sendMessage("Hello")) { state in
  state.isLoading = true
  state.messages.append(ChatMessage(role: "user", content: "Hello"))
}

await store.receive(.messageSent("Hello")) { state in
  state.messageInputState.inputText = ""
}

await store.receive(.messageReceived("Test response")) { state in
  state.isLoading = false
  state.messages.append(ChatMessage(role: "assistant", content: "Test response"))
}
```

## Complete Data Flow

```
User Input
    ↓
[User Text] → ChatView
    ↓
Chat.Action.sendMessage
    ↓
ChatReducer processes:
  1. Add user message to state
  2. Set isLoading = true
  3. Call chatService.sendMessage()
    ↓
ChatService.sendMessage:
  1. Format messages for Google AI
  2. Make HTTP POST request
  3. Parse response
  4. Return text
    ↓
ChatReducer receives response:
  1. Add assistant message to state
  2. Set isLoading = false
  3. Update UI
    ↓
[Chat displayed with new messages]
```

## Next Steps

1. Get API key from [Google AI Studio](https://aistudio.google.com/apikey)
2. Enter key in Settings
3. Select Google AI as provider
4. Start chatting!

For troubleshooting, see GOOGLE_AI_INTEGRATION.md
