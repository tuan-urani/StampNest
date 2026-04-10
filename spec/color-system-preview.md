# Color System Preview (Current -> Standardized)

Generated: 2026-04-10  
Scope: preview only, no implementation in `lib/` yet.

## 1) Current Snapshot

- `AppColors` constants with hex values: **115**
- Legacy constants named by hex (`colorXXXXXX...`): **81**
- Direct `Colors.*` usage outside `AppColors`: **5**
- Direct raw `Color(0x...)` outside `AppColors`: **4** (all in `app_toggle.dart`)
- App-level theme mapping via `ThemeData/ColorScheme`: **not configured yet** (`GetMaterialApp` has no `theme`)

## 2) Current Core Palette (for preview)

### Brand

| Current token | Hex |
| --- | --- |
| `primary` | `#84C93F` |
| `primaryLight` | `#5CC7A0` |
| `secondary1` | `#CAE7B4` |
| `secondary2` | `#E6F4EC` |
| `colorF586AA6` (used as accent in Stampverse views) | `#586AA6` |

### Neutral

| Current token | Hex |
| --- | --- |
| `white` | `#FFFFFF` |
| `black` | `#000000` |
| `textPrimary` | `#212121` |
| `stampverseHeadingText` | `#4A4A48` |
| `stampversePrimaryText` | `#757575` |
| `stampverseMutedText` | `#A0A09C` |
| `textDisabled` | `#C0C0C0` |
| `stampverseBorderSoft` | `#F1EEE7` |

### Surface / Background

| Current token | Hex |
| --- | --- |
| `stampverseBackground` | `#F8F5ED` |
| `stampverseSurface` | `#FEFAF5` |
| `background` | `#FFFFFF` |
| `backgroundSecondary` | `#F5F5F5` |
| `backgroundOverlay` | `#80000000` |
| `backgroundDisabled` | `#E5E5E5` |

### Semantic

| Current token | Hex |
| --- | --- |
| `success` | `#4CAF50` |
| `stampverseSuccess` | `#22C55E` |
| `stampverseSuccessSoft` | `#EAF9E6` |
| `warning` | `#FFC107` |
| `error` | `#F44336` |
| `stampverseDanger` | `#EF4444` |
| `stampverseDangerSoft` | `#FEF2F2` |
| `info` | `#2196F3` |

### State (current, partial)

| Current token | Hex | Notes |
| --- | --- | --- |
| `textDisabled` | `#C0C0C0` | disabled text |
| `backgroundDisabled` | `#E5E5E5` | disabled bg |
| `primaryAlpha10` | `#1A84C93F` | pressed/overlay-like |
| `color1A2D7DD2` | `#1A2D7DD2` | hover/overlay-like |
| `colorF586AA6` | `#586AA6` | currently used as focus-like border on some forms |

## 3) Proposed Standardized Token Set (Single Theme, Soft/Cute Direction)

These values are tuned for a softer, calmer, more gentle mood while keeping current surface colors.

### A. Brand

| Proposed token | Preview value | Mapped from |
| --- | --- | --- |
| `brand.primary` | `#84C93F` | keep `primary` |
| `brand.primaryAlt` | `#7BCFB2` | tuned from `primaryLight` |
| `brand.secondary` | `#D8EDC5` | tuned from `secondary1` |
| `brand.accent` | `#7E8FC7` | tuned from `colorF586AA6` |
| `brand.accentSoft` | `#E8ECFA` | soft tint for accent surfaces |

### B. Neutral

| Proposed token | Preview value | Mapped from |
| --- | --- | --- |
| `neutral.0` | `#FFFFFF` | `white` |
| `neutral.50` | `#FEFAF5` | `stampverseSurface` |
| `neutral.100` | `#F8F5ED` | `stampverseBackground` |
| `neutral.300` | `#C0C0C0` | `textDisabled` |
| `neutral.500` | `#757575` | `stampversePrimaryText` |
| `neutral.700` | `#4A4A48` | `stampverseHeadingText` |
| `neutral.900` | `#000000` | `black` |

### C. Surface / Border / Overlay

| Proposed token | Preview value | Mapped from |
| --- | --- | --- |
| `surface.page` | `#F8F5ED` | `stampverseBackground` |
| `surface.card` | `#FEFAF5` | `stampverseSurface` |
| `surface.base` | `#FFFFFF` | `background` |
| `surface.secondary` | `#F5F5F5` | `backgroundSecondary` |
| `border.soft` | `#F1EEE7` | `stampverseBorderSoft` |
| `border.default` | `#E0E0E0` | `border` |
| `overlay.scrim` | `#80000000` | `backgroundOverlay` |

### D. Semantic

| Proposed token | Preview value | Mapped from |
| --- | --- | --- |
| `semantic.success` | `#6FBE8B` | softened success green |
| `semantic.successSoft` | `#EAF7EF` | soft success background |
| `semantic.warning` | `#E3B160` | softened warning |
| `semantic.error` | `#E98492` | softened coral error |
| `semantic.errorSoft` | `#FDECEF` | soft error background |
| `semantic.info` | `#7FA4D8` | softened info blue |

### E. State

| Proposed token | Preview value | Mapped from |
| --- | --- | --- |
| `state.focus` | `#7E8FC7` | aligned with `brand.accent` |
| `state.hover` | `#EEF3FF` | softer hover tint |
| `state.pressed` | `#DDECC7` | softer pressed tint |
| `state.disabledBg` | `#ECE9E2` | warm disabled background |
| `state.disabledText` | `#B7B2A9` | warm disabled text |

## 4) Gaps To Fix During Implementation

- Replace legacy hex-named tokens with semantic tokens (keep temporary alias for safe migration).
- Replace hardcoded `Colors.*` and raw `Color(0x...)` in widgets.
- Add app-level `ThemeData` + `ColorScheme` mapping to standardized tokens.
- Keep `Stampverse`-specific naming only as aliases during migration, then phase out.

## 5) Visual Preview File

Open this file in browser for swatch view:

- `spec/color-system-preview.html`
