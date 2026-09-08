# Usage Examples for 6-Layer Architecture

## Overview

This document provides comprehensive examples of how to use the 6-layer architecture for platform extensions effectively.

## 🏗️ Complete 6-Layer Flow

### **Full Stack Implementation**
```swift
// Layer 1: Express intent
.platformResponsiveCard(
    type: .dashboard,
    content: { 
        // Card content
    }
)

// Layer 2: Decision engine analyzes content and context
// Layer 3: Strategy selection chooses optimal layout approach
// Layer 4: Implementation builds the card components
// Layer 5: Performance optimizations applied
// Layer 6: Platform-specific enhancements applied
```

### **Step-by-Step Breakdown**
```swift
// 1. Express semantic intent
let cardIntent = CardIntent(
    type: .dashboard,
    content: dashboardItems,
    priority: .high
)

// 2. Analyze and decide layout
let layoutDecision = determineOptimalFormLayout(
    fieldCount: dashboardItems.count,
    complexity: .moderate,
    deviceType: .macOS,
    screenSize: screenSize
)

// 3. Select optimal strategy
let strategy = selectCardLayoutStrategy(
    contentCount: dashboardItems.count,
    screenWidth: screenWidth,
    deviceType: .macOS,
    contentComplexity: .moderate
)

// 4. Implement the component
.platformCardGrid(
    columns: strategy.columns,
    spacing: strategy.spacing
) {
    ForEach(dashboardItems) { item in
        DashboardCard(item: item)
    }
}

// 5. Apply performance optimizations

// 6. Apply platform-specific enhancements
#if os(macOS)
.platformMacOSWindowResizing(resizable: true)
#endif
```

## 🎯 Direct Layer Usage

### **Layer 1: NavigationStack Semantic Intent**
```swift
// Express navigation intent - framework handles everything
platformPresentNavigationStack_L1(
    content: MyContentView(),
    title: "Settings",
    hints: PresentationHints(
        dataType: .navigation,
        presentationPreference: .navigation,
        complexity: .simple,
        context: .navigation
    )
)

// Navigation with items - automatic list-detail pattern
platformPresentNavigationStack_L1(
    items: items,
    hints: PresentationHints(
        dataType: .navigation,
        presentationPreference: .navigation,
        complexity: .moderate,
        context: .browse
    )
) { item in
    ItemRow(item: item)
} destination: { item in
    ItemDetailView(item: item)
}
```

**See [NavigationStackGuide.md](NavigationStackGuide.md) for complete NavigationStack documentation.**

### **Layer 1: Semantic Intent Only**
```swift
// Use semantic functions for high-level intent
.platformPresentForm(
    type: .dataEntry,
    complexity: .moderate,
    style: .standard
) {
    DataFormView()
}
```

### **Layer 4: Direct Component Usage**
```swift
// Use Layer 4 directly for specific components
.platformCardGrid(
    columns: 3,
    spacing: 16
) {
    ForEach(items) { item in
    ItemCard(item: item)
}
}
```

### **Layer 6: Platform-Specific Features**
```swift
// Apply platform-specific optimizations directly
#if os(iOS)
.platformIOSHapticFeedback(style: .medium)
#elseif os(macOS)
.platformMacOSWindowResizing(resizable: true)
#endif
```

## 🔄 Progressive Enhancement Patterns

### **Basic to Advanced**
```swift
// Start with basic Layer 4 implementation
.platformCardList(spacing: 16) {
    ForEach(items) { item in
        ItemCard(item: item)
    }
}

// Enhance with Layer 5 performance optimizations
.platformCardList(spacing: 16) {
    ForEach(items) { item in
        ItemCard(item: item)
    }
}

// Add Layer 6 platform enhancements
.platformCardList(spacing: 16) {
    ForEach(items) { item in
        ItemCard(item: item)
    }
}
#if os(iOS)
.platformIOSHapticFeedback(style: .light)
#endif
```

### **Conditional Enhancement**
```swift
// Base component
let baseComponent = platformCardGrid(
    columns: 2,
    spacing: 16
) {
    ForEach(items) { item in
        ItemCard(item: item)
    }
}

// Conditional enhancements based on device capabilities
if deviceSupportsAdvancedFeatures {
    return baseComponent
} else {
    return baseComponent
}
```

## 📱 Platform-Specific Examples

### **iOS-Specific Implementation**
```swift
#if os(iOS)
VStack {
    // iOS-specific navigation
    .platformIOSNavigationBar(
        title: "Item Details",
        displayMode: .large
    )
    
    // Content with iOS optimizations
    ItemDetailView(item: item)
        .platformIOSHapticFeedback(style: .medium)
        .platformIOSSwipeGestures(
            onSwipeLeft: { /* handle swipe */ },
            onSwipeRight: { /* handle swipe */ }
        )
}
#endif
```

### **macOS-Specific Implementation**
```swift
#if os(macOS)
VStack {
    // macOS-specific navigation
    .platformMacOSNavigation(
        title: "Item Details",
        subtitle: item.name + " " + item.description
    )
    
    // Content with macOS optimizations
    ItemDetailView(item: item)
        .platformMacOSWindowResizing(resizable: true)
        .platformMacOSWindowSizing(
            minWidth: 800,
            minHeight: 600,
            idealWidth: 1200,
            idealHeight: 800
        )
}
#endif
```

## 🎨 Form Implementation Examples

### **Simple Form**
```swift
.platformPresentForm(
    type: .itemCreation,
    complexity: .simple,
    style: .standard
) {
    VStack(spacing: 16) {
        .platformFormSection(title: "Basic Information") {
            .platformFormField(label: "Name") {
                TextField("Name", text: $name)
            }
            .platformFormField(label: "Description") {
                TextField("Description", text: $description)
            }
        }
        
        .platformFormSection(title: "Details") {
            .platformFormField(label: "Category") {
                TextField("Category", text: $category)
            }
        }
    }
}
```

### **Complex Form with Validation**
```swift
.platformPresentForm(
    type: .dataEntry,
    complexity: .complex,
    style: .detailed
) {
    VStack(spacing: 20) {
        // Basic information
        .platformFormSection(title: "Data Details") {
            .platformFormField(label: "Title") {
                TextField("Expense title", text: $title)
            }
            .platformFormField(label: "Amount") {
                TextField("Amount", text: $amount)
                    .keyboardType(.decimalPad)
            }
            .platformFormField(label: "Date") {
                DatePicker("Date", selection: $date, displayedComponents: .date)
            }
        }
        
        // Category selection
        .platformFormSection(title: "Category") {
            .platformFormField(label: "Category") {
                Picker("Category", selection: $selectedCategory) {
                    ForEach(categories) { category in
                        Text(category.name).tag(category)
                    }
                }
            }
        }
        
        // Notes
        .platformFormSection(title: "Additional Information") {
            .platformFormField(label: "Notes") {
                TextEditor(text: $notes)
                    .frame(height: 100)
            }
        }
        
        // Validation messages
        if !validationErrors.isEmpty {
            .platformValidationMessage(
                message: validationErrors.joined(separator: "\n"),
                type: .error
            )
        }
    }
}
```

## 🎯 Responsive Card Examples

### **Dashboard Grid**
```swift
.platformResponsiveCard(type: .dashboard) {
    .platformCardGrid(
        columns: 3,
        spacing: 16
    ) {
        ForEach(dashboardItems) { item in
            DashboardCard(item: item)
                .platformCardStyle(
                    backgroundColor: .systemBackground,
                    cornerRadius: 12,
                    shadowRadius: 4
                )
        }
    }
}
```

### **Masonry Layout**
```swift
.platformResponsiveCard(type: .gallery) {
    .platformCardMasonry(
        columns: 4,
        spacing: 12
    ) {
        ForEach(photos) { photo in
            PhotoCard(photo: photo)
                .platformCardStyle(
                    backgroundColor: .clear,
                    cornerRadius: 8,
                    shadowRadius: 2
                )
        }
    }
}
```

### **Adaptive Layout**
```swift
.platformResponsiveCard(type: .content) {
    .platformCardAdaptive(
        minWidth: 300,
        maxWidth: 600
    ) {
        ForEach(contentItems) { item in
            ContentCard(item: item)
                .platformCardPadding()
        }
    }
}
```

## 🔧 Performance Optimization Examples

### **Memory Optimization**
```swift
// Apply memory optimization to heavy views
LazyVStack {
    ForEach(largeDataSet) { item in
        HeavyItemView(item: item)
    }
}
```

### **Rendering Optimization**
```swift
// Optimize rendering for complex views
ComplexChartView(data: chartData)
```

### **Combined Optimizations**
```swift
// Apply multiple optimizations
DataGridView(data: gridData)
```

## 📚 Best Practices

### **1. Start with Semantic Intent**
Always begin with Layer 1 to express what you want to achieve.

### **2. Use Progressive Enhancement**
Start with basic implementation and add layers as needed.

### **3. Consider Platform Differences**
Use Layer 6 to enhance the native feel of each platform.

### **4. Monitor Performance**
Use Layer 5 optimizations judiciously and measure their impact.

### **5. Keep It Simple**
Don't over-engineer - use only the layers you need.

### **6. Test on Real Devices**
Performance characteristics vary significantly between devices.

## 🚀 Advanced Patterns

### **Custom Layer Composition**
```swift
// Create custom layer combinations
extension View {
    func platformOptimizedCard<Content: View>(
        type: CardType,
        @ViewBuilder content: () -> Content
    ) -> some View {
        self
            .platformResponsiveCard(type: type, content: content)
    }
}
```

### **Conditional Layer Application**
```swift
// Apply layers conditionally
func applyOptimizations<Content: View>(
    to view: Content,
    includePerformance: Bool = true,
    includePlatform: Bool = true
) -> some View {
    var result = view
    
    if includePerformance {
        result = result
    }
    
    if includePlatform {
        #if os(iOS)
        result = result.platformIOSHapticFeedback(style: .light)
        #elseif os(macOS)
        result = result.platformMacOSWindowResizing(resizable: true)
        #endif
    }
    
    return result
}
```

## 🔧 File System Utilities Examples

### **Basic Directory Access**

```swift
// Application Support directory
guard let appSupport = platformApplicationSupportDirectory() else {
    print("Could not locate Application Support directory")
    return
}

// Documents directory
guard let documentsURL = platformDocumentsDirectory() else {
    print("Could not locate Documents directory")
    return
}
```

### **Directory Access with Creation**

```swift
// Create Application Support directory if it doesn't exist
guard let appSupport = platformApplicationSupportDirectory(createIfNeeded: true) else {
    print("Failed to create or locate Application Support directory")
    return
}

// Create Documents directory if it doesn't exist
guard let documentsURL = platformDocumentsDirectory(createIfNeeded: true) else {
    print("Failed to create or locate Documents directory")
    return
}
```

### **Core Data Store Location**

```swift
// Store Core Data in Application Support directory
guard let appSupport = platformApplicationSupportDirectory(createIfNeeded: true) else {
    fatalError("Could not set up Application Support directory")
}

let storeURL = appSupport.appendingPathComponent("MyApp.sqlite")
// Use storeURL for Core Data persistent store
```

### **File Storage**

```swift
// Save file to Documents directory
guard let documentsURL = platformDocumentsDirectory(createIfNeeded: true) else {
    print("Could not access Documents directory")
    return
}

let fileURL = documentsURL.appendingPathComponent("data.json")
try data.write(to: fileURL)
```

### **ML Model Storage**

```swift
// Store ML model in Application Support directory
guard let appSupport = platformApplicationSupportDirectory(createIfNeeded: true) else {
    print("Could not set up Application Support directory for ML models")
    return
}

let modelURL = appSupport.appendingPathComponent("MyModel.mlmodel")
// Load or save ML model at modelURL
```

### **Error Handling Pattern**

```swift
func setupApplicationDirectories() -> Bool {
    // Ensure Application Support directory exists
    guard platformApplicationSupportDirectory(createIfNeeded: true) != nil else {
        print("Failed to set up Application Support directory")
        return false
    }
    
    // Ensure Documents directory exists
    guard platformDocumentsDirectory(createIfNeeded: true) != nil else {
        print("Failed to set up Documents directory")
        return false
    }
    
    return true
}
```

### **Home Directory (Existing Utility)**

```swift
// Get home directory (non-optional, always available)
let homeDir = platformHomeDirectory()
print("Home directory: \(homeDir.path)")
```

## 📚 Related Documentation

- **Architecture Overview:** [README_6LayerArchitecture.md](README_6LayerArchitecture.md)
- **Layer 1:** [README_Layer1_Semantic.md](README_Layer1_Semantic.md)
- **Layer 2:** [README_Layer2_Decision.md](README_Layer2_Decision.md)
- **Layer 3:** [README_Layer3_Strategy.md](README_Layer3_Strategy.md)
- **Layer 4:** [README_Layer4_Implementation.md](README_Layer4_Implementation.md)
- **Layer 5:** [README_Layer5_Performance.md](README_Layer5_Performance.md)
- **Layer 6:** [README_Layer6_Platform.md](README_Layer6_Platform.md)
