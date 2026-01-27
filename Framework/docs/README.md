# SixLayer Framework Documentation

Welcome to the SixLayer Framework documentation. This directory contains comprehensive guides and references for understanding and extending the framework.

## 📚 Documentation Overview

### 🚀 Getting Started
- **[README_6LayerArchitecture.md](README_6LayerArchitecture.md)** - Complete architecture overview
- **[README_UsageExamples.md](README_UsageExamples.md)** - Practical usage examples and patterns
- **[DeveloperExtensionGuide.md](DeveloperExtensionGuide.md)** - **NEW!** Complete guide for developers extending the framework
- **[ExtensionQuickReference.md](ExtensionQuickReference.md)** - **NEW!** Quick reference card for common patterns
- **[AI Agent Guides](AI_AGENT_GUIDE.md)** - AI agent guides for helping developers USE the framework
  - **[AI_AGENT_GUIDE.md](AI_AGENT_GUIDE.md)** - Main guide for AI agents
  - **[AI_AGENT_GUIDE_v4.6.0.md](AI_AGENT_GUIDE_v4.6.0.md)** - Version-specific guide for v4.6.0
  - **[AI_AGENT_v5.0.0.md](AI_AGENT_v5.0.0.md)** - Version-specific guide for v5.0.0
  - Other version-specific guides available in this directory

### 🏗️ Architecture Details
- **[README_Layer1_Semantic.md](README_Layer1_Semantic.md)** - Semantic intent layer
- **[README_Layer2_Decision.md](README_Layer2_Decision.md)** - Layout decision engine
- **[README_Layer3_Strategy.md](README_Layer3_Strategy.md)** - Strategy selection layer
- **[README_Layer4_Implementation.md](README_Layer4_Implementation.md)** - Component implementation
- **[README_Layer5_Performance.md](README_Layer5_Performance.md)** - Performance optimization
- **[README_Layer6_Platform.md](README_Layer6_Platform.md)** - Platform-specific features

### ♿ Accessibility
- **[AutomaticAccessibilityIdentifiers.md](AutomaticAccessibilityIdentifiers.md)** - Automatic accessibility identifier generation
- **[AccessibilityLabelsGuide.md](AccessibilityLabelsGuide.md)** - Accessibility labels and localization
- **[Layer1AccessibilityGuide.md](Layer1AccessibilityGuide.md)** - **NEW!** Complete Layer 1 accessibility guide (Issue #166)
- **[Layer1AccessibilityTestingGuide.md](Layer1AccessibilityTestingGuide.md)** - **NEW!** Layer 1 accessibility testing guide (Issue #166)

### 🔧 Advanced Topics
- **[MigrationGuide.md](MigrationGuide.md)** - **NEW v6.4.0!** Framework upgrade and migration guide
- **[NavigationStackGuide.md](NavigationStackGuide.md)** - **NEW!** Complete 6-layer NavigationStack implementation guide
- **[HintsSystemExtensibility.md](HintsSystemExtensibility.md)** - Custom hints and extensibility
- **[HintsDefaultValuesGuide.md](HintsDefaultValuesGuide.md)** - **NEW v4.6.0!** Default values in hints system
- **[FieldHintsCompleteGuide.md](FieldHintsCompleteGuide.md)** - **NEW v4.8.0!** Field-level display hints system
- **[FieldHintsGuide.md](FieldHintsGuide.md)** - Quick start guide for field hints
- **[HintsDRYArchitecture.md](HintsDRYArchitecture.md)** - DRY architecture for field hints
- **[HintsFolderStructure.md](HintsFolderStructure.md)** - Hints file organization
- **[platform-specific-patterns.md](platform-specific-patterns.md)** - Platform-specific development patterns
- **[FunctionIndex.md](FunctionIndex.md)** - Complete function reference
- **Settings Management** - Centralized settings system (see AI_AGENT_GUIDE.md)

### 📝 Form Components
- **[AdvancedFieldTypesGuide.md](AdvancedFieldTypesGuide.md)** - **NEW!** Complete guide to advanced form field types
- **Native Type Support** - **NEW!** Full native type support for Int, Image, URL, Array, Data, and Enum
- **Rich Text Editor** - Formatting capabilities with platform-specific implementation
- **Date/Time Pickers** - Comprehensive date and time selection components
- **File Upload** - Drag & drop file upload with validation
- **Autocomplete** - Smart suggestion-based input fields
- **Custom Fields** - Extensible custom field component system

### 📸 OCR & Barcode Scanning
- **[OCROverlayGuide.md](OCROverlayGuide.md)** - **NEW!** Complete guide to OCR overlay system
- **[BarcodeScanningGuide.md](BarcodeScanningGuide.md)** - **NEW!** Complete guide to barcode scanning
- **[StructuredOCRExtractionGuide.md](StructuredOCRExtractionGuide.md)** - **NEW!** Complete guide to structured OCR data extraction
- **[HIGVisualDesignCategoriesGuide.md](HIGVisualDesignCategoriesGuide.md)** - **NEW v5.9.0!** Complete guide to HIG-compliant visual design categories
- **OCR Overlay System** - Interactive visual text correction with bounding box editing
- **OCR Disambiguation** - Smart text recognition with user selection capabilities
- **Visual Text Correction** - Tap-to-edit functionality for OCR results
- **Barcode Scanning** - **NEW!** Detect 1D and 2D barcodes (QR Code, Code 128, EAN-13, etc.)
- **Structured Data Extraction** - **NEW!** Extract structured data from documents using regex patterns and hints
- **Visual Design Categories** - **NEW v5.9.0!** HIG-compliant animations, shadows, corner radius, borders, opacity, and blur effects


### 📱 Platform-Specific
- **[keyboard-consistency-guidelines.md](keyboard-consistency-guidelines.md)** - Cross-platform keyboard handling


## 🎯 Quick Navigation

**For New Developers:**
1. Start with [README_6LayerArchitecture.md](README_6LayerArchitecture.md)
2. Review [README_UsageExamples.md](README_UsageExamples.md)
3. Use [DeveloperExtensionGuide.md](DeveloperExtensionGuide.md) for custom development

**For Framework Extension:**
1. Read [DeveloperExtensionGuide.md](DeveloperExtensionGuide.md) for comprehensive guidance
2. Study [HintsSystemExtensibility.md](HintsSystemExtensibility.md) for advanced customization
3. Reference [FunctionIndex.md](FunctionIndex.md) for API details

**For Platform-Specific Development:**
1. Review [platform-specific-patterns.md](platform-specific-patterns.md)
2. Check [keyboard-consistency-guidelines.md](keyboard-consistency-guidelines.md)

**For Settings Management:**
1. See [AI_AGENT_GUIDE.md](AI_AGENT_GUIDE.md) Settings Management section
2. Use VisualDesignSystem.shared for centralized settings
3. Leverage automatic platform and accessibility detection

## 🔍 Finding What You Need

- **Function Reference**: Use [FunctionIndex.md](FunctionIndex.md) for complete API documentation
- **Examples**: Check [README_UsageExamples.md](README_UsageExamples.md) for practical code samples
- **Architecture**: See [README_6LayerArchitecture.md](README_6LayerArchitecture.md) for system overview
- **Extension**: Use [DeveloperExtensionGuide.md](DeveloperExtensionGuide.md) for custom development

## 📖 Documentation Standards

All documentation follows these principles:
- **Clear examples** with working code
- **Progressive complexity** from basic to advanced
- **Cross-references** between related topics
- **Practical guidance** for real-world usage
- **Best practices** and common patterns

## 🎯 **Framework Design Philosophy**

### **Apple HIG Compliance by Default**
The SixLayer Framework is designed to automatically follow Apple's Human Interface Guidelines (HIG) and accessibility best practices, ensuring that applications built with the framework provide excellent user experiences out of the box.

**Core Principle**: *Make it impossible to build a bad UI with the framework, while making it easy to build a great one.*

#### **What This Means:**
- **Automatic Accessibility**: VoiceOver support, keyboard navigation, high contrast, and dynamic type are applied automatically when needed
- **Platform-Specific Patterns**: iOS uses navigation stacks and haptic feedback, macOS uses window-based navigation and keyboard shortcuts
- **Visual Design Consistency**: SF Symbols on iOS, system colors that adapt to light/dark mode, proper spacing following Apple's 8pt grid
- **Interaction Patterns**: Appropriate touch targets, hover states, gesture recognition, and feedback for each platform
- **Apple Quality Standards**: Every UI element follows Apple's design guidelines without developer configuration

#### **Developer Experience:**
```swift
// Developer writes this:
Button("Save") { saveData() }

// Framework automatically provides Apple HIG compliance:
// - Proper accessibility labels and hints
// - Platform-appropriate styling and interactions
// - VoiceOver support when enabled
// - Keyboard navigation support
// - High contrast support when needed
// - Proper touch targets and spacing
// - Platform-specific feedback (haptic/sound)
```

## 🤝 Contributing to Documentation

When updating documentation:
1. Maintain the existing structure and style
2. Update cross-references when adding new files
3. Include practical examples and code samples
4. Follow the established naming conventions
5. Update this README when adding new documentation files
