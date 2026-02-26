# Issue #190 — Photo capture tabbed flow: verification

## What to verify

When the **system camera drops** after many retakes (e.g. ~10 Retake taps in the camera preview):

1. **Does the user stay in the tabbed flow?**  
   (Camera | Library tabs still visible at top; not dropped back to the form.)

2. **Can they get back to the camera by tapping the Camera tab?**  
   (Tapping Camera again shows a fresh camera picker.)

## How to test

1. In an app that uses `platformPhotoCapture_L1` with both camera and library available (e.g. CarManagerML or the framework test app), open photo capture. You should see the tabbed UI (Camera | Library).
2. *(Optional)* To see what the camera picker does when it becomes unstable: set environment variable `SLF_DEBUG_PHOTO_CAPTURE=1` in the app scheme (Edit Scheme → Run → Arguments → Environment Variables). The framework logs to console when the picker delegate is called:
   - `didFinishPickingMediaWithInfo` — user tapped Use Photo.
   - `imagePickerControllerDidCancel` — user tapped Cancel, or **the system dismissed the picker** (e.g. after instability). If you see this when the camera "drops" without tapping Cancel, the picker dismissed itself; our code only dismisses the picker, not the sheet, so you should stay in the tabbed flow.
3. Ensure you're on the Camera tab. Take a photo, tap **Retake** repeatedly (aim for ~10+ times).
4. Observe:
   - **If you stay in the tabbed flow:** Tab bar remains visible. Content area may go blank or show library. Tap **Camera** again → confirm a fresh camera appears.
   - **If you're dropped out:** You're back on the form/screen that presented photo capture. The tabbed flow was dismissed.
   - **Console:** If you enabled `SLF_DEBUG_PHOTO_CAPTURE`, check whether `imagePickerControllerDidCancel` was logged when the drop happened. If yes, the picker dismissed itself (we stay in tabbed flow). If no delegate call and you're on the form, something else dismissed the sheet.

## Result

- [ ] **Stays in tabbed flow** — user can tap Camera again to retry. (Expected with current implementation.)
- [ ] **Dropped to form** — whole sheet dismissed; would need different mitigation.

*Update this section after manual test and, if needed, close or update Issue #190.*
