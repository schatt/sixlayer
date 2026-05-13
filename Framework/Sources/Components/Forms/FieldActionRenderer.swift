import SwiftUI

// MARK: - Field Action Renderer

/// Renders field actions for DynamicFormField
/// Handles layout based on action count: single button, horizontal buttons, or menu
/// Supports async actions with loading states and error handling
/// 
/// BUSINESS PURPOSE: Unified rendering system for field actions
/// DESIGN: Handles 1 action (button), 2 actions (horizontal), 3+ actions (menu)
@MainActor
public struct FieldActionRenderer: View {
    let field: DynamicFormField
    @ObservedObject var formState: DynamicFormState
    @State private var isActionMenuPresented = false
    @State private var actionLoadingState: [String: Bool] = [:]
    @State private var actionErrors: [String: Error] = [:]
    @State private var showBarcodeScanner = false
    @State private var showOCRScanner = false
    @State private var scanningFieldId: String?
    
    public init(field: DynamicFormField, formState: DynamicFormState) {
        self.field = field
        self.formState = formState
    }
    
    public var body: some View {
        let actions = field.effectiveActions
        
        Group {
            if actions.isEmpty {
                EmptyView()
            } else if actions.count == 1, let action = actions.first {
                singleActionButton(action: action)
            } else if actions.count <= field.maxVisibleActions && !field.useActionMenu {
                horizontalActionButtons(actions: actions)
            } else {
                // SwiftUI `Menu` is unavailable on watchOS; show inline actions instead.
                #if os(watchOS)
                horizontalActionButtons(actions: actions)
                #else
                actionMenu(actions: actions)
                #endif
            }
        }
        .sheet(isPresented: $showBarcodeScanner) {
            // Extract hint and types from field (backward compatibility)
            FieldActionBarcodeScanner(
                isPresented: $showBarcodeScanner,
                onResult: { result in
                    if let result = result {
                        formState.setValue(result, for: field.id)
                    }
                },
                onError: { error in
                    formState.addError(error.localizedDescription, for: field.id)
                },
                hint: field.barcodeHint,
                supportedTypes: field.supportedBarcodeTypes
            )
        }
        .sheet(isPresented: $showOCRScanner) {
            // Extract hint and types from field (backward compatibility)
            FieldActionOCRScanner(
                isPresented: $showOCRScanner,
                onResult: { result in
                    if let result = result {
                        formState.setValue(result, for: field.id)
                    }
                },
                onError: { error in
                    formState.addError(error.localizedDescription, for: field.id)
                },
                hint: field.ocrHint,
                validationTypes: field.ocrValidationTypes
            )
        }
    }
    
    // MARK: - Single Action Rendering
    
    /// Render single action as button
    @ViewBuilder
    private func singleActionButton(action: any FieldAction) -> some View {
        Button(action: {
            Task {
                await performAction(action)
            }
        }) {
            Image(systemName: action.icon)
                .foregroundColor(.blue)
        }
        .buttonStyle(.borderless)
        .disabled(actionLoadingState[action.id] == true)
        .accessibilityLabel(action.accessibilityLabel)
        .accessibilityHint(action.accessibilityHint)
        .overlay {
            if actionLoadingState[action.id] == true {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .automaticCompliance(named: "FieldActionButton")
    }
    
    // MARK: - Multiple Actions Rendering
    
    /// Render multiple actions horizontally (when count <= maxVisibleActions)
    @ViewBuilder
    private func horizontalActionButtons(actions: [any FieldAction]) -> some View {
        platformHStackContainer(spacing: 8) {
            ForEach(Array(actions.enumerated()), id: \.offset) { index, action in
                singleActionButton(action: action)
            }
        }
        .automaticCompliance(named: "FieldActionButtons")
    }
    
    /// Render actions in menu (when count > maxVisibleActions or useActionMenu is true)
    @ViewBuilder
    private func actionMenu(actions: [any FieldAction]) -> some View {
        #if os(watchOS)
        // Menu is unavailable on watchOS; fall back to inline action buttons.
        horizontalActionButtons(actions: actions)
        #else
        Menu {
            ForEach(Array(actions.enumerated()), id: \.offset) { index, action in
                Button(action: {
                    Task {
                        await performAction(action)
                    }
                }) {
                    Label(action.label, systemImage: action.icon)
                }
                .disabled(actionLoadingState[action.id] == true)
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .foregroundColor(.blue)
        }
        .accessibilityLabel("Field actions")
        .accessibilityHint("Tap to see available actions for this field")
        .automaticCompliance(named: "FieldActionMenu")
        #endif
    }
    
    // MARK: - Action Execution
    
    /// Perform action with loading state and error handling
    private func performAction(_ action: any FieldAction) async {
        actionLoadingState[action.id] = true
        actionErrors.removeValue(forKey: action.id)
        
        do {
            let result = try await action.perform(
                fieldId: field.id,
                currentValue: formState.getValue(for: field.id),
                formState: formState
            )
            
            // Update field value if action returned one
            if let newValue = result {
                formState.setValue(newValue, for: field.id)
            }
            
            actionLoadingState[action.id] = false
        } catch let error as FieldActionError {
            // Handle special field action errors
            switch error {
            case .scanningRequiresUI(let type, let hint, let supportedTypes, let validationTypes):
                // Present scanning UI based on type
                await presentScanningUI(
                    type: type,
                    hint: hint,
                    supportedTypes: supportedTypes,
                    validationTypes: validationTypes
                )
            }
            actionLoadingState[action.id] = false
        } catch {
            actionErrors[action.id] = error
            actionLoadingState[action.id] = false
            
            // Add error to form state for display
            let errorMessage = error.localizedDescription
            formState.addError(errorMessage, for: field.id)
        }
    }
    
    /// Present scanning UI for barcode or OCR
    private func presentScanningUI(
        type: FieldActionError.ScanningType,
        hint: String?,
        supportedTypes: [BarcodeType]?,
        validationTypes: [TextType]?
    ) async {
        switch type {
        case .barcode:
            showBarcodeScanner = true
        case .ocr:
            showOCRScanner = true
        }
    }
}

// MARK: - Helper Extension for Action Arrays

@MainActor
extension Array where Element == any FieldAction {
    /// Get action by ID
    func first(whereId id: String) -> (any FieldAction)? {
        return self.first { $0.id == id }
    }
}
