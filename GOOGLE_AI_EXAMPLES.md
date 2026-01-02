# Google AI Integration - Code Examples

This document provides code examples for working with the Google AI integration.

## Basic Usage in Reducers

### Using ChatService to Send Messages

```swift
import ComposableArchitecture

@Reducer
struct Chat {
  @Dependency(\.chatService) var chatService
  @Dependency(\.userDefaultsService) var userDefaultsService

  enum Action {
    case sendMessage(String)
    case messageReceived(String)
    case messageError(String)
  }

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .sendMessage(let userMessage):
        let provider: ChatProvider = userDefaultsService.getAPIProvider() == "googleai"
          ? .googleAI
          : .groq

        let selectedModel = userDefaultsService.getDefaultModel()
        let temperature = userDefaultsService.getTemperature()
        let maxTokens = userDefaultsService.getMaxTokens()

        let messages = [
          ChatMessage(role: "user", content: userMessage)
        ]

        return .run { send in
          do {
            let response = try await chatService.sendMessage(
              messages,
              selectedModel,
              temperature,
              maxTokens,
              provider
            )
            await send(.messageReceived(response))
          } catch {
            await send(.messageError(error.localizedDescription))
          }
        }

      case .messageReceived(let response):
        // Handle received message
        return .none

      case .messageError(let errorMessage):
        // Handle error
        return .none
      }
    }
  }
}
```

## Provider-Specific Implementation

### Handling Both Providers

```swift
func handleChatMessage(
  _ message: String,
  provider: ChatProvider,
  model: String
) async throws -> String {
  let chatService = ChatService.liveValue

  switch provider {
  case .groq:
    // Groq-specific handling
    let messages = [ChatMessage(role: "user", content: message)]
    return try await chatService.sendMessage(
      messages,
      model,
      0.7,
      1024,
      .groq
    )

  case .googleAI:
    // Google AI-specific handling
    let messages = [ChatMessage(role: "user", content: message)]
    return try await chatService.sendMessage(
      messages,
      model,
      0.7,
      1024,
      .googleAI
    )
  }
}
```

## Settings Integration

### Switching Providers

```swift
// In SettingsReducer:
case .apiProviderChanged(let newProvider):
  state.apiProvider = newProvider
  UserDefaults.standard.set(newProvider.rawValue, forKey: "apiProvider")

  // Notify dependent features
  return .run { send in
    await send(.refreshAvailableModels)
  }

case .googleAIAPIKeyChanged(let key):
  state.googleAIAPIKey = key
  UserDefaults.standard.set(key, forKey: "googleAIAPIKey")
  return .none
```

### View Example

```swift
struct ProviderSettings: View {
  let store: StoreOf<Settings>

  var body: some View {
    Form {
      Section("API Provider") {
        Picker("Provider", selection: Binding(
          get: { store.apiProvider },
          set: { store.send(.apiProviderChanged($0)) }
        )) {
          ForEach(Settings.APIProvider.allCases, id: \.self) { provider in
            Text(provider.displayName).tag(provider)
          }
        }
      }

      if store.apiProvider == .googleAI {
        Section("Google AI Configuration") {
          SecureField("API Key", text: Binding(
            get: { store.googleAIAPIKey },
            set: { store.send(.googleAIAPIKeyChanged($0)) }
          ))

          Button("Get API Key") {
            if let url = URL(string: "https://aistudio.google.com/apikey") {
              UIApplication.shared.open(url)
            }
          }
        }
      }
    }
  }
}
```

## Error Handling Examples

### Try-Catch Pattern

```swift
do {
  let response = try await chatService.sendMessage(
    messages,
    model,
    temperature,
    maxTokens,
    provider
  )
  // Handle success
  print("Response: \(response)")
} catch let error as ChatError {
  switch error {
  case .noAPIKey:
    print("API key not configured")
  case .networkError(let message):
    print("Network error: \(message)")
  case .invalidResponse:
    print("Invalid response from API")
  case .apiError(let message):
    print("API error: \(message)")
  }
} catch {
  print("Unknown error: \(error)")
}
```

### Error Recovery

```swift
func sendMessageWithRetry(
  _ message: String,
  maxRetries: Int = 3
) async throws -> String {
  var lastError: ChatError?

  for attempt in 1...maxRetries {
    do {
      return try await chatService.sendMessage(
        [ChatMessage(role: "user", content: message)],
        "gemini-2.5-flash",
        0.7,
        1024,
        .googleAI
      )
    } catch let error as ChatError {
      lastError = error
      if attempt < maxRetries {
        try await Task.sleep(for: .seconds(Double(attempt)))
      }
    }
  }

  throw lastError ?? ChatError.apiError("Unknown error after retries")
}
```

## Testing with Mock Data

### Preview Usage

```swift
#Preview {
  SettingsView(
    store: Store(initialState: Settings.State()) {
      Settings()
        .dependency(\.chatService, .testValue)
        .dependency(\.googleAIService, .testValue)
    }
  )
}
```

### Unit Test Example

```swift
@MainActor
func testGoogleAIIntegration() async {
  let store = TestStore(
    initialState: Chat.State(),
    reducer: { Chat() }
      .dependency(\.chatService, ChatService(
        sendMessage: { _, _, _, _, provider in
          XCTAssertEqual(provider, .googleAI)
          return "Mock Google AI Response"
        }
      ))
  )

  await store.send(.sendMessage("Hello")) { state in
    state.isLoading = true
  }

  await store.receive(.messageReceived("Mock Google AI Response")) { state in
    state.isLoading = false
    state.messages.append(.init(role: "assistant", content: "Mock Google AI Response"))
  }
}
```

## Advanced: Streaming Support (Future)

```swift
// Example of how streaming could be implemented in the future
extension ChatService {
  func streamMessage(
    _ messages: [ChatMessage],
    model: String,
    provider: ChatProvider
  ) async throws -> AsyncStream<String> {
    return AsyncStream { continuation in
      Task {
        do {
          // Implementation would use URLSession's WebSocket or Server-Sent Events
          let response = try await sendMessage(
            messages,
            model,
            0.7,
            1024,
            provider
          )
          continuation.yield(response)
          continuation.finish()
        } catch {
          continuation.finish(throwing: error)
        }
      }
    }
  }
}

// Usage in a reducer
return .run { send in
  do {
    let stream = try await chatService.streamMessage(
      messages,
      "gemini-2.5-flash",
      .googleAI
    )
    for try await chunk in stream {
      await send(.streamChunk(chunk))
    }
  } catch {
    await send(.error(error))
  }
}
```

## Configuration Management

### Retrieving Current Configuration

```swift
struct ChatConfiguration {
  let provider: ChatProvider
  let model: String
  let temperature: Double
  let maxTokens: Int

  static func current(from userDefaults: UserDefaultsService) -> Self {
    let providerRaw = UserDefaults.standard.string(forKey: "apiProvider") ?? "groq"
    let provider = Settings.APIProvider(rawValue: providerRaw) == .googleAI
      ? ChatProvider.googleAI
      : .groq

    return ChatConfiguration(
      provider: provider,
      model: userDefaults.getDefaultModel(),
      temperature: userDefaults.getTemperature(),
      maxTokens: userDefaults.getMaxTokens()
    )
  }
}

// Usage
let config = ChatConfiguration.current(from: userDefaultsService)
let response = try await chatService.sendMessage(
  messages,
  config.model,
  config.temperature,
  config.maxTokens,
  config.provider
)
```

## API Key Management

### Safe API Key Handling

```swift
extension UserDefaultsService {
  // Secure storage helper
  func saveGoogleAIAPIKey(_ key: String) {
    UserDefaults.standard.set(key, forKey: "googleAIAPIKey")
    // In a production app, consider Keychain storage
  }

  func getGoogleAIAPIKey() -> String {
    UserDefaults.standard.string(forKey: "googleAIAPIKey") ?? ""
  }

  func clearGoogleAIAPIKey() {
    UserDefaults.standard.removeObject(forKey: "googleAIAPIKey")
  }

  // Validate API key format
  func isValidGoogleAIAPIKey(_ key: String) -> Bool {
    // Basic validation - Google AI keys typically have a specific format
    return !key.isEmpty && key.count > 20
  }
}
```

## Performance Considerations

### Caching Model List

```swift
class ModelCache {
  static let shared = ModelCache()

  private var cachedGroqModels: [String]?
  private var cachedGoogleAIModels: [String]?

  func getModels(for provider: ChatProvider) -> [String]? {
    switch provider {
    case .groq:
      return cachedGroqModels
    case .googleAI:
      return cachedGoogleAIModels
    }
  }

  func setModels(_ models: [String], for provider: ChatProvider) {
    switch provider {
    case .groq:
      cachedGroqModels = models
    case .googleAI:
      cachedGoogleAIModels = models
    }
  }
}
```

## Common Patterns

### Message History Management

```swift
struct ChatHistory {
  var messages: [ChatMessage] = []

  mutating func addUserMessage(_ content: String) {
    messages.append(ChatMessage(role: "user", content: content))
  }

  mutating func addAssistantMessage(_ content: String) {
    messages.append(ChatMessage(role: "assistant", content: content))
  }

  func getMessagesForAPI() -> [ChatMessage] {
    return messages  // Or filtered/formatted as needed
  }
}
```

### Provider-Agnostic Response Handling

```swift
func processResponse(
  _ response: String,
  provider: ChatProvider
) -> ProcessedResponse {
  // Handle provider-specific response formatting if needed
  switch provider {
  case .groq:
    return ProcessedResponse(content: response, provider: "Groq")
  case .googleAI:
    return ProcessedResponse(content: response, provider: "Google AI")
  }
}
```

These examples demonstrate how to effectively use the Google AI integration throughout your application.
