# Google AI Integration - Implementation Summary

## What Was Added

### 1. **GoogleAIService** (`iA/Sources/Services/GoogleAIService.swift`)

A new service that handles direct communication with the Google AI API.

**Features:**

- `generateContent()` - Sends messages to Google AI and receives responses
- `listModels()` - Retrieves available Google AI models
- Proper error handling with custom `GoogleAIError` enum
- Support for temperature and max tokens configuration
- Thread-safe implementation with `@Sendable` closures

**Dependencies:**

- Uses `UserDefaults` for API key storage

### 2. **ChatService** (`iA/Sources/Services/ChatService.swift`)

A unified abstraction layer that supports both Groq and Google AI APIs.

**Features:**

- Single interface for both providers via `ChatProvider` enum
- `sendMessage()` function that routes to the correct provider
- Automatic message format conversion for each provider
- Unified error handling with `ChatError` enum
- Test implementations for both services

**Key Implementations:**

- `sendGroqMessage()` - Handles Groq API communication
- `sendGoogleAIMessage()` - Handles Google AI API communication

### 3. **Updated SettingsReducer** (`iA/Sources/Features/SettingsFeature/SettingsReducer.swift`)

Enhanced with Google AI support.

**New State Properties:**

- `apiProvider: APIProvider` - Enum for provider selection (Groq/Google AI)
- `googleAIAPIKey: String` - Stores the Google AI API key

**New Nested Enum:**

- `APIProvider` with cases `.groq` and `.googleAI`
- Each provider has a `displayName` for UI display

**New Actions:**

- `.apiProviderChanged(APIProvider)` - Handle provider switching
- `.googleAIAPIKeyChanged(String)` - Handle API key input

### 4. **Updated SettingsView** (`iA/Sources/Features/SettingsFeature/SettingsView.swift`)

Enhanced UI with provider selection and Google AI API key input.

**New UI Elements:**

- API Provider picker at the top
- Conditional Google AI API key section that appears when Google AI is selected
- Help text directing users to aistudio.google.com
- Security note about local storage

### 5. **Documentation**

#### `GOOGLE_AI_INTEGRATION.md`

Comprehensive guide covering:

- How to get a Google AI API key
- How to configure the app
- Available models
- Supported features
- Architecture overview
- Security considerations
- Troubleshooting guide
- Links to official documentation

#### Updated `README.md`

- Changed description to mention both Groq and Google AI support
- Updated features list to highlight dual-provider capability
- Updated requirements section with Google AI option
- Added Google AI setup instructions
- Listed available models for both providers
- Added link to Google AI Integration Guide

## Technical Architecture

### Data Flow

```
User Input (Settings View)
    ↓
SettingsReducer (State Management)
    ↓
ChatService (Abstraction Layer)
    ├→ Groq Provider
    └→ Google AI Service
        ↓
    Google AI API
```

### Provider Selection Logic

1. User selects provider in Settings
2. Selection is stored in `UserDefaults` with key `"apiProvider"`
3. API key is stored with key `"googleAIAPIKey"` (Groq uses `"groqAPIKey"`)
4. When sending messages, `ChatService` routes to correct provider based on selection

### API Endpoints

**Google AI:**

- Model listing: `https://generativelanguage.googleapis.com/v1beta/models?key={API_KEY}`
- Content generation: `https://generativelanguage.googleapis.com/v1beta/models/{MODEL_ID}:generateContent?key={API_KEY}`

**Groq:** (already implemented)

- `https://api.groq.com/openai/v1/chat/completions`

## Model Compatibility

### Google AI Models Supported

- `gemini-2.5-flash` - Fast, efficient model
- `gemini-2.5-pro` - Advanced reasoning
- `gemini-3-flash` - Frontier-class performance
- `gemini-3-pro` - Most intelligent model

### Groq Models Supported

- Mixtral-8x7b-32768
- Llama-3.1-70b
- Gemma-7b
- Meta-Llama-Scout-17b

## Security Features

1. **Local Storage Only** - Keys stored in `UserDefaults`, not in code or cloud
2. **HTTPS Encryption** - All API calls use HTTPS
3. **No Backend Server** - Direct client-to-API communication
4. **No Logging** - API keys not logged or tracked

## How to Use

### For End Users

1. Get Google AI API key from https://aistudio.google.com/apikey
2. Open app Settings (⚙️)
3. Select "Google AI (Gemini)" as API Provider
4. Enter your API key
5. Select a Gemini model from the Model dropdown
6. Start chatting!

### For Developers

To use the ChatService in a reducer:

```swift
@Dependency(\.chatService) var chatService

// In your reducer's body:
case .sendMessage(let messages, let model, let temp, let tokens):
    return .run { send in
        do {
            let response = try await chatService.sendMessage(
                messages,
                model,
                temp,
                tokens,
                .googleAI  // or .groq
            )
            await send(.messageReceived(response))
        } catch {
            await send(.messageFailed(error))
        }
    }
```

## Testing

Both services include test implementations:

```swift
// In DependencyKey extensions:
static let testValue = Self(...)
```

These are automatically used in previews and tests, returning mock responses.

## Error Handling

### GoogleAIError Cases

- `.invalidAPIKey` - No API key provided
- `.networkError(String)` - Network connectivity issues
- `.invalidResponse` - Malformed API response
- `.apiError(String)` - Server-side errors

### ChatError Cases

- `.noAPIKey` - Provider API key not configured
- `.networkError(String)` - Network issues
- `.invalidResponse` - Malformed response
- `.apiError(String)` - Server errors

All errors conform to `LocalizedError` for user-friendly display.

## Future Enhancements

Potential improvements for future releases:

1. **Streaming Support** - Implement SSE for real-time message streaming
2. **Vision Support** - Add image analysis capabilities for Google AI
3. **Function Calling** - Support Google AI's function calling feature
4. **Token Counting** - Show token usage before sending messages
5. **Model Comparison** - Allow side-by-side comparison of both providers
6. **Advanced Settings** - Provider-specific parameters (e.g., Web Search for Groq)

## Backward Compatibility

The integration maintains full backward compatibility:

- Existing Groq functionality unchanged
- New Google AI is opt-in via Settings
- Default provider remains Groq
- Existing user data unaffected

## Files Modified/Created

### Created

- `iA/Sources/Services/GoogleAIService.swift`
- `iA/Sources/Services/ChatService.swift`
- `GOOGLE_AI_INTEGRATION.md`

### Modified

- `iA/Sources/Features/SettingsFeature/SettingsReducer.swift`
- `iA/Sources/Features/SettingsFeature/SettingsView.swift`
- `README.md`

## Next Steps

1. Build the project in Xcode
2. Test with a Google AI API key from https://aistudio.google.com/apikey
3. Verify both Groq and Google AI functionality
4. Test provider switching in Settings
5. Verify API key persistence across app launches

## Support Resources

- [Google AI API Documentation](https://ai.google.dev/gemini-api/docs)
- [Getting Started Guide](https://ai.google.dev/gemini-api/docs/quickstart)
- [API Reference](https://ai.google.dev/api)
- [Pricing Information](https://ai.google.dev/gemini-api/docs/pricing)
