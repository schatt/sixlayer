import SwiftUI
import UniformTypeIdentifiers

// MARK: - Rich Text Editor Field

/// Rich text editor field with formatting capabilities
public struct RichTextEditorField: View {
    let field: DynamicFormField
    @ObservedObject var formState: DynamicFormState
    @State private var isEditing = false
    @State private var selectedText: NSRange?
    
    public var body: some View {
        platformVStackContainer(alignment: .leading, spacing: 8) {
            platformHStackContainer {
                Text(field.label)
                    .font(.headline)
                
                Spacer()
                
                let i18n = InternationalizationService()
                Button(isEditing ? i18n.localizedString(for: "SixLayerFramework.button.done") : i18n.localizedString(for: "SixLayerFramework.button.edit")) {
                    isEditing.toggle()
                }
                .buttonStyle(.bordered)
            }
            
            if isEditing {
                RichTextEditor(
                    text: Binding(
                        get: { formState.getValue(for: field.id) ?? "" },
                        set: { formState.setValue($0, for: field.id) }
                    ),
                    selectedText: $selectedText
                )
                .frame(minHeight: 150)
                .background(Color.secondaryBackground)
                .cornerRadius(8)
                
                RichTextToolbar(selectedText: $selectedText)
            } else {
                RichTextPreview(
                    text: formState.getValue(for: field.id) ?? ""
                )
                .frame(minHeight: 100)
                .background(Color.secondaryBackground)
                .cornerRadius(8)
            }
        }
        .automaticCompliance()
    }
}

// MARK: - Rich Text Editor

/// Rich text editor with formatting capabilities
#if os(iOS)
public struct RichTextEditor: UIViewRepresentable {
    @Binding var text: String
    @Binding var selectedText: NSRange?
    
        public func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = Font.uiFontBody()
        textView.isEditable = true
        textView.isScrollEnabled = true
        textView.backgroundColor = UIColor(Color.platformSystemBackground)
        textView.layer.cornerRadius = 8
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor(Color.platformSeparator).cgColor
        
        // Enable rich text editing
        textView.allowsEditingTextAttributes = true
        textView.dataDetectorTypes = [.link, .phoneNumber]
        
        return textView
    }
    
        public func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
    }
    
        public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public class Coordinator: NSObject, UITextViewDelegate {
        var parent: RichTextEditor
        
        init(_ parent: RichTextEditor) {
            self.parent = parent
        }
        
            public func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }
        
            public func textViewDidChangeSelection(_ textView: UITextView) {
            parent.selectedText = textView.selectedRange
        }
    }
}
#elseif os(tvOS)
// tvOS: `TextEditor` is unavailable; use a single-line `TextField`.
public struct RichTextEditor: View {
    @Binding var text: String
    @Binding var selectedText: NSRange?

    public var body: some View {
        TextField("", text: $text)
            .font(.body)
            .frame(minHeight: 150)
            .padding(8)
            .background(Color.secondaryBackground)
            .cornerRadius(8)
            .onChange(of: text) {
                // Handle text changes
            }
    }
}
#elseif os(watchOS)
// watchOS: multiline `TextField` with vertical axis (TextEditor is heavy on small screens).
public struct RichTextEditor: View {
    @Binding var text: String
    @Binding var selectedText: NSRange?

    public var body: some View {
        TextField("", text: $text, axis: .vertical)
            .font(.body)
            .lineLimit(4...12)
            .frame(minHeight: 120)
            .padding(8)
            .background(Color.secondaryBackground)
            .cornerRadius(8)
            .onChange(of: text) {
                // Handle text changes
            }
    }
}
#else
// macOS (and other platforms with `TextEditor`) — simple text editor
public struct RichTextEditor: View {
    @Binding var text: String
    @Binding var selectedText: NSRange?
    
    public var body: some View {
        TextEditor(text: $text)
            .font(.body)
            .frame(minHeight: 150)
            .padding(8)
            .background(Color.secondaryBackground)
            .cornerRadius(8)
                    .onChange(of: text) {
            // Handle text changes
        }
    }
}
#endif

// MARK: - Rich Text Toolbar

/// Toolbar for rich text formatting
public struct RichTextToolbar: View {
    @Binding var selectedText: NSRange?
    
    public var body: some View {
        platformHStackContainer(spacing: 12) {
            FormatButton(title: "B", action: { formatBold() })
            FormatButton(title: "I", action: { formatItalic() })
            FormatButton(title: "U", action: { formatUnderline() })
            
            Divider()
            
            FormatButton(title: "•", action: { formatBullet() })
            FormatButton(title: "1.", action: { formatNumbered() })
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.tertiaryBackground)
        .cornerRadius(6)
        .automaticCompliance(named: "RichTextToolbar")
    }
    
    private func formatBold() {
        // Format bold implementation
        // This would apply bold formatting to the selected text
        // For now, this is a placeholder for the actual implementation
    }
    
    private func formatItalic() {
        // Format italic implementation
        // This would apply italic formatting to the selected text
        // For now, this is a placeholder for the actual implementation
    }
    
    private func formatUnderline() {
        // Format underline implementation
        // This would apply underline formatting to the selected text
        // For now, this is a placeholder for the actual implementation
    }
    
    private func formatBullet() {
        // Format bullet list implementation
        // This would apply bullet list formatting to the selected text
        // For now, this is a placeholder for the actual implementation
    }
    
    private func formatNumbered() {
        // Format numbered list implementation
        // This would apply numbered list formatting to the selected text
        // For now, this is a placeholder for the actual implementation
    }
}

// MARK: - Format Button

/// Button for text formatting
public struct FormatButton: View {
    let title: String
    let action: () -> Void
    
    public var body: some View {
        Button(title, action: action)
            .font(.system(.body, design: .monospaced))
            .frame(width: 32, height: 32)
            .background(Color.accentColor)
            .foregroundColor(.platformButtonTextOnColor)
            .cornerRadius(4)
            .automaticCompliance(named: "FormatButton")
    }
}

// MARK: - Rich Text Preview

/// Preview of rich text content
public struct RichTextPreview: View {
    let text: String
    
    public var body: some View {
        ScrollView {
            Text(text)
                .font(.body)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .automaticCompliance(named: "RichTextPreview")
    }
}

// MARK: - Autocomplete Field

/// Autocomplete text field with suggestions
public struct AutocompleteField: View {
    let field: DynamicFormField
    @ObservedObject var formState: DynamicFormState
    let suggestions: [String]
    
    @State private var text: String = ""
    @State private var showSuggestions = false
    @State private var filteredSuggestions: [String] = []
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            TextField(field.placeholder ?? field.label, text: $text)
                .platformTextFieldStyle()
                .accessibilityLabel("Autocomplete field for \(field.label)")
                .accessibilityHint("Type to search and select from suggestions")
                .onChange(of: text) { oldValue, newValue in
                    filterSuggestions(query: newValue)
                    formState.setValue(newValue, for: field.id)
                }
                .onAppear {
                    text = formState.getValue(for: field.id) ?? ""
                }
            
            if showSuggestions && !filteredSuggestions.isEmpty {
                AutocompleteSuggestions(
                    suggestions: filteredSuggestions,
                    onSelect: { suggestion in
                        text = suggestion
                        formState.setValue(suggestion, for: field.id)
                        showSuggestions = false
                    }
                )
            }
        }
        .automaticCompliance()
    }
    
    private func filterSuggestions(query: String) {
        if query.isEmpty {
            filteredSuggestions = []
            showSuggestions = false
        } else {
            // Enhanced filtering with better matching
            filteredSuggestions = suggestions.filter { suggestion in
                suggestion.localizedCaseInsensitiveContains(query) ||
                suggestion.lowercased().hasPrefix(query.lowercased())
            }
            .sorted { suggestion1, suggestion2 in
                // Prioritize exact matches and prefix matches
                let queryLower = query.lowercased()
                let s1Lower = suggestion1.lowercased()
                let s2Lower = suggestion2.lowercased()
                
                if s1Lower.hasPrefix(queryLower) && !s2Lower.hasPrefix(queryLower) {
                    return true
                } else if !s1Lower.hasPrefix(queryLower) && s2Lower.hasPrefix(queryLower) {
                    return false
                } else {
                    return suggestion1 < suggestion2
                }
            }
            showSuggestions = !filteredSuggestions.isEmpty
        }
    }
}

// MARK: - Autocomplete Suggestions

/// Display autocomplete suggestions
public struct AutocompleteSuggestions: View {
    let suggestions: [String]
    let onSelect: (String) -> Void
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(suggestions, id: \.self) { suggestion in
                Button(action: { onSelect(suggestion) }) {
                    Text(suggestion)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .background(Color.secondaryBackground)
                
                if suggestion != suggestions.last {
                    Divider()
                }
            }
        }
        .background(Color.secondaryBackground)
        .cornerRadius(8)
        .shadow(radius: 2)
    }
}

// MARK: - Enhanced File Upload Field

/// Enhanced file upload field with drag & drop support
public struct EnhancedFileUploadField: View {
    let field: DynamicFormField
    @ObservedObject var formState: DynamicFormState
    let allowedTypes: [UTType]
    let maxFileSize: Int64? // in bytes
    
    @State private var isDragOver = false
    @State private var selectedFiles: [FileInfo] = []
    
    public var body: some View {
        platformVStackContainer(alignment: .leading, spacing: 12) {
            Text(field.label)
                .font(.headline)
            
            FileUploadArea(
                isDragOver: $isDragOver,
                selectedFiles: $selectedFiles,
                allowedTypes: allowedTypes,
                maxFileSize: maxFileSize,
                onFilesSelected: { files in
                    selectedFiles = files
                    updateFormState()
                }
            )
            
            if !selectedFiles.isEmpty {
                FileList(files: selectedFiles) { file in
                    selectedFiles.removeAll { $0.id == file.id }
                    updateFormState()
                }
            }
        }
        .automaticCompliance()
    }
    
    private func updateFormState() {
        let fileData = selectedFiles.map { file in
            [
                "name": file.name,
                "size": file.size,
                "type": file.type.identifier,
                "url": file.url?.absoluteString ?? ""
            ]
        }
        formState.setValue(fileData, for: field.id)
    }
}

// MARK: - File Upload Area

/// Drag & drop file upload area
public struct FileUploadArea: View {
    @Binding var isDragOver: Bool
    @Binding var selectedFiles: [FileInfo]
    let allowedTypes: [UTType]
    let maxFileSize: Int64?
    let onFilesSelected: ([FileInfo]) -> Void
    
    public var body: some View {
        platformVStackContainer(spacing: 16) {
            Image(systemName: "doc.badge.plus")
                .platformDecorativeIconFont(designSize: 48)
                .foregroundColor(.accentColor)
            
            let i18n = InternationalizationService()
            Text(i18n.localizedString(for: "SixLayerFramework.form.dragDropFiles"))
                .font(.headline)
            
            Text(i18n.localizedString(for: "SixLayerFramework.form.or"))
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button(i18n.localizedString(for: "SixLayerFramework.button.browseFiles")) {
                selectFiles()
            }
            .buttonStyle(.borderedProminent)
            
            let supportedTypes = allowedTypes.compactMap { $0.localizedDescription }.joined(separator: ", ")
            Text(i18n.localizedString(for: "SixLayerFramework.form.supportedTypes", arguments: [supportedTypes]))
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if let maxSize = maxFileSize {
                let maxSizeStr = ByteCountFormatter.string(fromByteCount: maxSize, countStyle: .file)
                Text(i18n.localizedString(for: "SixLayerFramework.form.maxFileSize", arguments: [maxSizeStr]))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, minHeight: 200)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isDragOver ? Color.accentColor.opacity(0.1) : Color.secondaryBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isDragOver ? Color.accentColor : Color.platformSeparator, lineWidth: 2)
        )
        .platformOnDrop(supportedTypes: allowedTypes, isTargeted: $isDragOver) { providers in
            handleDrop(providers: providers)
            return true
        }
        .accessibilityLabel("File upload area")
        .accessibilityHint("Drag and drop files here or tap to browse")
        .automaticCompliance(named: "FileUploadArea")
    }
    
    private func selectFiles() {
        // File picker implementation
        // This would integrate with the system file picker
        // For now, this is a placeholder for the actual implementation
        #if os(iOS)
        // iOS file picker implementation would go here
        #elseif os(macOS)
        // macOS file picker implementation would go here
        #endif
    }
    
    private func handleDrop(providers: [NSItemProvider]) {
        // Handle dropped files
        // This would process the dropped file providers
        // For now, this is a placeholder for the actual implementation
        let group = DispatchGroup()
        
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                // Handle image files
                group.enter()
                provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { item, error in
                    defer { group.leave() }
                    if let url = item as? URL {
                        Task { @MainActor in
                            let fileInfo = FileInfo(
                                name: url.lastPathComponent,
                                size: Int64((try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0),
                                type: UTType.image,
                                url: url
                            )
                            onFilesSelected([fileInfo])
                        }
                    }
                }
            } else if provider.hasItemConformingToTypeIdentifier(UTType.pdf.identifier) {
                // Handle PDF files
                group.enter()
                provider.loadItem(forTypeIdentifier: UTType.pdf.identifier, options: nil) { item, error in
                    defer { group.leave() }
                    if let url = item as? URL {
                        Task { @MainActor in
                            let fileInfo = FileInfo(
                                name: url.lastPathComponent,
                                size: Int64((try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0),
                                type: UTType.pdf,
                                url: url
                            )
                            onFilesSelected([fileInfo])
                        }
                    }
                }
            }
        }
    }
}

// MARK: - File Info

/// Information about a selected file
public struct FileInfo: Identifiable, Sendable {
    public let id = UUID()
    public let name: String
    public let size: Int64
    public let type: UTType
    public let url: URL?
    
    public init(name: String, size: Int64, type: UTType, url: URL?) {
        self.name = name
        self.size = size
        self.type = type
        self.url = url
    }
}

// MARK: - File List

/// Display list of selected files
public struct FileList: View {
    let files: [FileInfo]
    let onRemove: (FileInfo) -> Void
    
    public var body: some View {
        VStack(spacing: 8) {
            ForEach(files) { file in
                FileRow(file: file, onRemove: onRemove)
            }
        }
        .automaticCompliance()
    }
}

// MARK: - File Row

/// Individual file row in the file list
public struct FileRow: View {
    let file: FileInfo
    let onRemove: (FileInfo) -> Void
    
    public var body: some View {
        HStack {
            Image(systemName: "doc")
                .foregroundColor(.accentColor)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(file.name)
                    .font(.subheadline)
                    .lineLimit(1)
                
                Text("\(ByteCountFormatter.string(fromByteCount: file.size, countStyle: .file)) • \(file.type.localizedDescription ?? "Unknown")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: { onRemove(file) }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(8)
        .background(Color.tertiaryBackground)
        .cornerRadius(6)
        .environment(\.accessibilityIdentifierLabel, file.name) // TDD GREEN: Pass label to identifier generation
        .automaticCompliance(named: "FileRow")
    }
}

// MARK: - Date Picker Field

/// Date picker field for selecting dates.
///
/// **Storage contract:** Persists a **localized medium-style string** in ``DynamicFormState`` (see ``DynamicFormStoredDateValue`` and the Advanced Field Types guide for contrast with ``DynamicDateField``, which prefers `Date`).
public struct DatePickerField: View {
    let field: DynamicFormField
    @ObservedObject var formState: DynamicFormState
    @State private var selectedDate = Date()
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(field.label)
                .font(.headline)
            
            #if os(watchOS)
            DatePicker(
                "",
                selection: $selectedDate,
                displayedComponents: .date
            )
            .datePickerStyle(.wheel)
            .selfLabelingControl(label: field.label)
            .onChange(of: selectedDate) {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formState.setValue(formatter.string(from: selectedDate), for: field.id)
            }
            .onAppear {
                if let existingValue: String = formState.getValue(for: field.id) {
                    let formatter = DateFormatter()
                    formatter.dateStyle = .medium
                    if let date = formatter.date(from: existingValue) {
                        selectedDate = date
                    }
                }
            }
            #else
            platformDateInput(selection: $selectedDate, label: field.label)
            .onChange(of: selectedDate) {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formState.setValue(formatter.string(from: selectedDate), for: field.id)
            }
            .onAppear {
                // Load existing value if available
                if let existingValue: String = formState.getValue(for: field.id) {
                    let formatter = DateFormatter()
                    formatter.dateStyle = .medium
                    if let date = formatter.date(from: existingValue) {
                        selectedDate = date
                    }
                }
            }
            #endif
        }
        .automaticCompliance()
    }
}

// MARK: - Time Picker Field

/// Time picker field for selecting times.
///
/// **Storage contract:** Persists a **localized short time string** in ``DynamicFormState`` (contrast: ``DynamicTimeField`` prefers `Date`).
public struct TimePickerField: View {
    let field: DynamicFormField
    @ObservedObject var formState: DynamicFormState
    @State private var selectedTime = Date()
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(field.label)
                .font(.headline)
            
            #if os(watchOS)
            DatePicker(
                "",
                selection: $selectedTime,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .selfLabelingControl(label: field.label)
            .onChange(of: selectedTime) {
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                formState.setValue(formatter.string(from: selectedTime), for: field.id)
            }
            .onAppear {
                if let existingValue: String = formState.getValue(for: field.id) {
                    let formatter = DateFormatter()
                    formatter.timeStyle = .short
                    if let time = formatter.date(from: existingValue) {
                        selectedTime = time
                    }
                }
            }
            #else
            platformTimeInput(selection: $selectedTime, label: field.label)
            .onChange(of: selectedTime) {
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                formState.setValue(formatter.string(from: selectedTime), for: field.id)
            }
            .onAppear {
                // Load existing value if available
                if let existingValue: String = formState.getValue(for: field.id) {
                    let formatter = DateFormatter()
                    formatter.timeStyle = .short
                    if let time = formatter.date(from: existingValue) {
                        selectedTime = time
                    }
                }
            }
            #endif
        }
        .automaticCompliance()
    }
}

// MARK: - Date Time Picker Field

/// Date and time picker field for selecting both date and time.
///
/// **Storage contract:** Persists a **localized medium date + short time string** in ``DynamicFormState`` (contrast: ``DynamicDateTimeField`` prefers `Date`).
public struct DateTimePickerField: View {
    let field: DynamicFormField
    @ObservedObject var formState: DynamicFormState
    @State private var selectedDateTime = Date()
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(field.label)
                .font(.headline)
            
            #if os(watchOS)
            DatePicker(
                "",
                selection: $selectedDateTime,
                displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(.wheel)
            .selfLabelingControl(label: field.label)
            .onChange(of: selectedDateTime) {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .short
                formState.setValue(formatter.string(from: selectedDateTime), for: field.id)
            }
            .onAppear {
                if let existingValue: String = formState.getValue(for: field.id) {
                    let formatter = DateFormatter()
                    formatter.dateStyle = .medium
                    formatter.timeStyle = .short
                    if let dateTime = formatter.date(from: existingValue) {
                        selectedDateTime = dateTime
                    }
                }
            }
            #else
            platformDateTimeInput(selection: $selectedDateTime, label: field.label)
            .onChange(of: selectedDateTime) {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .short
                formState.setValue(formatter.string(from: selectedDateTime), for: field.id)
            }
            .onAppear {
                // Load existing value if available
                if let existingValue: String = formState.getValue(for: field.id) {
                    let formatter = DateFormatter()
                    formatter.dateStyle = .medium
                    formatter.timeStyle = .short
                    if let dateTime = formatter.date(from: existingValue) {
                        selectedDateTime = dateTime
                    }
                }
            }
            #endif
        }
        .automaticCompliance()
    }
}

