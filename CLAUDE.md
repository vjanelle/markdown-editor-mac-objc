# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

MarkdownEditor Lite is a macOS Markdown editor with split-pane live preview. Forked from [satoshi-iwaki/markdown-editor-mac-objc](https://github.com/satoshi-iwaki/markdown-editor-mac-objc), migrated to Swift.

- **Language**: Swift
- **Platform**: macOS 26 (Apple Silicon)
- **UI**: AppKit with storyboards + WebKit preview
- **Conversion**: markdown-mercury via `ConverterManager` (3 modes: GFM, Markdown, Strict)

## Directory Structure

```
MarkdownEditor/
├── MarkdownEditor/Sources/          # Application code
│   ├── AppDelegate.swift             # NSApplicationDelegate
│   ├── MainWindowController.swift   # Window controller, AutoSave frame
│   ├── EditorViewController.swift   # Left pane: NSTextView, file I/O, toolbar
│   ├── PreviewViewController.swift  # Right pane: WKWebView HTML preview
│   ├── Converter/                    # Markdown → HTML conversion
│   │   ├── ConverterManager.swift   # Singleton orchestrator, posts NSNotification
│   │   ├── TextConverter.swift      # Abstract converter protocol
│   │   ├── MarkdownRendererConverter.swift  # Base + GFM/Strict subclasses
│   │   └── MarkdownHTMLRenderer.swift # Calls markdown-mercury C library
│   ├── Editor/
│   │   ├── EditorTextFormatter.swift     # Syntax highlight ranges
│   │   ├── EditorFileWatcher.swift      # Inotify watch for external changes
│   │   ├── EditorDocumentStore.swift    # Disk I/O (read/write .md files)
│   │   └── EditorDialogPresenter.swift  # Alert/file panel coordinator
│   ├── PreferenceManager.swift    # UserDefaults wrapper (auto-reload toggle)
│   └── Logger.swift                # DEBUG-only NSLog helpers
├── MarkdownEditor/Resources/       # Bundled assets (CSS, sample.md)
├── MarkdownEditorTests/            # XCTest unit tests
└── MarkdownEditorUITests/          # XCTest UI tests
```

## Common Commands

All `make` targets run from repository root. `xcodebuild` commands require `MarkdownEditor/` as working directory.

```sh
# From repository root
make build          # Build for Debug
make test           # Run all unit + UI tests
make coverage       # Run tests, enforce 80% line coverage
make run            # Build and launch app
make clean          # Remove derived data
open MarkdownEditor/MarkdownEditor.xcworkspace  # Open in Xcode
```

```sh
# From MarkdownEditor/
xcodebuild -workspace MarkdownEditor.xcworkspace -scheme MarkdownEditor build
xcodebuild -workspace MarkdownEditor.xcworkspace -scheme MarkdownEditor test
```

## Architecture

### Data flow

```
EditorViewController (NSTextView text)
    ↓ textDidChange / textDidEndEditing
ConverterManager.shared.setContent(with:)
    ↓ posts ConverterManagerDidChangeContentNotification
PreviewViewController (WKWebView)
    ↑ didChangeContentNotification → reloadHtml()
```

### ConverterManager

Thread-safe singleton that mediates between editor and preview:

- Holds current selected converter index (persisted via `selectedConverterIndex` property)
- `setContent(with:)` → invokes selected converter → posts notification
- `html` → computed property, always reflects current converter output
- Three converters available: `GfmConverter`, `MarkdownConverter`, `StrictMarkdownConverter`

### Editor file handling

`EditorViewController` manages documents with:
- **Auto-save**: 500ms delay after edit, writes to current `filePath`
- **File watching**: `EditorFileWatcher` triggers `reloadFileFromDiskIfNeeded()` on external changes (only if not dirty)
- **Dirty tracking**: Prevents accidental data loss on new/open operations
- **Supported extensions**: `.md`, `.markdown` (registered in `Info.plist`)

### Preview security

`PreviewViewController` enforces:
- Non-persistent `WKWebsiteDataStore`
- JavaScript window creation disabled
- CSP header inserted: `default-src 'none'; img-src file:; script/style-src file: 'unsafe-inline';`
- Only bundle-resource files allowed (file scheme check)
- HTTP(S) links opened externally via `NSWorkspace`

## Testing

```sh
make test                          # All tests
make coverage                     # With 80% threshold (excludes closures, delegates, panels)
```

### Unit test structure

| File | Tests |
|------|-------|
| `MarkdownRendererConverterTests.swift` | Converter output, format application, content setting |
| `EditorTextFormatterTests.swift` | Syntax highlight range calculation |
| `EditorDocumentStoreTests.swift` | File I/O, encoding, error cases |
| `EditorDialogPresenterTests.swift` | Panel callback behavior |
| `PreviewViewControllerTests.swift` | URL filtering, CSP injection, reload |
| `ConverterManagerTests.swift` | Manager state transitions, notifications |
| `EditorViewControllerTests.swift` | Toolbar, formatting, file operations |
| `ContentAndPreferencesTests.swift` | Preference persistence, auto-reload |
| `AppLifecycleTests.swift` | Window creation, reopen handling |

### Coverage exclusions (in Makefile)

- Compiler-generated closures (`implicit closure`, `closure #`)
- `PreviewViewController.webView(` delegates
- `EditorDialogPresenter` alert/panel presenters (`showAlert`, `confirmDiscardingChanges`, `showOpenFilePanel`, `showSaveFilePanel`)

## Coding Conventions

- **Indentation**: 4 spaces
- **Naming**: PascalCase for classes, camelCase for methods/properties
- **IBOutlets/IBActions**: Match storyboard element names
- **Access control**: Default (internal) unless exposed to Objective-C (`@objc`)
- **Logging**: Use `logError`/`logWarning`/`logInfo`/`logDebug`/`logVerbose` (DEBUG-only)
- **Synchronization**: `objc_sync_enter/exit` for shared state in singletons
- **Error handling**: `do-catch` for `FileManager` operations, optional returns for validation

## Build System

- **Workspace**: `MarkdownEditor.xcworkspace` (CocoaPods)
- **Derived data**: `/private/tmp/MarkdownEditorDerivedData` (Makefile default)
- **CI**: macOS 26 runner, builds and tests via GitHub Actions

## Tips

- Run `make coverage` before committing to catch regressions
- `PreviewViewController` tests require stubbing `WKWebView` — do not instantiate real WebViews in unit tests
- Storyboard changes require Xcode; command-line cannot edit `.storyboard` files
- The `@objc` annotations are required for storyboard connections and notification selectors
