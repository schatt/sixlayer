import SwiftUI

// MARK: - Platform Forms Layer 4: Layout Implementation
/// This layer provides platform-specific form components that implement
/// form patterns across iOS and macOS. This layer handles the specific
/// implementation of form components.

public extension View {
    
    // MARK: - Form Section
    // Note: platformFormSection functions are now defined in PlatformSpecificViewExtensions.swift
    // to avoid ambiguity with multiple overloads. Use those instead.
    
    /// Platform-specific form field with consistent styling
    /// Provides standardized form field appearance across platforms
    func platformFormField<Content: View>(
        label: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        platformVStackContainer(alignment: .leading, spacing: 8) {
            if let label = label {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.platformLabel)
            }
            content()
        }
        .padding(.vertical, 4)
        .environment(\.accessibilityIdentifierLabel, label ?? "") // TDD GREEN: Pass label to identifier generation
        .automaticCompliance(named: "platformFormField")
    }
    
    /// Platform-specific form field group for related fields
    /// Groups related fields with visual separation
    func platformFormFieldGroup<Content: View>(
        title: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        platformVStackContainer(alignment: .leading, spacing: 12) {
            if let title = title {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color.platformLabel)
                    .padding(.horizontal, 4)
            }
            
            platformVStackContainer(spacing: 8) {
                content()
            }
            .padding()
            .background(Color.platformSecondaryBackground)
            .cornerRadius(8)
        }
        .environment(\.accessibilityIdentifierLabel, title ?? "") // TDD GREEN: Pass label to identifier generation
        .automaticCompliance(named: "platformFormFieldGroup")
    }
    
    /// Platform-specific validation message with consistent styling
    /// Provides standardized validation message appearance across platforms
    func platformValidationMessage(
        _ message: String,
        type: ValidationType = .error
    ) -> some View {
        platformHStackContainer(spacing: 4) {
            Image(systemName: type.iconName)
                .foregroundColor(type.color)
                .font(.caption)
            
            Text(message)
                .font(.caption)
                .foregroundColor(type.color)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(type.color.opacity(0.1))
        .cornerRadius(4)
        .environment(\.accessibilityIdentifierLabel, message) // TDD GREEN: Pass label to identifier generation
        .automaticCompliance(named: "platformValidationMessage")
    }
    
    /// Platform-specific form divider with consistent styling
    /// Provides visual separation between form sections
    func platformFormDivider() -> some View {
        Rectangle()
            .fill(Color.platformSeparator)
            .frame(height: 1)
            .padding(.vertical, 8)
            .automaticCompliance(named: "platformFormDivider")
    }
    
    /// Platform-specific form spacing with consistent sizing
    /// Provides standardized spacing between form elements
    func platformFormSpacing(_ size: FormSpacing) -> some View {
        Spacer()
            .frame(height: size.rawValue)
            .automaticCompliance()
    }

    /// Layer 4 date input primitive that hides platform availability differences.
    func platformDateInput(
        selection: Binding<Date>,
        label: String
    ) -> some View {
        platformDatePicker(selection: selection) {
            EmptyView()
        }
        .selfLabelingControl(label: label)
    }

    /// Layer 4 time input primitive that hides platform availability differences.
    func platformTimeInput(
        selection: Binding<Date>,
        label: String
    ) -> some View {
        #if os(tvOS)
        Text(selection.wrappedValue, format: .dateTime.hour().minute())
            .foregroundStyle(.secondary)
            .selfLabelingControl(label: label)
        #elseif os(watchOS)
        Text(selection.wrappedValue, format: .dateTime.hour().minute())
            .foregroundStyle(.secondary)
            .selfLabelingControl(label: label)
        #else
        DatePicker("", selection: selection, displayedComponents: .hourAndMinute)
            .datePickerStyle(.compact)
            .selfLabelingControl(label: label)
        #endif
    }

    /// Layer 4 date-time input primitive that hides platform availability differences.
    func platformDateTimeInput(
        selection: Binding<Date>,
        label: String
    ) -> some View {
        #if os(tvOS)
        Text(selection.wrappedValue, format: .dateTime.year().month().day().hour().minute())
            .foregroundStyle(.secondary)
            .selfLabelingControl(label: label)
        #elseif os(watchOS)
        Text(selection.wrappedValue, format: .dateTime.year().month().day().hour().minute())
            .foregroundStyle(.secondary)
            .selfLabelingControl(label: label)
        #else
        DatePicker("", selection: selection, displayedComponents: [.date, .hourAndMinute])
            .datePickerStyle(.compact)
            .selfLabelingControl(label: label)
        #endif
    }

    /// Layer 4 stepper primitive that degrades on platforms without Stepper.
    func platformStepperInput(
        label: String,
        value: Binding<Double>,
        in range: ClosedRange<Double>,
        step: Double = 1.0
    ) -> some View {
        #if os(tvOS)
        Text("\(Int(value.wrappedValue))")
            .foregroundStyle(.secondary)
            .selfLabelingControl(label: label)
        #else
        Stepper(label, value: value, in: range, step: step)
        #endif
    }

    /// Layer 4 color picker primitive that degrades on platforms without ColorPicker.
    func platformColorInput(
        label: String,
        selection: Binding<Color>
    ) -> some View {
        #if os(tvOS) || os(watchOS)
        Text(label)
            .foregroundStyle(selection.wrappedValue)
        #else
        ColorPicker("", selection: selection)
            .selfLabelingControl(label: label)
        #endif
    }

    /// Layer 4 range input primitive that degrades on platforms without Slider.
    func platformRangeInput(
        value: Binding<Double>,
        in range: ClosedRange<Double>
    ) -> some View {
        #if os(tvOS)
        ProgressView(value: value.wrappedValue, total: range.upperBound)
        #else
        Slider(value: value, in: range)
        #endif
    }

    /// Layer 4 gauge primitive that degrades to a progress view where needed.
    @ViewBuilder
    func platformGaugeInput(
        value: Double,
        min: Double,
        max: Double,
        label: String? = nil,
        style: String? = nil
    ) -> some View {
        let range = min...max
        #if os(tvOS)
        platformVStackContainer(alignment: .leading) {
            ProgressView(value: value, total: max)
                .progressViewStyle(.linear)
            Text("\(Int(value)) / \(Int(max))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        #else
        if #available(iOS 16.0, macOS 13.0, *) {
            if style == "circular" {
                Gauge(value: value, in: range) {
                    if let label {
                        Text(label)
                    }
                } currentValueLabel: {
                    Text("\(Int(value))")
                } minimumValueLabel: {
                    Text("\(Int(min))")
                } maximumValueLabel: {
                    Text("\(Int(max))")
                }
                .gaugeStyle(.accessoryCircularCapacity)
            } else {
                Gauge(value: value, in: range) {
                    if let label {
                        Text(label)
                    }
                } currentValueLabel: {
                    Text("\(Int(value))")
                } minimumValueLabel: {
                    Text("\(Int(min))")
                } maximumValueLabel: {
                    Text("\(Int(max))")
                }
                .gaugeStyle(.linearCapacity)
            }
        } else {
            platformVStackContainer(alignment: .leading) {
                ProgressView(value: value, total: max)
                    .progressViewStyle(.linear)
                Text("\(Int(value)) / \(Int(max))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        #endif
    }
}

// MARK: - Form container (Layer 4)

/// Resolves ``FormStrategy`` into a concrete form container. File-scope API so call sites use trailing-closure syntax without a dummy `View` receiver.
@MainActor
func platformFormContainer_L4<Content: View>(
    strategy: FormStrategy,
    @ViewBuilder content: @escaping () -> Content
) -> some View {
    switch strategy.containerType {
    case .form:
        return AnyView(
            Form {
                content()
            }
            .background(Color.platformGroupedBackground)
        )

    case .standard:
        let spacing: CGFloat = {
            switch strategy.fieldLayout {
            case .compact: return 8
            case .standard: return 16
            case .spacious: return 20
            case .adaptive: return 16
            case .vertical: return 16
            case .horizontal: return 12
            case .grid: return 20
            }
        }()
        return AnyView(
            platformVStackContainer(spacing: spacing) {
                content()
            }
            .padding()
            .background(Color.platformSecondaryBackground)
            .cornerRadius(8)
        )

    case .scrollView:
        let spacing: CGFloat = {
            switch strategy.fieldLayout {
            case .compact: return 8
            case .standard: return 16
            case .spacious: return 20
            case .adaptive: return 16
            case .vertical: return 16
            case .horizontal: return 12
            case .grid: return 20
            }
        }()

        return AnyView(
            ScrollView {
                platformVStackContainer(spacing: spacing) {
                    content()
                }
                .padding(.vertical)
            }
            .background(Color.platformGroupedBackground)
        )

    case .custom:
        let spacing: CGFloat = {
            switch strategy.fieldLayout {
            case .compact: return 8
            case .standard: return 16
            case .spacious: return 20
            case .adaptive: return 16
            case .vertical: return 16
            case .horizontal: return 12
            case .grid: return 20
            }
        }()
        return AnyView(
            platformVStackContainer(spacing: spacing) {
                content()
            }
            .padding()
            .background(Color.platformSecondaryBackground)
            .cornerRadius(8)
        )

    case .adaptive:
        let spacing: CGFloat = {
            switch strategy.fieldLayout {
            case .compact: return 8
            case .standard: return 16
            case .spacious: return 20
            case .adaptive: return 16
            case .vertical: return 16
            case .horizontal: return 12
            case .grid: return 20
            }
        }()
        return AnyView(
            platformVStackContainer(spacing: spacing) {
                content()
            }
            .padding()
            .background(Color.platformSecondaryBackground)
            .cornerRadius(12)
        )
    }
}

// MARK: - Validation Types

/// Validation message types for form fields
public enum ValidationType {
    case error, warning, success, info
    
    var color: Color {
        switch self {
        case .error: return .red
        case .warning: return .orange
        case .success: return .green
        case .info: return .blue
        }
    }
    
    var iconName: String {
        switch self {
        case .error: return "exclamationmark.triangle.fill"
        case .warning: return "exclamationmark.triangle"
        case .success: return "checkmark.circle.fill"
        case .info: return "info.circle"
        }
    }
}

// MARK: - Form Spacing

/// Standardized form spacing values
public enum FormSpacing: CGFloat, CaseIterable {
    case small = 8
    case medium = 16
    case large = 24
    case extraLarge = 32
}
