# Issue #190 — Photo capture tabbed flow: verification

## What to verify

When the **system camera drops** after many retakes (e.g. ~10 Retake taps in the camera preview):

1. **Does the user stay in the tabbed flow?**  
   (Camera | Library tabs still visible at top; not dropped back to the form.)

2. **Can they get back to the camera by tapping the Camera tab?**  
   (Tapping Camera again shows a fresh camera picker.)

## How to test

1. In an app that uses `platformPhotoCapture_L1` with both camera and library available (e.g. CarManagerML or the framework test app), open photo capture. You should see the tabbed UI (Camera | Library).
2. Ensure you're on the Camera tab. Take a photo, tap **Retake** repeatedly (aim for ~10+ times).
3. Observe:
   - **If you stay in the tabbed flow:** Tab bar remains visible. Content area may go blank or show library. Tap **Camera** again → confirm a fresh camera appears.
   - **If you're dropped out:** You're back on the form/screen that presented photo capture. The tabbed flow was dismissed.

## Result

- [ ] **Stays in tabbed flow** — user can tap Camera again to retry. (Expected with current implementation.)
- [ ] **Dropped to form** — whole sheet dismissed; would need different mitigation.

*Update this section after manual test and, if needed, close or update Issue #190.*
