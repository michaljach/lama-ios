//
//  ChatView.swift
//  lama
//
//  Created by Michal Jach on 31/10/2025.
//

import ComposableArchitecture
import SwiftUI
import MarkdownUI

struct ChatView: View {
  @Bindable var store: StoreOf<Chat>
  
  var body: some View {
    VStack(spacing: 0) {
      // Error banner
      if let errorMessage = store.errorMessage {
        VStack(alignment: .leading, spacing: 8) {
          HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
              .foregroundColor(.orange)
              .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
              Text("Error")
                .font(.headline)
                .foregroundColor(.primary)
              
              Text(errorMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            Button(action: { store.send(.clearError) }) {
              Image(systemName: "xmark.circle.fill")
                .foregroundColor(.gray)
                .font(.title3)
            }
          }
          .padding(16)
          .background(Color.orange.opacity(0.1))
          .cornerRadius(12)
          .padding(.horizontal, 16)
          .padding(.top, 8)
          .padding(.bottom, 8)
        }
        .transition(.move(edge: .top).combined(with: .opacity))
      }
      
      ScrollViewReader { scrollProxy in
        ScrollView {
          LazyVStack(alignment: .leading, spacing: 12) {
            ForEachStore(
              store.scope(state: \.messages, action: \.message)
            ) { messageStore in
              MessageView(store: messageStore)
            }
            
            // Loading indicator
            if store.isLoading {
              HStack(spacing: 8) {
                ProgressView()
                  .progressViewStyle(CircularProgressViewStyle())
                  .scaleEffect(0.8)
                
                if store.loadingState == .webSearching {
                  Text("Searching the web...")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
                } else {
                  Text("Thinking...")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
                }
              }
              .padding(.horizontal, 16)
              .padding(.vertical, 8)
              .transition(.opacity)
              .id("loading-indicator")
            }
          }
          .padding(.top)
          .scrollTargetLayout()
          .onChange(of: store.messages.count) { _, newCount in
            // Scroll to bottom when new message arrives
            if let lastMessage = store.messages.last {
              scrollProxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
          }
          .onChange(of: store.isLoading) { _, isLoading in
            // Scroll to loading indicator when it appears
            if isLoading {
              scrollProxy.scrollTo("loading-indicator", anchor: .bottom)
            }
          }
        }
        .scrollDismissesKeyboard(.interactively)
      }
      .safeAreaInset(edge: .bottom) {
        MessageInputView(
          store: store.scope(
            state: \.messageInputState,
            action: \.messageInput
          )
        )
      }
    }
    .navigationTitle("Chat")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        ModelPickerView(
          store: store.scope(
            state: \.modelPickerState,
            action: \.modelPicker
          )
        )
      }
    }
  }
}


#Preview {
  NavigationView {
    ChatView(
      store: Store(initialState: {
        var state = Chat.State(
          id: UUID()
        )
        
        // Add example messages
        state.messages = [
          Message.State(
            id: UUID(),
            role: .user,
            content: "What is SwiftUI?"
          ),
          Message.State(
            id: UUID(),
            role: .assistant,
            content: """
          **SwiftUI** is Apple's modern framework for building user interfaces across all Apple platforms.
          
          ## Key Features
          
          • **Declarative syntax** - Describe what your UI should look like
          • **Cross-platform** - Works on iOS, macOS, watchOS, and tvOS
          • **Live previews** - See changes instantly as you code
          • **Built-in animations** - Smooth transitions with minimal code
          
          ### Example Code
          
          ```swift
          struct ContentView: View {
              var body: some View {
                  Text("Hello, SwiftUI!")
                      .font(.title)
                      .foregroundColor(.blue)
              }
          }
          ```
          
          It replaces UIKit and AppKit with a more modern, Swift-first approach to UI development.
          """
          ),
          Message.State(
            id: UUID(),
            role: .user,
            content: "How do I create a list?"
          ),
          Message.State(
            id: UUID(),
            role: .assistant,
            content: """
          Creating a list in SwiftUI is straightforward using the `List` view:
          
          ```swift
          struct FruitList: View {
              let fruits = ["Apple", "Banana", "Orange"]
              
              var body: some View {
                  List(fruits, id: \\.self) { fruit in
                      Text(fruit)
                  }
              }
          }
          ```
          
          You can also use `ForEach` for more control over the list items.
          """,
            sources: [
              WebSource(
                title: "Apple Developer Documentation",
                url: "https://developer.apple.com/documentation/swiftui/list",
                preview: "A container that presents rows of data arranged in a single column, optionally providing the ability to select one or more members."
              )
            ]
          )
        ]
        
        return state
      }()) {
        Chat()
      }
    )
  }
}
