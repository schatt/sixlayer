//
//  FormUsageExample.swift
//  SixLayerFramework
//
//  Example showing how to use the fixed form implementation
//

import SwiftUI

/// Example showing how to use the fixed form implementation
public struct FormUsageExample: View {
    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var age = ""
    @State private var country = ""
    @State private var interests: [String] = []
    @State private var isSubscribed = false
    @State private var rating = "0"
    @State private var comments = ""
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            // MARK: - DEPRECATED: SimpleFormView uses GenericFormField which has been deprecated
            // TODO: Replace with DynamicFormView using DynamicFormField
            Text("Form functionality temporarily disabled - needs DynamicFormField migration")
                .foregroundColor(.secondary)
                .padding()
            .navigationTitle("User Registration")
        }
        .automaticCompliance(named: "FormUsageExample")
    }
    
    // MARK: - Form Field Creation
    
    private func createFormFields() -> [DynamicFormField] {
        // MARK: - DEPRECATED: This function uses GenericFormField which has been deprecated
        // TODO: Replace with DynamicFormField equivalents
        return []
        
        /*
        return [
            // Name field (required text)
            DynamicFormField(
                id: "fullName",
                contentType: .textarea,
                label: "Full Name",
                placeholder: "Enter your full name",
                isRequired: true,
                validationRules: [
                    "minLength": "2",
                    "maxLength": "50"
                ]
            ),
            
            // Email field (required email)
            let i18n = InternationalizationService()
            GenericFormField(
                label: "Email Address",
                placeholder: "Enter your email",
                value: $email,
                isRequired: true,
                fieldType: .email,
                validationRules: [
                    ValidationRule(rule: .email, message: i18n.localizedString(for: "SixLayerFramework.validation.email"))
                ]
            ),
            
            // Phone field (optional phone)
            GenericFormField(
                label: "Phone Number",
                placeholder: "Enter your phone number",
                value: $phone,
                isRequired: false,
                fieldType: .phone,
                validationRules: [
                    ValidationRule(rule: .phone, message: i18n.localizedString(for: "SixLayerFramework.validation.phone"))
                ]
            ),
            
            // Age field (required number)
            GenericFormField(
                label: "Age",
                placeholder: "Enter your age",
                value: $age,
                isRequired: true,
                fieldType: .number,
                validationRules: [
                    ValidationRule(rule: .custom { value in
                        guard let age = Int(value) else { return false }
                        return age >= 13 && age <= 120
                    }, message: "Age must be between 13 and 120")
                ]
            ),
            
            // Country selection (required select)
            GenericFormField(
                label: "Country",
                placeholder: i18n.localizedString(for: "SixLayerFramework.form.placeholder.selectCountry"),
                value: $country,
                isRequired: true,
                fieldType: .select,
                options: ["United States", "Canada", "United Kingdom", "Australia", "Germany", "France", "Japan", "Other"]
            ),
            
            // Interests (optional multiselect)
            GenericFormField(
                label: "Interests",
                placeholder: i18n.localizedString(for: "SixLayerFramework.form.placeholder.selectCategory"),
                value: Binding(
                    get: { interests.joined(separator: ",") },
                    set: { interests = $0.split(separator: ",").map(String.init) }
                ),
                isRequired: false,
                fieldType: .multiselect,
                options: ["Technology", "Sports", "Music", "Travel", "Cooking", "Reading", "Gaming", "Art"]
            ),
            
            // Newsletter subscription (checkbox)
            GenericFormField(
                label: "Subscribe to Newsletter",
                placeholder: "Receive updates via email",
                value: Binding(
                    get: { isSubscribed ? "true" : "false" },
                    set: { isSubscribed = $0 == "true" }
                ),
                isRequired: false,
                fieldType: .checkbox
            ),
            
            // Rating (range slider)
            GenericFormField(
                label: "How would you rate our service?",
                placeholder: "Rate from 1 to 10",
                value: $rating,
                isRequired: false,
                fieldType: .range
            ),
            
            // Comments (textarea)
            GenericFormField(
                label: "Additional Comments",
                placeholder: "Any additional comments or feedback",
                value: $comments,
                isRequired: false,
                fieldType: .textarea,
                validationRules: [
                    ValidationRule(rule: .maxLength(500), message: "Comments must be less than 500 characters")
                ]
            )
        ]
        */
    }
    
    // MARK: - Presentation Hints
    
    private func createPresentationHints() -> PresentationHints {
        var hints = PresentationHints()
        hints.customPreferences["formTitle"] = "User Registration Form"
        return hints
    }
    
    // MARK: - Form Handlers
    
    private func handleFormSubmission(_ formData: [String: String]) {
        print("Form submitted with data:")
        for (key, value) in formData {
            print("  \(key): \(value)")
        }
        
        // Here you would typically:
        // 1. Send data to your API
        // 2. Save to local storage
        // 3. Navigate to next screen
        // 4. Show success message
        
        // Example: Show success alert
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // In a real app, you'd show an alert or navigate
            print("✅ Form submitted successfully!")
        }
    }
    
    private func handleFormReset() {
        print("Form reset")
        // Additional reset logic if needed
    }
}

// MARK: - Preview

#if DEBUG
struct FormUsageExample_Previews: PreviewProvider {
    static var previews: some View {
        FormUsageExample()
    }
}
#endif
