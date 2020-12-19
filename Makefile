.PHONY: setup
setup: ## setup project
	cp .githooks/pre-commit .git/hooks/pre-commit
	cp .githooks/commit-msg .git/hooks/commit-msg
	chmod +x .git/hooks/pre-commit .git/hooks/commit-msg
	fvm install
	fvm flutter pub get

.PHONY: dependencies
dependencies: ## update dependencies
	fvm flutter pub get

.PHONY: clean
clean: ## clear cache
	fvm flutter clean

.PHONY: analyze
analyze: ## run code analyzer
	fvm flutter analyze

.PHONY: format 
format: ## format code
	fvm flutter format lib/

.PHONY: format-analyze
format-analyze: ## run code analyzer && format code
	fvm flutter format --set-exit-if-changed --dry-run lib/
	fvm flutter analyze

.PHONY: generate
generate: ## update generated files
	fvm flutter pub run build_runner build --delete-conflicting-outputs

.PHONY: run-dev
run-dev: ## run app in debug mode
	fvm flutter run --target lib/main.dart

.PHONY: run-prd
run-prd: ## run app in production mode
	fvm flutter run --release --target lib/main.dart

.PHONY: build-android
build-android: ## build android app bundle
	fvm flutter build appbundle
	
.PHONY: build-apk
build-apk: ## ## build android release
	fvm flutter build apk --release --split-per-abi --target lib/main.dart

.PHONY: build-ios
build-ios: ## build ios release
	cd ios/ && pod install && cd ..
	fvm flutter build ios --release --target lib/main.dart

.PHONY: test
test: ## run unit tests
	fvm flutter test --coverage test/all_tests.dart
	dart scripts/remove_from_coverage.dart
	genhtml -o coverage coverage/lcov.info
	open coverage/index.html

.PHONY: mirror
mirror: ## mirror screen read-only (using scrcpy)
	scrcpy -n -m 1024 --window-title 'NGTV'

.PHONY: screenshot
screenshot: ## Capture screenshot
	adb exec-out screencap -p > ./marketing/images/screenshot.png

.DEFAULT_GOAL := help
.PHONY: help
help:
	@grep -E '(^[a-zA-Z_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'
