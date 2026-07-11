# Repository Guidelines

## Project Structure & Module Organization

This repository contains a macOS Swift app in `MarkdownEditor/`. Open `MarkdownEditor/MarkdownEditor.xcworkspace` for development. App code lives in `MarkdownEditor/MarkdownEditor/Sources/`, with converter implementations grouped under `Sources/Converter/`. Storyboard UI is in `MarkdownEditor/MarkdownEditor/Base.lproj/Main.storyboard`. Static resources such as Markdown templates and CSS are in `MarkdownEditor/MarkdownEditor/Resources/`, and image assets are in `MarkdownEditor/MarkdownEditor/Assets.xcassets/`. Unit tests are in `MarkdownEditor/MarkdownEditorTests/`; UI tests are in `MarkdownEditor/MarkdownEditorUITests/`.

## Build, Test, and Development Commands

Run commands from `MarkdownEditor/` unless noted otherwise.

```sh
make build
make test
```

Builds or tests from the command line using the Makefile.

## Coding Style & Naming Conventions

Use Swift conventions already present in `Sources/`: four-space indentation, braces on method lines, `#pragma mark` sections for delegate and action groups, and paired `.h`/`.m` files for classes. Name classes with descriptive PascalCase, such as `EditorViewController` or `ConverterManager`. Use lower camelCase for methods, properties, and local variables. Keep IBOutlet and IBAction names aligned with storyboard controls.

## Testing Guidelines

Tests use XCTest. Add unit tests in `MarkdownEditorTests` and UI tests in `MarkdownEditorUITests`. Name test methods with the `test...` prefix so XCTest discovers them. Prefer focused tests around converter behavior and content/client logic; use UI tests for workflows that require AppKit interaction.

## Commit & Pull Request Guidelines

Recent history uses short imperative summaries, for example `Fix build script` and `Implements Markdown Editor`. Keep commits concise and focused on one logical change. Pull requests should include a brief description, testing performed, and screenshots or screen recordings for visible UI changes. Mention dependency, signing, or workspace changes explicitly because they affect local setup.

## Agent-Specific Instructions

Keep changes scoped to the app, tests, or project settings needed for the task, and avoid unrelated storyboard or asset churn.

## Task Completion Status

- Task 1: Complete (baseline verification)
- Task 2: Complete (real toolbar implementation)
- Task 3: Complete (adaptive window sizing)
- Task 4: Complete (discoverable Markdown menu commands)

## Implementation Notes

The app now uses a real NSToolbar in the main window (replacing the fake content toolbar), and has implemented adaptive window sizing (reduced from 1200x800 to 720x480 minimum). Testing has been enhanced to verify toolbar content and window properties via the actual instantiated controller rather than parsing storyboard XML.

Task 4 has been completed by adding Markdown formatting commands to the macOS menu bar for discoverability, following the Apple Human Interface Guidelines.
