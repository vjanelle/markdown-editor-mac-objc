WORKSPACE := MarkdownEditor/MarkdownEditor.xcworkspace
SCHEME := MarkdownEditor
DERIVED_DATA := /private/tmp/MarkdownEditorDerivedData
APP_PATH := $(DERIVED_DATA)/Build/Products/Debug/Markdown\ Editor.app

.PHONY: build test run app-path clean

build:
	xcodebuild -workspace $(WORKSPACE) -scheme $(SCHEME) -derivedDataPath $(DERIVED_DATA) build -quiet

test:
	xcodebuild -workspace $(WORKSPACE) -scheme $(SCHEME) -derivedDataPath $(DERIVED_DATA) test -quiet

run: build
	open $(APP_PATH)

app-path:
	@printf '%s\n' "$(DERIVED_DATA)/Build/Products/Debug/Markdown Editor.app"

clean:
	rm -rf $(DERIVED_DATA)
