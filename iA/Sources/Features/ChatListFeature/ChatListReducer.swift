//
//  ChatListReducer.swift
//  lama
//
//  Created by Michal Jach on 31/10/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct ChatList {
  @Dependency(\.googleAIService) var googleAIService
  
  @Reducer
  enum Path {
    case chat(Chat)
    case settings(Settings)
  }

  @ObservableState
  struct State: Equatable {
    var chats: IdentifiedArrayOf<Chat.State> = []
    var path = StackState<Path.State>()
    var availableModels: [AIModel] = []
    var isLoadingModels = false
  }

  enum Action {
    case newChatButtonTapped
    case settingsButtonTapped
    case removeEmptyChats
    case initialize
    case loadModels
    case modelsLoaded([AIModel])
    case modelsLoadError(String)
    case deleteChat(Chat.State.ID)
    case selectChat(UUID)
    case chats(IdentifiedActionOf<Chat>)
    case path(StackActionOf<Path>)
  }
  
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .initialize:
        return .merge(
          .send(.loadModels),
          .send(.newChatButtonTapped)
        )
      
      case .loadModels:
        state.isLoadingModels = true
        return .run { send in
          do {
            let models = try await googleAIService.listModels()
            await send(.modelsLoaded(models))
          } catch {
            await send(.modelsLoadError(error.localizedDescription))
          }
        }
      
      case .modelsLoaded(let models):
        state.isLoadingModels = false
        state.availableModels = models
        
        // Sync models to all chats in collection
        for index in state.chats.indices {
          state.chats[index].modelPickerState.availableModels = models
        }
        
        // Sync models to chats in path (important for auto-created chat on launch)
        // We need to rebuild the path with updated chat states
        var updatedPath = StackState<Path.State>()
        for pathElement in state.path {
          switch pathElement {
          case var .chat(chat):
            chat.modelPickerState.availableModels = models
            updatedPath.append(.chat(chat))
            
            // Also update the chat in the collection if it exists
            if let chatIndex = state.chats.ids.firstIndex(of: chat.id) {
              state.chats[chatIndex].modelPickerState.availableModels = models
            }
          case .settings(let settings):
            updatedPath.append(.settings(settings))
          }
        }
        state.path = updatedPath
        
        return .none
      
      case .modelsLoadError:
        state.isLoadingModels = false
        return .none
        
      case .path(.element(id: _, action: .chat(.messageInput(.sendButtonTapped)))):
        // Sync chat state back to collection after sending a message
        for pathElement in state.path {
          if case let .chat(chat) = pathElement {
            if state.chats.contains(where: { $0.id == chat.id }) {
              state.chats[id: chat.id] = chat
            }
          }
        }
        return .none

      case .path(.popFrom(id: let id)):
        // Sync chat state back when popping from navigation
        if case let .chat(chat) = state.path[id: id] {
          if state.chats.contains(where: { $0.id == chat.id }) {
            state.chats[id: chat.id] = chat
          }
          
          // Remove chat if it has no messages
          if chat.messages.isEmpty {
            state.chats.remove(id: chat.id)
          }
        }
        return .none
        
      case .path:
        return .none

      case .removeEmptyChats:
        return .none

      case .deleteChat(let id):
        state.chats.remove(id: id)
        // Also remove from path if it's there
        state.path.removeAll { element in
          if case let .chat(chat) = element {
            return chat.id == id
          }
          return false
        }
        return .none

      case .newChatButtonTapped:
        print("DEBUG: newChatButtonTapped - path before: \(state.path.count)")
        
        // Clean up empty chats before creating new one
        state.chats.removeAll { $0.messages.isEmpty }
        
        let newChatId = UUID()
        var newChatItem = Chat.State(id: newChatId)
        newChatItem.modelPickerState.availableModels = state.availableModels
        state.chats.insert(newChatItem, at: 0)
        
        // Only replace the path, don't append
        state.path.removeAll()
        state.path.append(.chat(newChatItem))
        print("DEBUG: newChatButtonTapped - path after: \(state.path.count)")
        return .none

      case .settingsButtonTapped:
        print("DEBUG: settingsButtonTapped - path before: \(state.path.count)")
        
        // Clean up empty chats before going to settings
        state.chats.removeAll { $0.messages.isEmpty }
        
        // Replace the path with settings
        state.path.removeAll()
        state.path.append(.settings(Settings.State()))
        print("DEBUG: settingsButtonTapped - path after: \(state.path.count)")
        return .none
      
      case .selectChat(let id):
        print("DEBUG: selectChat - path before: \(state.path.count)")
        guard let chat = state.chats[id: id] else { return .none }
        
        // Clean up OTHER empty chats before selecting this one
        state.chats.removeAll { $0.id != id && $0.messages.isEmpty }
        
        // Replace the path with selected chat
        state.path.removeAll()
        state.path.append(.chat(chat))
        print("DEBUG: selectChat - path after: \(state.path.count)")
        return .none

      case .chats:
        return .none
      }
    }
    .forEach(\.path, action: \.path)
  }
}

extension ChatList.Path.State: Equatable {}
