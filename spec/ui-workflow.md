## Stampverse
**Path**: `lib/src/ui/stampverse`

### 1. Description
Goal: Build a local-first memory stamping experience with camera/gallery input and tabbed browsing.

Features:
- Create stamp via camera or file picker.
- Crop and shape selection (scallop/circle/square) before save.
- Save stamp metadata into local cache.
- Home tab system: Tem / Bộ sưu tập / Kỷ niệm / Chỉnh sửa / Cài đặt.
- Memory tab calendar view (month grid): each day shows first stamp thumbnail; empty day stays blank.
- Tap a day in Memory tab to open a bottom-sheet list of all stamps created in that day.
- Collection workflow: open a collection and browse stamps in that collection.
- Details workflow: view, download, share, delete.
- Data persistence: local cache on device (`SharedPreferences`) with no mandatory login flow.

### 2. UI Structure
- Screen: `StampversePage`
- Components:
  - `stampverse_home_view.dart`
  - `stampverse_camera_view.dart`
  - `stampverse_save_view.dart`
  - `stampverse_album_view.dart`
  - `stampverse_details_view.dart`
  - shared: `stampverse_stamp.dart`, `stampverse_icon_button.dart`, `stampverse_primary_button.dart`, `stampverse_text_styles.dart`

### 3. User Flow & Logic
1. App starts and `StampverseBloc.initialize()` loads cached stamps + collection cache from local storage.
2. App opens Home directly (local-first).
3. Home has 5 tabs:
   - `Stamp`: split into `Gần đây mở` (recently opened) and `Yêu thích` sections.
   - `Bộ sưu tập`: grouped by collection; tapping a group opens album view for that collection.
   - `Xưởng`: creative workspace with two internal modes.
     - Segment mode:
     - `Mẫu` (default): shows local template gallery with 3 sections:
       - `Chọn loại template`: category cards for `Classic Stamp Wall`, `Botanical Postage`, `Cute Anime`.
       - `Nổi bật`: hero card of selected category.
       - `Tất cả template`: grid of templates filtered by selected category.
       - Current category mapping rule:
         - Template #1 -> `Classic Stamp Wall`
         - Template #2 and #4 -> `Botanical Postage`
         - Template #3 -> `Cute Anime`
     - `Bộ ảnh của tôi`: shows existing board list with long-press multi-select delete.
     - Selecting a template auto-creates and saves a board, then opens editor immediately.
     - Template slot coordinates now use a common spec that supports both rect (`x1,y1 -> x2,y2 + rotation`) and quad (`x1,y1,x2,y2,x3,y3,x4,y4`) inputs; `Retro postage patchwork` is authored with quad points for higher placement accuracy.
     - Board editor behavior by mode:
       - `freeform` board (legacy): keeps old drag/scale/rotate/import behavior.
       - `template` board: mixed frame slots (`stamp scallop/circle/square/classic` + `plain rect/circle`) with per-slot add image flow (`Gallery máy` + saved `Stamp`), toolbar actions (`Xoá`, `Nhân bản`, `Khoá/Mở khoá`), and transform on each slot (move/zoom/rotate).
       - For template slot import:
         - choosing from gallery uses the selected gallery image directly.
         - choosing from saved stamp uses `sourceImageUrl` (original crop, not the already-stamped `imageUrl`) to avoid double clipping.
     - Template slot lock blocks move/zoom/rotate but still allows replacing image.
     - Each board still supports canvas background style (Grid / Dots / Paper), rename, share, and export.
   - `Kỷ niệm`: monthly calendar (`syncfusion_flutter_calendar`) where each day displays the first stamp of that day.
     - Tapping a day with stamps opens a detail list (bottom sheet) for all stamps in that date.
     - Tapping a day without stamps keeps calendar unchanged.
   - `Cài đặt`: local storage status + refresh/reset actions.
4. Tapping `+` opens source sheet: `Camera` or `File`.
5. Camera/File both go through crop/shape step before save.
6. Save screen allows:
   - auto-generated stamp name (editable),
   - collection input with quick-pick chips and create-new action (no forced date default),
   - save to local cache.
   - each saved stamp stores:
     - `imageUrl`: stamped output image (used in Stamp/Album/Collection tabs),
     - `sourceImageUrl`: original cropped image before stamp clipping (used in Template editor).
   - if collection is left empty, stamp is still saved and appears in `Tem`/`Kỷ niệm` without forcing a date-based collection.
7. Selecting a stamp opens Details.
8. Details supports:
   - mark/unmark favorite,
   - download to gallery,
   - share image,
   - delete (with confirmation) from local cache.

### 4. Key Dependencies
- State management: `flutter_bloc` (`StampverseBloc` + `StampverseState`)
- Dependency injection: GetX Binding (`StampverseBinding`)
- Local cache/session: `shared_preferences`
- Live camera: `camera`
- Image input: `image_picker`
- Stamp shape rendering: `path_drawing`
- Calendar UI: `syncfusion_flutter_calendar`
- Download/share: `image_gallery_saver_plus`, `share_plus`, `path_provider`
- Fonts: `google_fonts`
- Localization: GetX translation maps (`en/ja/vi`)

### 5. Notes & Known Issues
- Live camera uses `camera` package with in-app preview; gallery import still uses `image_picker`.
- Crop supports panning and zooming inside the selected stamp aperture.
- Current default behavior is local-first; server integration exists in repository/api layer but is not required for normal create/view/delete flow.

## System States
**Path**: `lib/src/ui/widgets` + `lib/src/ui/splash`

### 1. Description
Goal: Standardize cross-app system states so pages can reuse a consistent UI language for startup, async loading, and successful completion.

Features:
- Shared loading layout (`AppLoadingState`) with headline, helper text, and progress treatment.
- Shared success layout (`AppSuccessState`) with configurable icon colors and optional CTA action.
- Branded splash screen (`AppSplashState`) with app icon, tagline, and boot progress.
- `SplashPage` now composes `AppSplashState` instead of default spinner.
- `AppBody` default loading state now uses `AppLoadingState` for consistent behavior.
- `StampverseRegisterView` success branch now reuses `AppSuccessState`.

### 2. UI Structure
- Screen: `SplashPage`
- Shared widgets:
  - `app_loading_state.dart`
  - `app_success_state.dart`
  - `app_splash_state.dart`
  - `base/app_body.dart` (integration point)

### 3. User Flow & Logic
1. App boots into `SplashPage` and immediately renders `AppSplashState`.
2. Splash delay keeps current navigation behavior (2 seconds) and then routes to `AppPages.main`.
3. Any screen using `AppBody` with `PageState.loading` now gets a richer default loading experience.
4. Registration flow sets `isSuccess = true`, and the screen renders a reusable success state instead of a one-off implementation.

### 4. Key Dependencies
- Navigation: GetX (`Get.offNamed`)
- Localization: `LocaleKey` + `common_*` maps (`vi/en/ja`)
- Shared tokens: `AppColors`, `AppStyles`, `int_extensions`
- SVG rendering: `flutter_svg` (splash icon)

### 5. Notes & Known Issues
- Current splash branding uses existing camera SVG asset; no new asset file was introduced.
- System states are intentionally modular so future `error`/`empty` shared widgets can follow the same pattern.
