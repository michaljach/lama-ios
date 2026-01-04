//
//  ChatReducerTests.swift
//  iATests
//
//  Created by Test Suite on 31/12/2025.
//

import XCTest
import ComposableArchitecture

@MainActor
final class ChatReducerTests: XCTestCase {
  
  func test_initialState() {
    let state = Chat.State(id: UUID())
    
    XCTAssertNotNil(state.id)
    XCTAssertTrue(state.messages.isEmpty)
    XCTAssertEqual(state.loadingState, .idle)
    XCTAssertFalse(state.messageInputState.isLoading)
  }
  
  func test_chatTitle_withEmptyMessages() {
    let state = Chat.State(id: UUID())
    
    XCTAssertEqual(state.title, "New Chat")
  }
  
  func test_chatTitle_withUserMessage() {
    var state = Chat.State(id: UUID())
    let message = Message.State(id: UUID(), role: .user, content: "Hello, how are you?")
    state.messages.append(message)
    
    XCTAssertEqual(state.title, "Hello, how are you?")
  }
  
  func test_chatTitle_withLongMessage() {
    var state = Chat.State(id: UUID())
    let longText = String(repeating: "a", count: 100)
    let message = Message.State(id: UUID(), role: .user, content: longText)
    state.messages.append(message)
    
    XCTAssertEqual(state.title.count, 53) // 50 chars + "..."
    XCTAssertTrue(state.title.hasSuffix("..."))
  }
  
  func test_visibleMessages_filtersCorrectly() {
    var state = Chat.State(id: UUID())
    let userMessage = Message.State(id: UUID(), role: .user, content: "User message")
    let assistantMessage = Message.State(id: UUID(), role: .assistant, content: "Assistant response")
    
    state.messages.append(userMessage)
    state.messages.append(assistantMessage)
    
    let visibleMessages = state.visibleMessages
    XCTAssertEqual(visibleMessages.count, 2)
  }
  
  func test_modelSelection() async {
    let store = TestStore(
      initialState: Chat.State(id: UUID()),
      reducer: { Chat() },
      withDependencies: { deps in
        deps.userDefaultsService = .testValue
      }
    )
    
    await store.send(.modelSelected("openai/gpt-oss:120b")) { state in
      state.model = "openai/gpt-oss:120b"
    }
  }
  
  func test_loadingState_transitions() async {
    let store = TestStore(
      initialState: Chat.State(id: UUID()),
      reducer: { Chat() },
      withDependencies: { deps in
        deps.userDefaultsService = .testValue
      }
    )
    
    XCTAssertEqual(store.state.loadingState, .idle)
  }
  
  func test_webSearchUI_showsAndHides() async {
    var state = Chat.State(id: UUID())
    XCTAssertFalse(state.isShowingWebSearchUI)
    
    state.isShowingWebSearchUI = true
    XCTAssertTrue(state.isShowingWebSearchUI)
    
    state.isShowingWebSearchUI = false
    XCTAssertFalse(state.isShowingWebSearchUI)
  }
  
  func test_errorMessage_storage() async {
    var state = Chat.State(id: UUID())
    XCTAssertNil(state.errorMessage)
    
    state.errorMessage = "API error"
    XCTAssertEqual(state.errorMessage, "API error")
    
    state.errorMessage = nil
    XCTAssertNil(state.errorMessage)
  }
}

@MainActor
final class ChatListReducerTests: XCTestCase {
  
  func test_initialState() {
    let state = ChatList.State()
    
    XCTAssertTrue(state.chats.isEmpty)
    XCTAssertTrue(state.availableModels.isEmpty)
    XCTAssertFalse(state.isLoadingModels)
  }
  
  func test_newChat_createsNewChatState() async {
    let store = TestStore(
      initialState: ChatList.State(),
      reducer: { ChatList() },
      withDependencies: { deps in
      }
    )
    
    await store.send(.newChatButtonTapped) { state in
      XCTAssertEqual(state.chats.count, 1)
      XCTAssertEqual(state.path.count, 1)
    }
  }
  
  func test_deleteChat_removesChat() async {
    var initialState = ChatList.State()
    let chatId = UUID()
    initialState.chats.insert(Chat.State(id: chatId), at: 0)
    
    let store = TestStore(
      initialState: initialState,
      reducer: { ChatList() },
      withDependencies: { deps in
      }
    )
    
    await store.send(.deleteChat(chatId)) { state in
      XCTAssertTrue(state.chats.isEmpty)
    }
  }
  
  func test_modelsLoaded_syncsToAllChats() async {
    var initialState = ChatList.State()
    let chatId = UUID()
    initialState.chats.insert(Chat.State(id: chatId), at: 0)
    
    let models = ["openai/gpt-oss:120b", "llama-2-70b"]
    
    let store = TestStore(
      initialState: initialState,
      reducer: { ChatList() },
      withDependencies: { deps in
      }
    )
    
    await store.send(.modelsLoaded(models)) { state in
      state.availableModels = models
      state.isLoadingModels = false
      state.chats[id: chatId]?.availableModels = models
    }
  }
  
  func test_settingsButton_navigates() async {
    let store = TestStore(
      initialState: ChatList.State(),
      reducer: { ChatList() },
      withDependencies: { deps in
      }
    )
    
    await store.send(.settingsButtonTapped) { state in
      XCTAssertEqual(state.path.count, 1)
    }
  }
  
  func test_removeEmptyChats() async {
    var initialState = ChatList.State()
    initialState.chats.insert(Chat.State(id: UUID()), at: 0) // Empty chat
    initialState.chats.insert(Chat.State(id: UUID()), at: 0) // Empty chat
    
    XCTAssertEqual(initialState.chats.count, 2)
    
    let store = TestStore(
      initialState: initialState,
      reducer: { ChatList() },
      withDependencies: { deps in
      }
    )
    
    await store.send(.removeEmptyChats) { state in
      // Both chats should be removed since they're empty
      XCTAssertTrue(state.chats.isEmpty)
    }
  }
}
