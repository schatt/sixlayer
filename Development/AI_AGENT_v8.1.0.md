# AI Agent Guide - SixLayer Framework v8.1.0

**Version**: v8.1.0  
**Release Date**: July 7, 2026  
**Release Type**: Minor

---

## 🎯 What's in v8.1.0

v8.1.0 ships **ViewInspector 0.10.x test infrastructure**: hosted accessibility identifier collection (#314), **`SixLayerViewInspectorTestKit`** for consumers (#327), typed inspect helper fixes (#326), and **Inspectable conformance removal** (#328). Field actions default to inline OCR/barcode buttons with menu only on overflow.

### Key points for AI agents

1. **ViewInspectorTestKit:** Use the public `SixLayerViewInspectorTestKit` product for `inspectView`, `withInspectedView`, and `firstVStackInHierarchy` — deep hierarchy walks stay in SixLayer's test target, not the kit (#327).
2. **No Inspectable conformances:** Do not add `extension Foo: ViewInspector.Inspectable {}`; ViewInspector 0.10 inspects via reflection (#328).
3. **Accessibility probes:** Prefer hosted identifier collection (`AccessibilityTestUtilities`, `BaseTestClass` helpers) for a11y contract tests; use typed ViewInspector for structure; XCUITest only when the system tree is required (#314).
4. **Overload preference:** When a view is type-erased, use AnyView/ClassifiedView overloads or `*Unwrapped` helpers — typed `view(V.self)` paths are disfavored where erasure applies (#326).
5. **Field actions:** Default inline layout; set `useActionMenu: true` only for overflow menu UX.

---

## 🔗 Related docs

- [RELEASE_v8.1.0.md](RELEASE_v8.1.0.md) — Release notes  
- [AI_AGENT.md](AI_AGENT.md) — Main AI agent index  
- `Framework/ViewInspectorTestKit/Sources/README.md` — TestKit inspection policy  

---

**For full framework guidance, start at [AI_AGENT.md](AI_AGENT.md).**
