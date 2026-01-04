# iA Tests

This directory contains comprehensive unit and integration tests for the iA chat application.

## Test Structure

### Services Tests
- **UserDefaultsServiceTests.swift** - Tests for user preferences and settings storage
  - Tests for getting/setting API key, model, temperature, max tokens
  - Tests for web search preferences
  - Tests for default values

- **GroqModelsTests.swift** - Tests for Groq API model data structures
  - Chat message encoding/decoding
  - Content block handling (text and images)
  - Request payload serialization
  - Message role encoding
  - System prompt handling

### Features Tests
- **ChatReducerTests.swift** - Tests for chat and chat list functionality
  - Chat state initialization
  - Chat title generation
  - Model selection
  - Message history management
  - Web search UI state
  - Error handling

### Integration Tests
- **IntegrationTests.swift** - End-to-end tests combining multiple components
  - Complex message handling with images and text
  - Full request/response cycle simulation
  - Unicode and special character handling
  - Reasoning and web search parameters

### Mock Dependencies
- **MockDependencies.swift** - Reusable mocks and test utilities
  - Mock GroqService
  - Mock UserDefaultsService
  - Test constants

## Running Tests

### From Xcode
1. Select the iATests target
2. Press Cmd+U to run all tests
3. Or select specific tests in the Test Navigator (Cmd+6)

### From Command Line
```bash
# Run all tests
xcodebuild -project iA.xcodeproj -scheme Ai -enableCodeCoverage YES test

# Run specific test class
xcodebuild -project iA.xcodeproj -scheme Ai -enableCodeCoverage YES test \
  -testProductName iATests \
  -testSpecifier UserDefaultsServiceTests

# Run with verbose output
xcodebuild -project iA.xcodeproj -scheme Ai test -verbose
```

## Test Coverage

The test suite covers:
- ✅ UserDefaults service - preferences persistence
- ✅ Groq models - JSON serialization/deserialization
- ✅ Chat reducer - state management and transitions
- ✅ Chat list reducer - collection management
- ✅ Integration scenarios - realistic usage patterns

## Adding New Tests

1. Create test files in the appropriate subdirectory
2. Name files with `Tests` suffix (e.g., `MyFeatureTests.swift`)
3. Use `XCTestCase` as the base class
4. Prefix test methods with `test_` 
5. Use descriptive names following the pattern `test_componentUnderTest_actionPerformed_expectedOutcome`

Example:
```swift
func test_userDefaults_setAPIKey_keySavedCorrectly() {
  // Arrange
  let service = UserDefaultsService.testValue
  let testKey = "test-key-123"
  
  // Act
  service.setGroqAPIKey(testKey)
  
  // Assert
  XCTAssertEqual(service.getGroqAPIKey(), testKey)
}
```

## Testing Best Practices

1. **Arrange-Act-Assert** - Structure tests with setup, action, and verification
2. **Single Responsibility** - Each test should verify one behavior
3. **Isolation** - Tests should not depend on execution order
4. **Descriptive Names** - Test names should clearly state what they verify
5. **Mock External Dependencies** - Use provided mock services for isolation

## Continuous Integration

Tests should pass before committing. Use pre-commit hooks:
```bash
xcodebuild test -project iA.xcodeproj -scheme Ai
```

## Known Limitations

- Tests use `@MainActor` for reducer tests due to Composable Architecture requirements
- Some async tests may require careful time management
- Network calls are mocked to prevent external dependencies
