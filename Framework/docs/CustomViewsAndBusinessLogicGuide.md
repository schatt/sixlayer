# Custom Views & Business Logic Integration Guide

## Overview

This guide shows how to create custom views and business logic extensions that integrate seamlessly with the SixLayer Framework's 6-layer architecture. You'll learn how to leverage the framework's intelligent platform adaptation and performance optimization while building business-specific functionality.

## Table of Contents

1. [Quick Start](#quick-start)
2. [Custom Views Integration](#custom-views-integration)
3. [Business Logic Extension Patterns](#business-logic-extension-patterns)
4. [6-Layer Architecture Integration](#6-layer-architecture-integration)
5. [Project-Level Extension Architecture](#project-level-extension-architecture)
6. [Real-World Examples](#real-world-examples)
7. [Best Practices](#best-practices)
8. [Troubleshooting](#troubleshooting)

## Quick Start

### 1. Import the Framework

```swift
import SixLayerFramework
```

### 2. Create Your First Custom View

```swift
struct MyBusinessView: View {
    let businessData: [MyBusinessItem]
    
    var body: some View {
        // Use framework functions to present your data
        platformPresentItemCollection_L1(
            items: businessData,
            hints: createBusinessHints()
        )
    }
    
    private func createBusinessHints() -> EnhancedPresentationHints {
        let businessHint = CustomHint(
            hintType: "myapp.business",
            priority: .high,
            customData: [
                "businessType": "inventory",
                "showAdvancedMetrics": true,
                "layoutStyle": "adaptive"
            ]
        )
        
        return EnhancedPresentationHints(
            dataType: .collection,
            presentationPreference: .automatic,
            complexity: .moderate,
            context: .dashboard,
            extensibleHints: [businessHint]
        )
    }
}
```

### 3. The Framework Handles the Rest

- **Automatic Layout**: Framework analyzes your data and hints to determine optimal presentation
- **Platform Adaptation**: Views automatically adapt to iOS/macOS conventions
- **Performance Optimization**: Framework applies memory and rendering optimizations
- **Responsive Behavior**: Views respond to screen size and device capabilities

## Custom Views Integration

### Basic Custom View Pattern

```swift
struct MyCustomView: View {
    let data: [MyData]
    @State private var selectedItem: MyData?
    
    var body: some View {
        VStack(spacing: 16) {
            // Your custom business logic
            CustomHeaderView()
            
            // Use framework components for consistency
            platformCardGrid(columns: 2, spacing: 12) {
                ForEach(data) { item in
                    MyCustomCard(item: item)
                        .onTapGesture {
                            selectedItem = item
                        }
                }
            }
            
            // Custom business actions
            CustomActionButtons(selectedItem: selectedItem)
        }
        // Apply framework optimizations
    }
}
```

### Custom View with Framework Integration

```swift
struct MyBusinessDashboard: View {
    let businessData: BusinessData
    
    var body: some View {
        // Layer 1: Semantic Intent
        platformPresentItemCollection_L1(
            items: businessData.items,
            hints: createBusinessHints(),
            customItemView: { item in
                MyBusinessItemView(item: item)
            }
        )
        // Layer 5: Performance Optimization
        // Layer 6: Platform-Specific Features
        #if os(iOS)
        .platformIOSHapticFeedback(style: .medium) {
            // Haptic feedback on interactions
        }
        #elseif os(macOS)
        .platformMacOSWindowSizing(
            minWidth: 800,
            minHeight: 600
        )
        #endif
    }
    
    private func createBusinessHints() -> EnhancedPresentationHints {
        let businessHint = CustomHint(
            hintType: "myapp.dashboard",
            priority: .high,
            customData: [
                "businessType": "inventory",
                "showMetrics": true,
                "refreshInterval": 30
            ]
        )
        
        return EnhancedPresentationHints(
            dataType: .collection,
            presentationPreference: .automatic,
            complexity: .moderate,
            context: .dashboard,
            extensibleHints: [businessHint]
        )
    }
}
```

## Business Logic Extension Patterns

### 1. Custom Hints for Business Logic

```swift
// Create business-specific hints
class InventoryHint: CustomHint {
    init(showAdvancedMetrics: Bool = false, refreshInterval: Int = 30) {
        super.init(
            hintType: "inventory.management",
            priority: .high,
            overridesDefault: false,
            customData: [
                "showAdvancedMetrics": showAdvancedMetrics,
                "refreshInterval": refreshInterval,
                "businessType": "inventory",
                "layoutStyle": "adaptive",
                "showQuickActions": true
            ]
        )
    }
}

class CustomerHint: CustomHint {
    init(showContactInfo: Bool = true, showOrderHistory: Bool = true) {
        super.init(
            hintType: "customer.management",
            priority: .normal,
            customData: [
                "showContactInfo": showContactInfo,
                "showOrderHistory": showOrderHistory,
                "businessType": "customer",
                "layoutStyle": "detailed"
            ]
        )
    }
}
```

### 2. Business Logic Factories

```swift
extension EnhancedPresentationHints {
    /// Create hints optimized for inventory management
    static func forInventory(
        showAdvancedMetrics: Bool = false,
        refreshInterval: Int = 30
    ) -> EnhancedPresentationHints {
        let inventoryHint = InventoryHint(
            showAdvancedMetrics: showAdvancedMetrics,
            refreshInterval: refreshInterval
        )
        
        return EnhancedPresentationHints(
            dataType: .collection,
            presentationPreference: .automatic,
            complexity: .moderate,
            context: .dashboard,
            extensibleHints: [inventoryHint]
        )
    }
    
    /// Create hints optimized for customer management
    static func forCustomers(
        showContactInfo: Bool = true,
        showOrderHistory: Bool = true
    ) -> EnhancedPresentationHints {
        let customerHint = CustomerHint(
            showContactInfo: showContactInfo,
            showOrderHistory: showOrderHistory
        )
        
        return EnhancedPresentationHints(
            dataType: .collection,
            presentationPreference: .list,
            complexity: .moderate,
            context: .browse,
            extensibleHints: [customerHint]
        )
    }
}
```

### 3. Business-Specific View Extensions

```swift
extension View {
    /// Custom form section for business data
    func businessFormSection<Content: View>(
        title: String,
        businessType: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(businessType.uppercased())
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
            }
            
            content()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    /// Custom business card style
    func businessCardStyle(
        businessType: String,
        priority: BusinessPriority = .normal
    ) -> some View {
        self
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(priority.color, lineWidth: 2)
            )
            .shadow(radius: 2)
    }
}

enum BusinessPriority {
    case low, normal, high, critical
    
    var color: Color {
        switch self {
        case .low: return .green
        case .normal: return .blue
        case .high: return .orange
        case .critical: return .red
        }
    }
}
```

## 6-Layer Architecture Integration

### Complete 6-Layer Integration Example

```swift
struct MyBusinessView: View {
    let businessData: [BusinessItem]
    @State private var selectedStrategy: String = ""
    
    var body: some View {
        VStack {
            // Layer 1: Semantic Intent
            platformPresentItemCollection_L1(
                items: businessData,
                hints: createBusinessHints()
            )
        }
        .onAppear {
            // Layer 2: Layout Decision
            let decision = determineOptimalCardLayout_L2(
                cardCount: businessData.count,
                screenWidth: UIScreen.main.bounds.width,
                screenHeight: UIScreen.main.bounds.height,
                deviceType: .current
            )
            
            // Layer 3: Strategy Selection
            let strategy = selectCardLayoutStrategy_L3(
                contentCount: businessData.count,
                screenWidth: UIScreen.main.bounds.width,
                deviceType: .current,
                contentComplexity: .moderate
            )
            
            selectedStrategy = strategy.strategy.rawValue
        }
        // Layer 4: Component Implementation (handled by framework)
        // Layer 5: Performance Optimization
        // Layer 6: Platform-Specific Features
        #if os(iOS)
        .platformIOSHapticFeedback(style: .medium) {
            // Haptic feedback
        }
        .platformIOSSwipeGestures(
            onSwipeLeft: { /* Custom business logic */ },
            onSwipeRight: { /* Custom business logic */ }
        )
        #elseif os(macOS)
        .platformMacOSWindowSizing(
            minWidth: 800,
            minHeight: 600,
            idealWidth: 1200,
            idealHeight: 800
        )
        .platformMacOSToolbar {
            // Custom toolbar for business actions
        }
        #endif
    }
    
    private func createBusinessHints() -> EnhancedPresentationHints {
        let businessHint = CustomHint(
            hintType: "myapp.business",
            priority: .high,
            customData: [
                "businessType": "inventory",
                "showAdvancedMetrics": true,
                "layoutStyle": "adaptive"
            ]
        )
        
        return EnhancedPresentationHints(
            dataType: .collection,
            presentationPreference: .automatic,
            complexity: .moderate,
            context: .dashboard,
            extensibleHints: [businessHint]
        )
    }
}
```

### Layer-by-Layer Integration

```swift
struct MyCustomForm: View {
    @State private var formData = FormData()
    
    var body: some View {
        VStack(spacing: 20) {
            // Layer 1: Semantic Intent
            platformPresentFormData_L1(
                fields: createFormFields(),
                hints: createFormHints()
            )
        }
        // Layer 5: Performance Optimization
        // Layer 6: Platform-Specific Features
        #if os(iOS)
        .platformIOSNavigationBar(
            title: "Business Form",
            displayMode: .large
        )
        #elseif os(macOS)
        .platformMacOSWindowSizing(
            minWidth: 600,
            minHeight: 400
        )
        #endif
    }
    
    private func createFormFields() -> [GenericFormField] {
        return [
            GenericFormField(
                label: "Business Name",
                placeholder: "Enter business name",
                value: .constant(formData.businessName),
                fieldType: .text
            ),
            GenericFormField(
                label: "Industry",
                placeholder: "Select industry",
                value: .constant(formData.industry),
                fieldType: .select
            )
        ]
    }
    
    private func createFormHints() -> EnhancedPresentationHints {
        let formHint = CustomHint(
            hintType: "myapp.business.form",
            priority: .high,
            customData: [
                "businessType": "registration",
                "showValidation": true,
                "multiStep": true
            ]
        )
        
        return EnhancedPresentationHints(
            dataType: .form,
            presentationPreference: .form,
            complexity: .moderate,
            context: .create,
            extensibleHints: [formHint]
        )
    }
}
```

## Project-Level Extension Architecture

### 1. Project Structure

```
MyProject/
├── Sources/
│   ├── Shared/
│   │   ├── Views/
│   │   │   ├── Business/
│   │   │   │   ├── InventoryView.swift
│   │   │   │   ├── CustomerView.swift
│   │   │   │   └── OrderView.swift
│   │   │   └── Extensions/
│   │   │       ├── BusinessViewExtensions.swift
│   │   │       └── BusinessHints.swift
│   │   └── Models/
│   │       ├── BusinessData.swift
│   │       └── BusinessHints.swift
│   ├── iOS/
│   │   └── Views/
│   │       └── Business/
│   │           └── iOSBusinessViews.swift
│   └── macOS/
│       └── Views/
│           └── Business/
│               └── MacOSBusinessViews.swift
```

### 2. Business Logic Extensions

```swift
// BusinessViewExtensions.swift
import SixLayerFramework

extension View {
    /// Business-specific form section
    func businessFormSection<Content: View>(
        title: String,
        businessType: BusinessType,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                BusinessTypeBadge(type: businessType)
            }
            
            content()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    /// Business-specific card style
    func businessCardStyle(
        businessType: BusinessType,
        priority: BusinessPriority = .normal
    ) -> some View {
        self
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(priority.color, lineWidth: 2)
            )
            .shadow(radius: 2)
    }
}

enum BusinessType: String, CaseIterable {
    case inventory = "inventory"
    case customer = "customer"
    case order = "order"
    case product = "product"
    
    var displayName: String {
        switch self {
        case .inventory: return "Inventory"
        case .customer: return "Customer"
        case .order: return "Order"
        case .product: return "Product"
        }
    }
    
    var color: Color {
        switch self {
        case .inventory: return .blue
        case .customer: return .green
        case .order: return .orange
        case .product: return .purple
        }
    }
}
```

### 3. Business Hints System

```swift
// BusinessHints.swift
import SixLayerFramework

class BusinessHint: CustomHint {
    let businessType: BusinessType
    let businessContext: BusinessContext
    
    init(
        businessType: BusinessType,
        businessContext: BusinessContext,
        priority: HintPriority = .normal
    ) {
        self.businessType = businessType
        self.businessContext = businessContext
        
        super.init(
            hintType: "business.\(businessType.rawValue)",
            priority: priority,
            customData: [
                "businessType": businessType.rawValue,
                "businessContext": businessContext.rawValue,
                "displayName": businessType.displayName,
                "color": businessType.color.description
            ]
        )
    }
}

enum BusinessContext: String, CaseIterable {
    case dashboard = "dashboard"
    case detail = "detail"
    case create = "create"
    case edit = "edit"
    case browse = "browse"
}

extension EnhancedPresentationHints {
    /// Create hints for business-specific views
    static func forBusiness(
        businessType: BusinessType,
        context: BusinessContext,
        priority: HintPriority = .normal
    ) -> EnhancedPresentationHints {
        let businessHint = BusinessHint(
            businessType: businessType,
            businessContext: context,
            priority: priority
        )
        
        return EnhancedPresentationHints(
            dataType: .collection,
            presentationPreference: .automatic,
            complexity: .moderate,
            context: .dashboard,
            extensibleHints: [businessHint]
        )
    }
}
```

## Real-World Examples

### 1. E-commerce Product Management

```swift
struct ProductManagementView: View {
    let products: [Product]
    @State private var selectedProduct: Product?
    
    var body: some View {
        VStack {
            // Layer 1: Semantic Intent
            platformPresentItemCollection_L1(
                items: products,
                hints: createProductHints(),
                customItemView: { product in
                    ProductCard(product: product)
                        .onTapGesture {
                            selectedProduct = product
                        }
                }
            )
        }
        // Layer 5: Performance Optimization
        // Layer 6: Platform-Specific Features
        #if os(iOS)
        .platformIOSHapticFeedback(style: .medium) {
            // Haptic feedback on product selection
        }
        #endif
    }
    
    private func createProductHints() -> EnhancedPresentationHints {
        let productHint = CustomHint(
            hintType: "ecommerce.product",
            priority: .high,
            customData: [
                "businessType": "ecommerce",
                "showPricing": true,
                "showInventory": true,
                "showReviews": true,
                "layoutStyle": "grid"
            ]
        )
        
        return EnhancedPresentationHints(
            dataType: .collection,
            presentationPreference: .grid,
            complexity: .moderate,
            context: .browse,
            extensibleHints: [productHint]
        )
    }
}
```

### 2. Financial Dashboard

```swift
struct FinancialDashboardView: View {
    let financialData: FinancialData
    
    var body: some View {
        VStack(spacing: 20) {
            // Custom business header
            FinancialHeaderView(data: financialData)
            
            // Use framework for consistent layout
            platformCardGrid(columns: 2, spacing: 16) {
                ForEach(financialData.metrics) { metric in
                    FinancialMetricCard(metric: metric)
                        .businessCardStyle(
                            businessType: .product,
                            priority: metric.priority
                        )
                }
            }
        }
        // Apply framework optimizations
    }
}
```

### 3. Customer Management System

```swift
struct CustomerManagementView: View {
    let customers: [Customer]
    
    var body: some View {
        // Layer 1: Semantic Intent
        platformPresentItemCollection_L1(
            items: customers,
            hints: createCustomerHints(),
            customItemView: { customer in
                CustomerCard(customer: customer)
            }
        )
        // Layer 5: Performance Optimization
    }
    
    private func createCustomerHints() -> EnhancedPresentationHints {
        let customerHint = CustomHint(
            hintType: "crm.customer",
            priority: .normal,
            customData: [
                "businessType": "crm",
                "showContactInfo": true,
                "showOrderHistory": true,
                "showNotes": true,
                "layoutStyle": "list"
            ]
        )
        
        return EnhancedPresentationHints(
            dataType: .collection,
            presentationPreference: .list,
            complexity: .moderate,
            context: .browse,
            extensibleHints: [customerHint]
        )
    }
}
```

## Best Practices

### 1. Use the Hints System Effectively

```swift
// ✅ Good: Use hints to configure framework behavior
let hints = EnhancedPresentationHints(
    dataType: .collection,
    presentationPreference: .automatic,
    complexity: .moderate,
    context: .dashboard,
    extensibleHints: [
        BusinessHint(businessType: .inventory, businessContext: .dashboard),
        PerformanceHint(priority: .high, enableCaching: true)
    ]
)

// ❌ Avoid: Hardcoding framework behavior
platformCardGrid(columns: 3, spacing: 16) {
    // Hardcoded values
}
```

### 2. Leverage the 6-Layer Architecture

```swift
// ✅ Good: Use all layers for maximum benefit
struct MyBusinessView: View {
    var body: some View {
        // Layer 1: Semantic Intent
        platformPresentItemCollection_L1(items: items, hints: hints)
        // Layer 5: Performance Optimization
        // Layer 6: Platform-Specific Features
        #if os(iOS)
        .platformIOSHapticFeedback(style: .medium) { }
        #endif
    }
}

// ❌ Avoid: Using only one layer
struct MyBusinessView: View {
    var body: some View {
        VStack {
            // Only using raw SwiftUI
        }
    }
}
```

### 3. Create Reusable Business Components

```swift
// ✅ Good: Create reusable business components
struct BusinessCard<Content: View>: View {
    let businessType: BusinessType
    let priority: BusinessPriority
    let content: Content
    
    init(
        businessType: BusinessType,
        priority: BusinessPriority = .normal,
        @ViewBuilder content: () -> Content
    ) {
        self.businessType = businessType
        self.priority = priority
        self.content = content()
    }
    
    var body: some View {
        content
            .businessCardStyle(businessType: businessType, priority: priority)
    }
}

// Usage
BusinessCard(businessType: .inventory, priority: .high) {
    Text("Inventory Item")
}
```

### 4. Maintain Framework Benefits

```swift
// ✅ Good: Custom views that maintain framework benefits
struct MyCustomView: View {
    var body: some View {
        VStack {
            // Custom business logic
        }
        // Apply framework optimizations
    }
}

// ❌ Avoid: Custom views that lose framework benefits
struct MyCustomView: View {
    var body: some View {
        VStack {
            // Custom business logic
        }
        // Missing framework optimizations
    }
}
```

## Troubleshooting

### Common Issues

#### 1. Custom Views Not Getting Framework Benefits

**Problem**: Custom views don't get platform optimization or responsive behavior.

**Solution**: Apply Layer 5 and Layer 6 functions to your custom views:

```swift
struct MyCustomView: View {
    var body: some View {
        VStack {
            // Your custom content
        }
        #if os(iOS)
        .platformIOSHapticFeedback(...)      // Layer 6
        #endif
    }
}
```

#### 2. Hints Not Working as Expected

**Problem**: Custom hints aren't influencing framework behavior.

**Solution**: Ensure hints are properly structured and have the right priority:

```swift
let hint = CustomHint(
    hintType: "myapp.business",  // Unique type
    priority: .high,             // High priority
    overridesDefault: false,     // Don't override unless necessary
    customData: [
        "businessType": "inventory",
        "showAdvancedMetrics": true
    ]
)
```

#### 3. Platform-Specific Features Not Working

**Problem**: Platform-specific features aren't applied on the correct platform.

**Solution**: Use proper platform detection:

```swift
#if os(iOS)
.platformIOSHapticFeedback(style: .medium) { }
#elseif os(macOS)
.platformMacOSWindowSizing(minWidth: 800, minHeight: 600)
#endif
```

#### 4. Performance Issues with Custom Views

**Problem**: Custom views are causing performance issues.

**Solution**: Apply framework performance optimizations:

```swift
struct MyCustomView: View {
    var body: some View {
        VStack {
            // Your custom content
        }
    }
}
```

### Getting Help

1. **Check the framework documentation** for available functions
2. **Use the hints system** to configure framework behavior
3. **Apply Layer 5 and Layer 6 functions** to custom views
4. **Test on both platforms** to ensure compatibility
5. **Profile performance** to identify bottlenecks

## Conclusion

The SixLayer Framework provides powerful extensibility through its hints system and 6-layer architecture. By following the patterns in this guide, you can create custom views and business logic extensions that leverage the framework's intelligent platform adaptation and performance optimization capabilities.

Remember:
- **Use the hints system** to configure framework behavior
- **Apply Layer 5 and Layer 6 functions** to custom views
- **Create reusable business components** for consistency
- **Test on both platforms** to ensure compatibility
- **Profile performance** to identify optimization opportunities

The framework is designed to be extended while maintaining its core benefits. Use these patterns to build business-specific functionality that integrates seamlessly with the framework's intelligent platform adaptation.
