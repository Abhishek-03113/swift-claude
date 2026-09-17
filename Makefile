# Orbit — common tasks.
#
# The OrbitKit package (Sources/, Tests/) builds and tests with the Swift
# toolchain alone. The Xcode app/widget targets are generated from
# App/project.yml by XcodeGen and need a Mac with Xcode.

XCODEPROJ := App/Orbit.xcodeproj

.DEFAULT_GOAL := help

.PHONY: help
help: ## Show this help
	@grep -hE '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

.PHONY: build
build: ## Build the OrbitKit package
	swift build

.PHONY: test
test: ## Run the OrbitKit test suites
	swift test

.PHONY: generate
generate: ## Generate the Xcode project from App/project.yml (requires xcodegen)
	cd App && [ -f .env ] && set -a && . ./.env && set +a; xcodegen generate

.PHONY: open
open: generate ## Generate and open the Xcode project
	open $(XCODEPROJ)

.PHONY: app
app: generate ## Build the app and widget with xcodebuild
	xcodebuild -project $(XCODEPROJ) -scheme Orbit -configuration Debug build

.PHONY: clean
clean: ## Remove build products
	swift package clean
	rm -rf .build $(XCODEPROJ)
