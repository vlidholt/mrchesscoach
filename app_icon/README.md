# Mr. Chess Coach app icon — "Walnut Board"

Ivory faceted knight on the board's walnut squares. Everything is rendered from the vector sources in `source/`.

| Folder | What | Where it goes |
|---|---|---|
| `store/` | App Store 1024 and Play Store 512 (opaque) | Upload in App Store Connect / Play Console |
| `ios/AppIcon.appiconset/` | All iPhone + iPad sizes, opaque | `mrchesscoach_flutter/ios/Runner/Assets.xcassets/` |
| `android/res/` | Legacy `ic_launcher` + adaptive icon (background, foreground, monochrome for themed icons) | `mrchesscoach_flutter/android/app/src/main/res/` |
| `macos/AppIcon.appiconset/` | macOS rounded-rect icons with shadow | `mrchesscoach_flutter/macos/Runner/Assets.xcassets/` |
| `web/` | `favicon.png` (32), `favicon.ico` (16/32/48), PWA icons, maskable icons, apple-touch-icon (180) | `mrchesscoach_flutter/web/` |
| `windows/app_icon.ico` | 16–256 | `mrchesscoach_flutter/windows/runner/resources/` |
| `source/` | Master SVGs: `full` (iOS/store), `safe` (maskable), `adaptive_*` (Android layers), `tile` (rounded), `tiny` (16–32 px favicon), `macos` | Edit these to change the art |

Colours: walnut `#5A3A2D` / `#6E4B3C`, ivory `#FDF8EC` → `#7D725F`, rim `#14110D`.
