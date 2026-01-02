# Google AI (Gemini) Integration Guide

This guide explains how to integrate and use the Google AI API with the iA chat application.

## Overview

The application now supports both **Groq** and **Google AI (Gemini)** as API providers. You can switch between them in the settings and configure each provider independently.

## Getting Started with Google AI

### 1. Get an API Key

1. Visit [Google AI Studio](https://aistudio.google.com/apikey)
2. Sign in with your Google account (create one if needed)
3. Click "Create API Key"
4. Copy your API key

### 2. Configure in the App

1. Launch the iA app
2. Tap the Settings icon (⚙️)
3. Select "API Provider" and choose "Google AI (Gemini)"
4. Paste your API key in the "API Key" field
5. The app will remember your key for future sessions

## Available Google AI Models

The application supports the following Google AI models:

- **gemini-2.5-flash** - Fast and efficient model, great for most tasks
- **gemini-2.5-pro** - More capable model for complex reasoning
- **gemini-3-flash** - Latest frontier-class performance
- **gemini-3-pro** - Most intelligent model with advanced reasoning

Model availability depends on your Google AI account tier and current API availability.

## Features Supported

### Text Generation

- Standard chat conversations
- Streaming responses
- Configurable temperature and max tokens

### Model Parameters

- **Temperature**: Controls response creativity (0.0 = deterministic, 2.0 = very creative)
- **Max Tokens**: Limits the length of generated responses

## Architecture

### New Services

#### ChatService

A unified service that handles communication with both Groq and Google AI APIs. Located in `Sources/Services/ChatService.swift`.

**Key functions:**

- `sendMessage()` - Sends a message and receives a response from the configured provider

#### GoogleAIService

Specialized service for Google AI API interactions. Located in `Sources/Services/GoogleAIService.swift`.

**Key functions:**

- `generateContent()` - Sends a request to Google AI API
- `listModels()` - Retrieves available models from Google AI

### Updated Components

#### SettingsReducer

Updated to support:

- API provider selection (Groq or Google AI)
- Google AI API key storage
- Provider-specific settings

#### SettingsView

Enhanced UI to:

- Display provider selection
- Show Google AI API key input field
- Display provider-specific configuration options

## Security Considerations

⚠️ **Important Security Notes:**

1. **Local Storage Only**: API keys are stored only in your device's `UserDefaults`. They are never uploaded to any external server except the respective API provider.

2. **HTTPS Only**: All communication with Google AI servers uses HTTPS encryption.

3. **No Backup**: If you uninstall the app, stored API keys will be lost. Keep your actual API key secure.

4. **Device Security**: Ensure your iOS device is secured with a passcode or Face ID to protect stored credentials.

## Switching Between Providers

You can easily switch between Groq and Google AI:

1. Open Settings (⚙️)
2. Change "API Provider" selection
3. If switching to Google AI, ensure you've set your API key
4. The default model will be used for each provider

## Available Groq Models

When using Groq, the following models are available:

- Mixtral-8x7b-32768
- Llama-3.1-70b
- Gemma-7b
- Meta-Llama-Scout-17b (vision)

## Troubleshooting

### "No API Key" Error

- Ensure you've entered your API key in Settings
- Check that you selected the correct provider
- Verify the API key is from the correct provider (Groq keys won't work with Google AI)

### "Invalid Response" Error

- Check your internet connection
- Ensure the selected model is available for your API tier
- Verify your API key hasn't expired or been revoked

### "Rate Limit" Error

- You've exceeded the API rate limit
- Wait a few moments and try again
- Check your API plan for rate limit details

## API Documentation

For more information about the Google AI API:

- [Official Documentation](https://ai.google.dev/gemini-api/docs)
- [API Reference](https://ai.google.dev/api)
- [Models Documentation](https://ai.google.dev/gemini-api/docs/models)
- [Quickstart Guide](https://ai.google.dev/gemini-api/docs/quickstart)

## Cost Information

Check [Google AI Pricing](https://ai.google.dev/gemini-api/docs/pricing) for current rates.

The free tier includes:

- Limited requests per month
- Access to latest models
- Perfect for testing and development

## Support

For issues with the Google AI integration:

1. Check the [API troubleshooting guide](https://ai.google.dev/gemini-api/docs/troubleshooting)
2. Verify your internet connection
3. Ensure your API key is valid at [Google AI Studio](https://aistudio.google.com/)
4. Check the app's error messages for specific details
