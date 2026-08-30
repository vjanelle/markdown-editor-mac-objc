ROOT_DIR := $(abspath .)
WORKSPACE := $(ROOT_DIR)/Draftmark.xcworkspace
SCHEME := Draftmark
DERIVED_DATA := /private/tmp/DraftmarkDerivedData
APP_PATH := $(DERIVED_DATA)/Build/Products/Debug/Draftmark.app
COVERAGE_RESULT := /private/tmp/DraftmarkCoverage.xcresult
COVERAGE_MIN := 0.8

.PHONY: build test coverage run app-path clean

build:
	xcodebuild -workspace $(WORKSPACE) -scheme $(SCHEME) -derivedDataPath $(DERIVED_DATA) build -quiet

test:
	xcodebuild -workspace $(WORKSPACE) -scheme $(SCHEME) -derivedDataPath $(DERIVED_DATA) test -quiet

coverage:
	rm -rf $(COVERAGE_RESULT)
	xcodebuild -workspace $(WORKSPACE) -scheme $(SCHEME) -derivedDataPath $(DERIVED_DATA) -enableCodeCoverage YES -resultBundlePath $(COVERAGE_RESULT) test -quiet
	@# Exclude compiler-generated closures and AppKit/WebKit delegate wrappers that are unsafe to drive in headless tests.
	@violations=$$(xcrun xccov view --report --json $(COVERAGE_RESULT) | jq -r --argjson threshold $(COVERAGE_MIN) '\
		.targets[] | select(.name == "Draftmark.app") | .files[] as $$file | $$file.functions[] |\
		select(.lineCoverage < $$threshold) |\
		select((.name | test("^(implicit closure|closure #)")) | not) |\
		select((.name | test("^PreviewViewController.webView\\(")) | not) |\
		select((($$file.name == "EditorDialogPresenter.swift") and (.name | test("^EditorDialogPresenter\\.(showAlert|confirmDiscardingChanges|showOpenFilePanel|showSaveFilePanel)"))) | not) |\
		"\($$file.name):\(.lineNumber): \((.lineCoverage * 10000 | round) / 100)% \(.name)"\
	'); \
	if [ -n "$$violations" ]; then \
		printf '%s\n' "$$violations"; \
		exit 1; \
	fi; \
	xcrun xccov view --report $(COVERAGE_RESULT) | awk '/Draftmark.app/ { print; exit }'

run: build
	open $(APP_PATH)

app-path:
	@printf '%s\n' "$(DERIVED_DATA)/Build/Products/Debug/Draftmark.app"

clean:
	rm -rf $(DERIVED_DATA)
