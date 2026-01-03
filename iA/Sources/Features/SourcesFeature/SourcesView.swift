//
//  SourcesView.swift
//  iA
//
//  Created by Michal Jach on 02/01/2026.
//

import ComposableArchitecture
import SwiftUI

// Compact sources bar component
struct SourcesBarView: View {
  let sources: [WebSource]
  let onTap: () -> Void
  
  var body: some View {
    Button(action: onTap) {
      HStack {
        Image(systemName: "globe")
          .font(.subheadline)
          .foregroundColor(.secondary)
        
        Text("\(sources.count) source\(sources.count == 1 ? "" : "s")")
          .font(.caption)
          .foregroundColor(.secondary)
        
        // Show favicons for first few sources
        HStack(spacing: -4) {
          ForEach(sources.prefix(10)) { source in
            FaviconView(url: source.url)
          }
        }
        
        Spacer()
        
        Image(systemName: "chevron.right")
          .font(.caption2)
          .foregroundColor(.secondary)
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
      .background(Color.colorGray)
      .cornerRadius(8)
    }
    .buttonStyle(.plain)
  }
}

// Favicon view - loads favicon from URL using Google's favicon service
struct FaviconView: View {
  let url: String
  
  @State private var actualDomain: String?
  @State private var isResolvingDomain = false
  
  private var faviconURL: URL? {
    guard let domain = actualDomain else {
      return nil
    }
    let faviconURLString = "https://www.google.com/s2/favicons?domain=\(domain)&sz=64"
    return URL(string: faviconURLString)
  }
  
  var body: some View {
    ZStack {
      if let faviconURL = faviconURL {
        AsyncImage(url: faviconURL) { phase in
          switch phase {
          case .success(let image):
            image
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: 20, height: 20)
          case .failure:
            Image(systemName: "globe")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: 12, height: 12)
              .foregroundColor(.secondary)
          case .empty:
            ProgressView()
              .scaleEffect(0.5)
          @unknown default:
            Image(systemName: "globe")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: 12, height: 12)
              .foregroundColor(.secondary)
          }
        }
        .clipShape(Circle())
      } else if isResolvingDomain {
        ProgressView()
          .scaleEffect(0.5)
      } else {
        Image(systemName: "globe")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: 12, height: 12)
          .foregroundColor(.secondary)
      }
    }
    .frame(width: 20, height: 20)
    .task {
      await resolveDomain()
    }
  }
  
  private func resolveDomain() async {
    guard actualDomain == nil, !isResolvingDomain else { return }
    
    isResolvingDomain = true
    defer { isResolvingDomain = false }
    
    // First try to extract domain directly
    if let baseURL = URL(string: url),
       let host = baseURL.host,
       !host.contains("vertexaisearch.cloud.google.com") {
      actualDomain = host
      return
    }
    
    // If it's a Google redirect URL, follow it to get actual domain
    guard let redirectURL = URL(string: url),
          redirectURL.host?.contains("vertexaisearch.cloud.google.com") == true else {
      actualDomain = "google.com" // Fallback
      return
    }
    
    
    do {
      var request = URLRequest(url: redirectURL)
      request.httpMethod = "HEAD"
      request.timeoutInterval = 5
      
      let (_, response) = try await URLSession.shared.data(for: request)
      
      if let httpResponse = response as? HTTPURLResponse,
         let location = httpResponse.value(forHTTPHeaderField: "Location") ?? httpResponse.url?.absoluteString,
         let actualURL = URL(string: location),
         let host = actualURL.host {
        let cleanHost = host.replacingOccurrences(of: "www.", with: "")
        actualDomain = cleanHost
      } else {
        actualDomain = "google.com"
      }
    } catch {
      actualDomain = "google.com"
    }
  }
}

// Sources detail sheet
struct SourcesDetailSheet: View {
  @Bindable var store: StoreOf<Sources>
  @Environment(\.dismiss) var dismiss
  
  var body: some View {
    NavigationStack {
      List {
        ForEach(store.sources) { source in
          Link(destination: URL(string: source.url)!) {
            HStack(spacing: 12) {
              FaviconView(url: source.url)
              
              VStack(alignment: .leading, spacing: 4) {
                Text(source.title)
                  .font(.body)
                  .foregroundColor(.primary)
                  .lineLimit(2)
                
                if let preview = source.preview {
                  Text(preview)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                }
              }
              
              Spacer()
              
              Image(systemName: "arrow.up.right")
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
          }
        }
      }
      .navigationTitle("Sources")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button(action: { dismiss() }) {
            Image(systemName: "xmark")
              .font(.body.weight(.medium))
              .foregroundColor(.secondary)
          }
        }
      }
      .interactiveDismissDisabled(false)
    }
    .presentationDragIndicator(.visible)
  }
}

#Preview {
  SourcesBarView(sources: [WebSource(title: "Test", url: "")]) {}
  
  SourcesDetailSheet(
    store: Store(initialState: Sources.State(
      sources: [
        WebSource(title: "Apple - Official Site", url: "https://www.apple.com"),
        WebSource(title: "Wikipedia - The Free Encyclopedia", url: "https://wikipedia.org"),
        WebSource(title: "GitHub - Where the world builds software", url: "https://github.com")
      ]
    )) {
      Sources()
    }
  )
}
