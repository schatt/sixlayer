# Real UI Tests

These are actual UI tests that render views in real windows to test:
- Actual view rendering and layout
- Full modifier execution (including EnvironmentAccessor.body)
- Layout calculations that only happen in window hierarchies
- Accessibility features that require actual windows
- Real user interactions (touch, hover, keyboard)

## Test Organization

- **macOS Tests**: Create `NSWindow` instances and render views
- **iOS Tests**: Create `UIWindow` instances and render views in simulator

## Key Differences from ViewInspector Tests

- **ViewInspector Tests** (in `UnitTests/ViewInspectorTests/`): Test view structure without rendering
- **Real UI Tests** (here): Test actual rendered UI in windows

Both test the same "blade" from different angles - structure vs. actual rendering.


