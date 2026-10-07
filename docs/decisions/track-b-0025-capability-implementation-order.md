# Track B decision 0025: capability implementation order

Date: 2026-10-07

The extracted official preload gives enough detail to rank the first native parity work without guessing from property names.

## Clipboard

The official `clipboard` group has seven methods:

- `copy(text)`: writes text through Electron clipboard APIs;
- `copyImage(imageArrayBuffer, imageSrc)`: creates an image and writes HTML plus image data;
- `copyFile(filePath)`: writes a Windows `FileNameW` clipboard payload;
- `cut()` and `paste()`: send the corresponding clipboard IPC events;
- `read()`: reads text;
- `hasMixedContent()`: checks whether text and an image format are both available.

Track B already has browser clipboard APIs in WebView2. They do not by themselves prove equivalent file and mixed-content behavior. The smallest safe implementation therefore needs a Windows clipboard owner for text, image, and file payloads, plus a source-restricted request boundary. It must not read or log arbitrary clipboard contents. Until that owner and an upload/paste test exist, `DiscordNative.clipboard` remains unexposed.

## File dialogs and downloads

The official `fileManager` group uses native open/save dialogs and a native show-in-folder action. Its save path validates the requested filename, obtains a default directory, asks the native dialog for a destination, and writes the selected file. Its open path returns selected file paths from the native dialog.

Track B has WebView2 download and file-picker behavior available through the browser surface, and the shell observes download events only in diagnostic mode. That is useful existing functionality, but it is not yet evidence that Discord's desktop file-manager path is equivalent. The next file test must cover one upload, one download, cancellation, and show-in-folder behavior without exposing local paths to diagnostics.

## Window and display

The official `window` group routes actions through IPC and accepts window keys because Electron can manage multiple windows. Track B currently owns one WinForms window and already has shell-native minimize, maximize, restore, focus, and close behavior. The existing five-action bridge is therefore a valid single-window native implementation, but it cannot be exposed to Discord as a partial `DiscordNative` object. Multi-window and media-source methods remain separate work.

## Capture

The official `desktopCapture.getDesktopCaptureSources(options)` is a source-list request over IPC. WebView2's ordinary `getDisplayMedia()` path and `ScreenCaptureStarting` event are not the same API. Track B must not report the desktop-capture group until a real source picker returns a selected screen/window, with audio policy, cancellation, and cleanup tested.

## Decision

The implementation order is:

1. establish a complete compatibility bootstrap boundary that does not abort Discord initialization;
2. implement clipboard behavior with a real Windows owner and private functional tests;
3. implement file open/save/download behavior and cancellation;
4. implement capture source selection;
5. expose only the corresponding Discord-native methods whose behavior is complete.

No production change is made by this decision. It prevents a partial object from being mistaken for desktop parity and keeps the current normal shell as the known-good rendering baseline.
