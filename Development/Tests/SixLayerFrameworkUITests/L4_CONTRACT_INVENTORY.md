# Layer 4 UI test contract inventory

Contract = **behavior** + **accessibility** (not a11y only). One test method per L4 API.

## Input / controls
- **platformButton**: Exists, identifier/label; tap invokes action.
- **platformTextField**: Exists, identifier/label; typing updates binding.
- **platformSecureField**: Exists, identifier/label; input works.
- **platformPicker**: Picker and options have identifiers; selection updates.
- **platformToggle**: Exists, identifier/label; toggling changes On/Off.
- **platformTextEditor**: Exists, identifier/label; text binding updates.
- **platformDatePicker**: Exists, identifier/label; date selection.

## Containers
- **platformVStack / platformVStackContainer**: Container exists; children findable.
- **platformForm / platformFormContainer / platformFormContainer_L4**: Form exists; content findable.
- **platformFormSection**: Section exists; header/content findable.
- **platformFormField**: Field exists; label + content findable.
- **platformFormFieldGroup**: Group exists; title + content findable.
- **platformSectionContainer**: Container exists; content findable.
- **platformListContainer**: List exists; content findable.
- **platformDisclosureGroup**: Expand/collapse toggles content.
- **platformStyledContainer_L4**: Container exists; content findable.
- **platformCardGrid / platformCardMasonry / platformCardList / platformCardAdaptive**: Cards or empty state findable.
- **platformHStack / platformZStack**: Same as VStack.

## Presentation
- **platformSheet_L4 / platformSheet**: Sheet content visible when presented; dismiss works.
- **platformPopover_L4**: Popover/sheet content visible when presented.
- **platformAlert**: Alert title/buttons visible when triggered.
- **platformConfirmationDialog**: Dialog visible when triggered.

## Navigation
- **platformNavigationTitle_L4**: Bar title visible.
- **platformNavigationTitleDisplayMode_L4**: Title mode applied; bar visible.
- **platformNavigationLink_L4**: Tap navigates; destination visible.
- **platformImplementNavigationStack_L4**: Stack wraps content; bar visible.
- **platformImplementNavigationStackItems_L4**: List + detail navigation.
- **platformNavigationSplitContainer_L4**: Split panes visible.
- **platformNavigationBarItems_L4**: Bar items visible.
- **platformNavigationBarBackButtonHidden**: Back hidden when true.
- **platformAppNavigation_L4**: Sidebar + detail visible.
- **platformSettingsContainer_L4**: Settings container visible.
- **platformNavigationButton_L4**: Nav button tap works.

## Photo / camera / map / CloudKit
- **platformPhotoPicker_L4**, **platformCameraInterface_L4**, **platformPhotoDisplay_L4**, **platformCameraPreview_L4**, **platformPhotoSourceTabbed_L4**: View or placeholder visible; a11y.
- **platformMapView_L4**, **platformMapViewWithCurrentLocation_L4**: Map or placeholder.
- **platformCloudKitSyncStatus_L4**, **platformCloudKitProgress_L4**, **platformCloudKitAccountStatus_L4**, **platformCloudKitServiceStatus_L4**, **platformCloudKitSyncButton_L4**, **platformCloudKitStatusBadge_L4**: View or placeholder.

## Share / clipboard / print / URL
- **platformCopyToClipboard_L4**: Copy trigger findable and tappable.
- **platformOpenURL_L4**: Call from button; no crash.
- **platformPrint_L4**: Print trigger available.
- **platformShare_L4**: Share trigger visible and tappable.

## Row actions / context menu / lists / split / styling / buttons / modals
- **platformRowActions_L4**: Swipe/right-click reveals actions.
- **platformContextMenu_L4**: Long-press/right-click reveals menu.
- **platformListRow**, **platformListEmptyState**, **platformListDetailContainer**, **platformSelectableListRow**, **platformDetailPlaceholder**: Row/empty/detail visible.
- **platformVerticalSplit_L4**, **platformHorizontalSplit_L4**: Panes visible.
- **platformBackground**, **platformPadding**, **platformCornerRadius**, **platformShadow**, **platformBorder**, **platformFont**, **platformFrame**, **platformFormStyle**, **platformContentSpacing**: View exists (modifier applied).
- **platformPrimaryButtonStyle**, **platformSecondaryButtonStyle**, **platformDestructiveButtonStyle**, **platformIconButton**: Button with style exists.
- **platformDismissEmbeddedSettings**, **platformDismissSheetSettings**, **platformDismissWindowSettings**: Dismiss available.
- **platformFormDivider**, **platformFormSpacing**, **platformValidationMessage**: Form elements.
- **platformRegisterForRemoteNotifications_L4**: No crash.
- **platformModalContainer_Form_L4**, **platformDetailViewFrame**, **platformFilePicker**, **platformExportSheet**, **platformHelpSheet**, **platformFormToolbar**, **platformDetailToolbar**: As per contract.

Implementation: one test method per API; contract UI in test app; single launch.
