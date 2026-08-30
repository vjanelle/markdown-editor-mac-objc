# Repository Guidelines

## Project Structure

Draftmark is a macOS Swift app. Open `Draftmark.xcworkspace` in Xcode.

- App code: `Draftmark/Sources/`
- Storyboard: `Draftmark/Base.lproj/Main.storyboard`
- App resources: `Draftmark/Resources/`
- Images: `Draftmark/Assets.xcassets/`
- Unit tests: `DraftmarkTests/`
- UI tests: `DraftmarkUITests/`

## Build and Run

Run these commands from the repository root:

```sh
make build       # Build Draftmark
make test        # Run unit and UI tests
make run         # Build and open the app
make coverage    # Run tests and check 80% line coverage
make clean       # Remove Draftmark derived data
```

## Code Style

Use four spaces for indentation. Use `PascalCase` for types and `camelCase` for methods, properties, and local values. Put the opening brace on the declaration line. Keep `@IBOutlet` and `@IBAction` names aligned with storyboard objects. Keep changes small and local.

## Tests

Use XCTest. Start test method names with `test`. The Xcode test targets are `DraftmarkTests` and `DraftmarkUITests`. Put unit tests in `DraftmarkTests` and UI tests in `DraftmarkUITests`. Test converter and document behavior with unit tests. Use UI tests only for AppKit workflows.

## Commits and Pull Requests

Use a short imperative commit subject, such as `Fix build script`. Keep each commit focused. A pull request must describe the change and list the tests that you ran. Add screenshots or a recording for UI changes. Call out changes to dependencies, signing, or Xcode workspace files.
