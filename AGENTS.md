# Repository Guidelines

## Project Structure & Module Organization

This repository contains a macOS Objective-C app in `MarkdownEditor/`. Open `MarkdownEditor/MarkdownEditor.xcworkspace` for development, especially after installing CocoaPods dependencies. App code lives in `MarkdownEditor/MarkdownEditor/Sources/`, with converter implementations grouped under `Sources/Converter/`. Storyboard UI is in `MarkdownEditor/MarkdownEditor/Base.lproj/Main.storyboard`. Static resources such as Markdown templates and CSS are in `MarkdownEditor/MarkdownEditor/Resources/`, and image assets are in `MarkdownEditor/MarkdownEditor/Assets.xcassets/`. Unit tests are in `MarkdownEditor/MarkdownEditorTests/`; UI tests are in `MarkdownEditor/MarkdownEditorUITests/`.

## Build, Test, and Development Commands

Run commands from `MarkdownEditor/` unless noted otherwise.

```sh
pod install
```

Installs CocoaPods dependencies declared in `Podfile` (`GCDWebServer`, `AppAuth`) and updates the workspace.

```sh
open MarkdownEditor.xcworkspace
```

Opens the app in Xcode for local builds, signing settings, and storyboard editing.

```sh
xcodebuild -workspace MarkdownEditor.xcworkspace -scheme MarkdownEditor build
xcodebuild -workspace MarkdownEditor.xcworkspace -scheme MarkdownEditor test
```

Builds or tests from the command line when a shared `MarkdownEditor` scheme is available. If Xcode reports that the scheme is missing, create and share the scheme before relying on CI-style commands.

## Coding Style & Naming Conventions

Use Objective-C conventions already present in `Sources/`: four-space indentation, braces on method lines, `#pragma mark` sections for delegate and action groups, and paired `.h`/`.m` files for classes. Name classes with descriptive PascalCase, such as `EditorViewController` or `ConverterManager`. Use lower camelCase for methods, properties, and local variables. Keep IBOutlet and IBAction names aligned with storyboard controls.

## Testing Guidelines

Tests use XCTest. Add unit tests in `MarkdownEditorTests` and UI tests in `MarkdownEditorUITests`. Name test methods with the `test...` prefix so XCTest discovers them. Prefer focused tests around converter behavior and content/client logic; use UI tests for workflows that require AppKit interaction.

## Commit & Pull Request Guidelines

Recent history uses short imperative summaries, for example `Fix build script` and `Implements Markdown Editor`. Keep commits concise and focused on one logical change. Pull requests should include a brief description, testing performed, and screenshots or screen recordings for visible UI changes. Mention dependency, signing, or workspace changes explicitly because they affect local setup.

## Agent-Specific Instructions

Do not edit generated CocoaPods files unless dependency changes require it. Keep changes scoped to the app, tests, or project settings needed for the task, and avoid unrelated storyboard or asset churn.
