# Issue #167: Layer 2 platform* Methods - Accessibility Inventory

**Status**: Phase 1 - Inventory & Analysis (In Progress)  
**Created**: 2026-01-26  
**Parent Issue**: #165

## Summary

- **Total Layer 2 Functions**: 4 functions (OCR layout functions)
- **Return Type**: All return `OCRLayout` (data structure, not View)
- **Accessibility Status**: ✅ **N/A** - Functions don't return Views, so no `.automaticCompliance()` needed
- **RealUI Test App Examples**: ✅ Examples exist (4/4 functions)
- **Example Views Need Accessibility**: ✅ To be verified (example views that use these functions)

## Functions by Category

### OCR Layout Functions (4 functions)

1. `platformOCRLayout_L2` - Generic OCR layout decision
2. `platformDocumentOCRLayout_L2` - Document-specific OCR layout
3. `platformReceiptOCRLayout_L2` - Receipt-specific OCR layout
4. `platformBusinessCardOCRLayout_L2` - Business card-specific OCR layout

## Next Steps

### Phase 1: Inventory & Analysis (In Progress)
- [x] Create comprehensive list of all Layer 2 `platform*_L2` functions
- [ ] Verify function signatures and return types
- [ ] Identify which functions already have accessibility support
- [ ] Identify which functions are missing accessibility support
- [ ] Document current RealUI test app coverage for Layer 2

### Phase 2: RealUI Test App Expansion
- [ ] Add one example for each Layer 2 function
- [ ] Ensure examples demonstrate realistic OCR layout scenarios
- [ ] Add accessibility verification helpers for Layer 2 examples

### Phase 3: Accessibility Implementation
- [ ] Add accessibility support to Layer 2 functions missing it
- [ ] Ensure automatic accessibility identifier generation works
- [ ] Add accessibility labels where missing
- [ ] Add accessibility hints where appropriate
- [ ] Set correct accessibility traits
- [ ] Verify dynamic type support
- [ ] Verify high contrast support

### Phase 4: Comprehensive Testing
- [ ] Create test suite for Layer 2 accessibility identifiers
- [ ] Create test suite for Layer 2 accessibility labels
- [ ] Create test suite for Layer 2 accessibility hints
- [ ] Create test suite for Layer 2 accessibility traits
- [ ] Create test suite for Layer 2 VoiceOver compatibility
- [ ] Create test suite for Layer 2 Switch Control compatibility
- [ ] Create test suite for Layer 2 dynamic type support
- [ ] Create test suite for Layer 2 high contrast support
- [ ] Create test suite for Layer 2 cross-platform consistency

### Phase 5: Documentation
- [ ] Document accessibility features for each Layer 2 function
- [ ] Update Layer 2 accessibility testing guide
- [ ] Update RealUI test app documentation for Layer 2
