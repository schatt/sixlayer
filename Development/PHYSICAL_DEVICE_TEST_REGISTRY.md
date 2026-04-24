# Physical device test registry

Tests that **should be re-run on real hardware periodically** (or before release when touching listed areas). **CI simulators** often cannot fully exercise these paths.

## How to use

1. When you add or change a test that depends on hardware, privacy, or drivers the **Simulator does not model**, add a row below.
2. Before a major release—or when editing the linked code—run the listed tests on the suggested **physical** device/OS.
3. Keep entries **specific** (test name + file path + why). Remove rows when a test is deleted or superseded.

| Test (name or suite) | File | Physical platform(s) | Why not sufficient in Simulator |
|----------------------|------|------------------------|----------------------------------|
| *(none registered yet)* | | | Add rows as capabilities are added. |

### Examples to add when applicable

- **Camera / capture / ARKit / LiDAR** — physical iPhone or iPad; Simulator camera stack and hardware differ.
- **Haptics / Taptic Engine** — physical device; Simulator reports limited or constant behavior.
- **NFC, Wallet passes, CarPlay in vehicle** — physical device or certified environment as required by Apple.
- **Push with production APNs entitlements** — device + proper provisioning (document in row when a test exists).

## Related

- Project testing footguns and thread-local overrides: [.cursor/rules/capability-override-test-flows.mdc](../.cursor/rules/capability-override-test-flows.mdc) (simulator vs device section; links back here).
