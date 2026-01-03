//
//  SourcesView.swift
//  iA
//
//  Created by Michal Jach on 02/01/2026.
//

import ComposableArchitecture
import SwiftUI
import MarkdownUI

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
  
  private var faviconURL: URL? {
    guard let baseURL = URL(string: url),
          let host = baseURL.host else {
      return nil
    }
    let faviconURLString = "https://www.google.com/s2/favicons?domain=\(host)&sz=64"
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
      } else {
        Image(systemName: "globe")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: 12, height: 12)
          .foregroundColor(.secondary)
      }
    }
    .frame(width: 20, height: 20)
  }
}

// Source detail view showing full content in markdown
struct SourceDetailView: View {
  let source: WebSource
  
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        // Title section
        VStack(alignment: .leading, spacing: 8) {
          HStack(spacing: 12) {
            FaviconView(url: source.url)
            
            Text(source.title)
              .font(.title3)
              .fontWeight(.semibold)
          }
          
          Link(destination: URL(string: source.url)!) {
            HStack(spacing: 4) {
              Text(source.url)
                .font(.caption)
                .foregroundColor(.blue)
                .lineLimit(1)
              
              Image(systemName: "arrow.up.right")
                .font(.caption2)
                .foregroundColor(.blue)
            }
          }
        }
        .padding(.horizontal)
        .padding(.top)
        
        Divider()
        
        // Content section
        if let preview = source.preview {
          VStack(alignment: .leading, spacing: 8) {
            Text("Search Result")
              .font(.headline)
              .foregroundColor(.secondary)
            
            Markdown(preview)
              .textSelection(.enabled)
              .markdownTextStyle(\.text) {
                ForegroundColor(.colorForeground)
              }
              .markdownTextStyle(\.code) {
                FontFamilyVariant(.monospaced)
                BackgroundColor(Color.colorForeground.opacity(0.08))
              }
              .markdownBlockStyle(\.codeBlock) { configuration in
                configuration.label
                  .padding()
                  .background(Color.colorForeground.opacity(0.08))
                  .cornerRadius(8)
              }
              .markdownTableBorderStyle(
                .init(
                  .horizontalBorders,
                  color: .colorGray,
                  strokeStyle: .init(lineWidth: 1)
                )
              )
              .markdownTableBackgroundStyle(
                .alternatingRows(Color.clear, Color.clear)
              )
          }
          .padding(.horizontal)
        } else {
          Text("No preview available")
            .font(.body)
            .foregroundColor(.secondary)
            .padding(.horizontal)
        }
        
        Spacer()
      }
    }
    .navigationTitle("Source Detail")
    .navigationBarTitleDisplayMode(.inline)
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
          NavigationLink {
            SourceDetailView(source: source)
          } label: {
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
  
  SourceDetailView(
    source: WebSource(
      title: "Apple - Official Site",
      url: "https://www.apple.com",
      preview: "Apple is a technology company known for iPhone, iPad, and Mac products. Founded in 1976, it has become one of the most valuable companies in the world."
    )
  )
  
  SourcesDetailSheet(
    store: Store(initialState: Sources.State(
      sources: [
        WebSource(
          title: "Apple - Official Site", 
          url: "https://www.apple.com",
          preview: "Apple is a technology company known for iPhone, iPad, and Mac products"
        ),
        WebSource(
          title: "Wikipedia - The Free Encyclopedia", 
          url: "https://wikipedia.org",
          preview: "Wikipedia is a free online encyclopedia with millions of articles"
        ),
        WebSource(
          title: "GitHub - Where the world builds software", 
          url: "https://github.com",
          preview: "GitHub is a platform for version control and collaboration"
        )
      ]
    )) {
      Sources()
    }
  )
}
