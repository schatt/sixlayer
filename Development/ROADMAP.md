# 🚀 Six-Layer Framework Development Roadmap

**Purpose**: Track planned upcoming work and future enhancements.  
**Last Updated**: January 2, 2026  
**Current Release**: v6.6.3

> **Note**: This roadmap tracks planned work. For active todos, see [`todos.md`](../todos.md). For release history, see [`RELEASES.md`](RELEASES.md).

---

## 📍 **Current Status**

**Last Release**: v6.6.3 - ScrollView Wrapper Fixes  
**Current Phase**: Minor Release (Platform Capability Detection Fixes)  
**Next Phase**: Continue framework evolution and stability improvements

---

## 🎯 **Upcoming Work**

### **High Priority**

- [ ] **Optimize device capability detection** - Improve performance and accuracy of runtime capability detection
- [ ] **Improve error handling in layout engine** - Better error messages and recovery

### **Medium Priority**

- [ ] **Add more comprehensive error messages** - Improve developer experience with clearer error reporting
- [ ] **Improve test performance** - Optimize test suite execution time
- [ ] **Add code coverage reporting** - Track and report test coverage metrics
- [ ] **Framework Integration Testing** - Add comprehensive integration test suite

### **Low Priority**

- [ ] **Refactor common test utilities** - Consolidate and improve test helper functions
- [ ] **Add performance benchmarks** - Establish performance baselines and tracking
- [ ] **Improve documentation** - Enhance API documentation and usage examples

---

## 🚀 **Future Enhancements**

**Purpose**: Track potential future improvements that are not currently needed but may be valuable later.

### **Runtime Capability Detection**

#### **Reactive Capability Detection**
- [ ] **Reactive Capability Detection** - Make `RuntimeCapabilityDetection` properties reactive using `@Published` or Combine publishers
  - **Priority**: Low
  - **Status**: 📋 **DEFERRED** - Not currently needed, but worth tracking for future consideration
  - **Complexity**: Medium - Would require ObservableObject wrapper, Combine publishers, and notification handling
  - **Description**: Views would automatically update when capabilities change (e.g., Apple Pencil connection/disconnection)
  - **Rationale**: Currently, `supportsHover` and other capability properties are computed each time they're accessed, but views don't automatically refresh when capabilities change mid-session
  - **Use Case**: When a user connects/disconnects an Apple Pencil during app use, views would automatically adapt without requiring manual refresh
  - **Notes**: 
    - Current implementation works because views are recreated on state changes
    - New views get current capability state automatically
    - Would need to handle all capability changes (touch, haptic, hover, etc.), not just hover
    - Consider lightweight `@Published` capability manager or Combine publisher approach

---

## 📋 **Roadmap Entry Format**

When adding items to this roadmap:

1. **Link to GitHub issues** - Use `[#123](https://github.com/schatt/6layer/issues/123)` format
2. **Include priority** - High, Medium, or Low
3. **Add status** - Use checkboxes `[ ]` for planned, `[x]` for completed
4. **Provide context** - Brief description, rationale, and complexity assessment

**Example**:
```markdown
- [ ] **Feature Name** [#123](https://github.com/schatt/6layer/issues/123) - Brief description
  - **Priority**: High
  - **Status**: Planned
  - **Complexity**: Medium
  - **Notes**: Additional context or dependencies
```

---

**Last Updated**: January 2, 2026  
**Next Review**: After next release

