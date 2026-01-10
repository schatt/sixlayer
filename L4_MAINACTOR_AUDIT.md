# L4 Functions @MainActor Audit

## Audit Date
2025-01-XX

## Principle
**L4 functions create view components (parts of views), not complete views. They should NOT require @MainActor unless they directly interact with system APIs that require the main thread.**

## Categories

### Category 1: View-Returning Functions (Should NOT have @MainActor)

These functions return `some View` - they create view components. Views are value types and don't require @MainActor for creation.

#### Photo Components
- ✅ `platformPhotoPicker_L4` - **HAS @MainActor** ❌ Should remove
- ✅ `platformCameraInterface_L4` - **HAS @MainActor** ❌ Should remove
- ✅ `platformPhotoDisplay_L4` - **HAS @MainActor** ❌ Should remove
- ✅ `platformCameraPreview_L4` - **HAS @MainActor** ❌ Should remove

#### Map Components
- ✅ `platformMapView_L4` (2 overloads) - **HAS @MainActor** ❌ Should remove
- ✅ `platformMapViewWithCurrentLocation_L4` - **HAS @MainActor** ❌ Should remove

#### CloudKit Components
- ✅ `platformCloudKitSyncStatus_L4` - **NO @MainActor** ✅ Correct
- ✅ `platformCloudKitProgress_L4` - **HAS @MainActor** ❌ Should remove (calls other view functions)
- ✅ `platformCloudKitAccountStatus_L4` - **NO @MainActor** ✅ Correct
- ✅ `platformCloudKitServiceStatus_L4` - **HAS @MainActor** ❌ Should remove (calls other view functions)
- ✅ `platformCloudKitSyncButton_L4` - **HAS @MainActor** ❌ Should remove (Button is value type)
- ✅ `platformCloudKitStatusBadge_L4` - **HAS @MainActor** ❌ Should remove (Group/Image are value types)

#### OCR Components (Deprecated)
- ✅ `platformOCRImplementation_L4` - **HAS @MainActor** ❌ Should remove (deprecated, but still)
- ✅ `platformTextExtraction_L4` - **HAS @MainActor** ❌ Should remove (deprecated, but still)
- ✅ `platformTextRecognition_L4` - **HAS @MainActor** ❌ Should remove (deprecated, but still)

#### Navigation
- ✅ `platformImplementNavigationStack_L4` - **HAS @MainActor** ❌ Should remove (returns AnyView, value type)
- ✅ `platformImplementNavigationStackItems_L4` - **HAS @MainActor** ❌ Should remove (returns some View, value type)

### Category 2: System API Functions (May need @MainActor)

These functions interact with system APIs that require main thread access.

#### Notifications
- ⚠️ `platformRegisterForRemoteNotifications_L4` - **HAS @MainActor** ✅ **KEEP** (calls UIApplication.shared/NSApplication.shared)

#### Share/Clipboard
- ⚠️ `platformCopyToClipboard_L4` - **HAS @MainActor** ✅ **KEEP** (accesses UIPasteboard/NSPasteboard, UINotificationFeedbackGenerator)
- ⚠️ `platformOpenURL_L4` - **HAS @MainActor** ✅ **KEEP** (calls UIApplication.shared.open/NSWorkspace.shared.open)

#### Print
- ⚠️ `platformPrint_L4` - **HAS @MainActor** ✅ **KEEP** (calls platform print APIs that require main thread)

## Summary

### Functions Removed @MainActor (View Components - No Main-Actor Access)
1. ✅ `platformPhotoPicker_L4` - Removed
2. ✅ `platformCameraInterface_L4` - Removed
3. ✅ `platformPhotoDisplay_L4` - Removed
4. ✅ `platformCameraPreview_L4` - Removed
5. ✅ `platformMapView_L4` (both overloads) - Removed
6. ✅ `platformMapViewWithCurrentLocation_L4` - Removed
7. ✅ `platformOCRImplementation_L4` (deprecated) - Removed
8. ✅ `platformTextExtraction_L4` (deprecated) - Removed
9. ✅ `platformTextRecognition_L4` (deprecated) - Removed
10. ✅ `platformImplementNavigationStack_L4` - Removed
11. ✅ `platformImplementNavigationStackItems_L4` - Removed
12. ✅ `PlatformPhotoComponentsLayer4` enum - Removed
13. ✅ `PlatformMapComponentsLayer4` enum - Removed
14. ✅ `View` extension for container methods - Removed
15. ✅ Global container wrapper functions - Removed

### Functions Kept @MainActor (Access Main-Actor Isolated Properties/APIs)
1. ✅ `platformRegisterForRemoteNotifications_L4` - Accesses UIApplication/NSApplication
2. ✅ `platformCopyToClipboard_L4` - Accesses UIPasteboard/NSPasteboard, UINotificationFeedbackGenerator
3. ✅ `platformOpenURL_L4` - Accesses UIApplication.shared/NSWorkspace.shared
4. ✅ `platformPrint_L4` - Accesses NSApplication.shared.keyWindow
5. ✅ `platformCloudKitProgress_L4` - Accesses @Published properties via platformVStackContainer
6. ✅ `platformCloudKitServiceStatus_L4` - Accesses @Published properties (accountStatus, syncStatus, etc.)
7. ✅ `platformCloudKitSyncButton_L4` - Accesses @Published properties and calls service.sync()
8. ✅ `platformCloudKitStatusBadge_L4` - Accesses @Published properties (syncStatus)

### Key Finding
Functions that access `@Published` properties from `ObservableObject` types (like `CloudKitService`) require `@MainActor` because `@Published` properties are main-actor isolated.

### Functions Already Correct (No @MainActor)
1. `platformCloudKitSyncStatus_L4` ✅
2. `platformCloudKitAccountStatus_L4` ✅

## Action Items
1. Remove @MainActor from all view-returning L4 functions
2. Verify system API functions actually need @MainActor (they likely do)
3. Test compilation after changes
4. Update documentation if needed
