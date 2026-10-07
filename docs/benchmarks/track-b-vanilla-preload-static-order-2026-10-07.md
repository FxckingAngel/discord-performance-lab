# Track B vanilla preload static order

Date: 2026-10-07  
Source: local vanilla Discord PTB `mainScreenPreload.js`, read-only extraction from the installed `core.asar`

## What this establishes

The extractor now records the order in which the vanilla preload constructs the `DiscordNative` object. This is source-order evidence only. It is not a runtime startup-call trace and is not used to claim that every group is needed by the initial Discord route.

The observed construction order is:

`isRenderer` → `setUncaughtExceptionHandler` → `nativeModules` → `process` → `os` → `clipboard` → `ipc` → `gpuSettings` → `window` → `ntpClock` → `spellCheck` → `crashReporter` → `desktopCapture` → `fileManager` → `clips` → `processUtils` → `powerSaveBlocker` → `http` → `accessibility` → `features` → `settings` → `userDataCache` → `thumbar` → `safeStorage` → `hardware` → `tracing` → `riotGames` → `cs2Gsi` → `dotaGsi` → `webAuthn` → `gcEvents` → `sysimg`

The first statically referenced IPC event names are:

`APP_GET_PATH`, `ACCESSIBILITY_GET_ENABLED`, `APP_GET_RELEASE_CHANNEL_SYNC`, `APP_GET_HOST_VERSION_SYNC`, `APP_GET_BUILD_NUMBER`, `APP_GET_ARCH`, `APP_DOCK_BOUNCE`, `APP_GET_MODULE_VERSIONS`, `APP_SET_BADGE_COUNT`, `APP_DOCK_SET_BADGE`, `APP_DOCK_CANCEL_BOUNCE`, `APP_RELAUNCH`, `APP_GET_DEFAULT_DOUBLE_CLICK_ACTION`, `APP_PAUSE_FRAME_EVICTOR`, `APP_UNPAUSE_FRAME_EVICTOR`, `APP_GET_PREFERRED_SYSTEM_LANGUAGES`, `APP_GET_SYSTEM_UI_DIRECTION_SYNC`, and `APP_GET_OPEN_ON_START`.

These names are sanitized. No arguments, return values, account data, URLs, cookies, tokens, clipboard contents, or file contents are collected.

## What this does not establish

The vanilla preload exposes non-configurable descriptors. The existing CDP probe could not wrap those methods after preload execution, so it recorded no reliable runtime call sequence. The extractor now writes `runtimeCallSequence: null` and records that limitation explicitly instead of presenting static source order as observed behavior.

The complete object is therefore still unsuitable for partial activation. Track B continues to expose no `DiscordNative` root to the normal Discord frontend. The isolated window and hardware probes remain diagnostic-only.

## Next step

The minimum coherent boot contract still requires behavior-level evidence from a separately labeled diagnostic session or a more appropriate pre-preload instrumentation boundary. Any such session must remain separate from the untouched official baseline. Until then, implementation can proceed in isolated harnesses, but activation must wait for a complete tested contract rather than a guessed subset.
