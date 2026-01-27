# Issue #168: Layer 3 platform* Methods - Accessibility Inventory

**Status**: Phase 1 - Inventory & Analysis (In Progress)  
**Created**: 2026-01-26  
**Parent Issue**: #165

## Summary

- **Total Layer 3 Functions**: 7 functions (OCR strategy functions)
- **Return Type**: All return `OCRStrategy` (data structure, not View)
- **Accessibility Status**: ✅ **N/A** - Functions don't return Views, so no `.automaticCompliance()` needed
- **RealUI Test App Examples**: ✅ Examples exist (7/7 functions)
- **Example Views Need Accessibility**: ✅ In progress (adding `.automaticCompliance()` to all example views)

## Functions by Category

### OCR Strategy Functions (7 functions)

1. `platformOCRStrategy_L3` - Generic OCR strategy selection
2. `platformDocumentOCRStrategy_L3` - Document-specific OCR strategy
3. `platformReceiptOCRStrategy_L3` - Receipt-specific OCR strategy
4. `platformBusinessCardOCRStrategy_L3` - Business card-specific OCR strategy
5. `platformInvoiceOCRStrategy_L3` - Invoice-specific OCR strategy
6. `platformOptimalOCRStrategy_L3` - Optimal OCR strategy selection
7. `platformBatchOCRStrategy_L3` - Batch OCR strategy selection

## Next Steps

### Phase 1: Inventory & Analysis (In Progress)
- [x] Create comprehensive list of all Layer 3 `platform*_L3` functions
- [ ] Verify function signatures and return types
- [ ] Identify which functions already have accessibility support
- [ ] Identify which functions are missing accessibility support
- [ ] Document current RealUI test app coverage for Layer 3

### Phase 2: RealUI Test App Expansion
- [ ] Add one example for each Layer 3 function
- [ ] Ensure examples demonstrate realistic OCR strategy selection scenarios
- [ ] Add accessibility verification helpers for Layer 3 examples

### Phase 3: Accessibility Implementation
- [ ] Add accessibility support to Layer 3 functions missing it
- [ ] Ensure automatic accessibility identifier generation works
- [ ] Add accessibility labels where missing
- [ ] Add accessibility hints where appropriate
- [ ] Set correct accessibility traits
- [ ] Verify dynamic type support
- [ ] Verify high contrast support

### Phase 4: Comprehensive Testing
- [ ] Create test suite for Layer 3 accessibility identifiers
- [ ] Create test suite for Layer 3 accessibility labels
- [ ] Create test suite for Layer 3 accessibility hints
- [ ] Create test suite for Layer 3 accessibility traits
- [ ] Create test suite for Layer 3 VoiceOver compatibility
- [ ] Create test suite for Layer 3 Switch Control compatibility
- [ ] Create test suite for Layer 3 dynamic type support
- [ ] Create test suite for Layer 3 high contrast support
- [ ] Create test suite for Layer 3 cross-platform consistency

### Phase 5: Documentation
- [ ] Document accessibility features for each Layer 3 function
- [ ] Update Layer 3 accessibility testing guide
- [ ] Update RealUI test app documentation for Layer 3
