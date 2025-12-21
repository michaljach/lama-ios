//
//  WebSearchSourcesView.swift
//  lama
//
//  Created by Michal Jach on 21/12/2025.
//

import SwiftUI

struct WebSearchSourcesView: View {
  let sources: [WebSearchSource]
  @State private var isShowingAllSources = false
  
  var body: some View {
    Button {
      isShowingAllSources = true
    } label: {
      HStack(alignment: .center) {
        HStack(spacing: 4) {
          Image(systemName: "globe")
            .font(.caption)
            .foregroundStyle(.secondary)
          Text("Sources:")
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
        }
        .foregroundStyle(.colorForeground)
        .padding(.leading, 16)
        
        // Favicon icons row
        HStack(spacing: -4) {
          ForEach(sources) { source in
            AsyncImage(url: faviconURL(for: source.url)) { image in
              image
                .resizable()
                .scaledToFit()
            } placeholder: {
              Image(systemName: "globe")
                .font(.caption)
                .foregroundColor(.gray)
            }
            .frame(width: 16, height: 16)
            .clipShape(RoundedRectangle(cornerRadius: 6))
          }
          
          Spacer()
        }
        .padding(.trailing, 16)
        .padding(.vertical, 12)
      }
      .background(Color.colorGray)
      .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    .padding(.horizontal, 16)
    .sheet(isPresented: $isShowingAllSources) {
      WebSearchSourcesListView(sources: sources)
    }
  }
  
  private func faviconURL(for urlString: String) -> URL? {
    guard let url = URL(string: urlString),
          let domain = url.host else { return nil }
    
    return URL(string: "https://icons.duckduckgo.com/ip3/\(domain).ico")
  }
}

struct WebSearchSourcesListView: View {
  let sources: [WebSearchSource]
  @Environment(\.dismiss) var dismiss
  
  var body: some View {
    NavigationStack {
      List {
        ForEach(sources) { source in
          WebSearchSourceRow(source: source)
        }
      }
      .navigationTitle("Sources")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button(action: { dismiss() }) {
            Image(systemName: "xmark")
              .font(.system(size: 16, weight: .semibold))
              .foregroundStyle(.colorForeground)
          }
        }
      }
    }
  }
}

struct WebSearchSourceRow: View {
  let source: WebSearchSource
  
  var body: some View {
    NavigationLink(destination: WebSearchDetailView(source: source)) {
      HStack(spacing: 12) {
        // Favicon
        AsyncImage(url: faviconURL(for: source.url)) { image in
          image
            .resizable()
            .scaledToFit()
        } placeholder: {
          Image(systemName: "globe")
            .font(.caption)
            .foregroundColor(.gray)
        }
        .frame(width: 24, height: 24)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        
        // Title and URL
        VStack(alignment: .leading, spacing: 4) {
          Text(source.title)
            .font(.subheadline)
            .fontWeight(.semibold)
            .lineLimit(2)
          
          Text(source.url)
            .font(.caption2)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
      }
      .padding(.vertical, 4)
    }
  }
  
  private func faviconURL(for urlString: String) -> URL? {
    guard let url = URL(string: urlString),
          let domain = url.host else { return nil }
    
    return URL(string: "https://icons.duckduckgo.com/ip3/\(domain).ico")
  }
}

struct WebSearchDetailView: View {
  let source: WebSearchSource
  @Environment(\.dismiss) var dismiss
  
  var body: some View {
    NavigationStack {
      VStack(alignment: .leading, spacing: 16) {
        // Title
        Text(source.title)
          .font(.headline)
          .fontWeight(.semibold)
        
        // URL
        Link(destination: URL(string: source.url) ?? URL(fileURLWithPath: "")) {
          HStack(spacing: 4) {
            Image(systemName: "link")
              .font(.caption)
            Text(source.url)
              .font(.caption)
              .lineLimit(1)
          }
          .foregroundColor(.colorBlue)
          .underline()
        }
        
        Divider()
        
        // Content
        VStack(alignment: .leading, spacing: 4) {
          Text("Preview")
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
          
          Text(source.content)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(nil)
        }
        
        Spacer()
      }
      .padding(16)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button(action: { dismiss() }) {
            Image(systemName: "xmark")
              .font(.system(size: 16, weight: .semibold))
              .foregroundStyle(.colorForeground)
          }
        }
      }
    }
  }
}

#Preview {
  VStack {
    WebSearchSourcesView(sources: [
      WebSearchSource(
        title: "Example Article",
        url: "https://www.bbc.com",
        content: "This is a preview of the web search result content."
      ),
      WebSearchSource(
        title: "Another Source",
        url: "https://www.theguardian.com",
        content: "More information from another source."
      )
    ])
    
    Spacer()
  }
  .padding()
  .background(Color(.systemBackground))
}

