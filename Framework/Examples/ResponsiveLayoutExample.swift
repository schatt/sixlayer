import SwiftUI
import SixLayerFramework

// Moved from Framework/Sources (#469). Copy-paste samples; not compiled into the framework.

// MARK: - Example Usage
public struct ResponsiveLayoutExample: View {
    let gridItems = [
        GridItemData(title: "Item 1", subtitle: "Description 1", icon: "star.fill", color: .blue),
        GridItemData(title: "Item 2", subtitle: "Description 2", icon: "heart.fill", color: .red),
        GridItemData(title: "Item 3", subtitle: "Description 3", icon: "circle.fill", color: .green)
    ]

    public var body: some View {
        ResponsiveLayout.adaptiveGrid {
            ForEach(gridItems) { item in
                VStack {
                    Image(systemName: item.icon)
                        .foregroundColor(item.color)
                    Text(item.title)
                        .font(.headline)
                    Text(item.subtitle)
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 100)

                .cornerRadius(8)
            }
        }
        .automaticCompliance(named: "ResponsiveLayoutExample")
    }
}

// MARK: - Example Navigation
public struct ResponsiveNavigationExample: View {
    public var body: some View {
        ResponsiveNavigation { isHorizontal in
            if isHorizontal {
                NavigationView {
                    List {
                        Text("Sidebar Item 1")
                        Text("Sidebar Item 2")
                    }
                    #if os(iOS) || os(macOS)
                    .listStyle(SidebarListStyle())
                    #else
                    .listStyle(.plain)
                    #endif
                }
                .frame(minWidth: 160, maxWidth: 240)
            } else {
                TabView {
                    Text("Tab 1")
                        .tabItem { Label("First", systemImage: "1.circle") }
                    Text("Tab 2")
                        .tabItem { Label("Second", systemImage: "2.circle") }
                }
            }
        }
        .automaticCompliance(named: "ResponsiveNavigationExample")
    }
}
