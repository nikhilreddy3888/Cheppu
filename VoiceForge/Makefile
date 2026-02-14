.PHONY: all setup build clean run test install help

# Configuration
PROJECT_NAME = VoiceForge
SCHEME = VoiceForge
CONFIGURATION = Release
BUILD_DIR = build
WHISPER_DIR = whisper.cpp
FRAMEWORKS_DIR = VoiceForge/Frameworks
DMG_NAME = VoiceForge-Installer.dmg

# Colors for output
GREEN = \033[0;32m
YELLOW = \033[0;33m
RED = \033[0;31m
NC = \033[0m # No Color

help: ## Show this help message
	@echo "$(GREEN)VoiceForge Build System$(NC)"
	@echo ""
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2}'

all: setup build ## Setup and build everything

setup: ## Download and build whisper.cpp framework
	@echo "$(GREEN)Setting up VoiceForge build environment...$(NC)"
	@if [ ! -d "$(WHISPER_DIR)" ]; then \
		echo "$(YELLOW)Cloning whisper.cpp...$(NC)"; \
		git clone https://github.com/ggerganov/whisper.cpp.git; \
	else \
		echo "$(GREEN)whisper.cpp already cloned$(NC)"; \
	fi
	@echo "$(YELLOW)Building whisper.cpp XCFramework...$(NC)"
	@cd $(WHISPER_DIR) && \
		xcodebuild -create-xcframework \
			-library .build/release/libwhisper.a \
			-headers bindings/ios \
			-output whisper.xcframework || \
		(echo "$(YELLOW)Building from source...$(NC)" && \
		 make clean && \
		 WHISPER_COREML=1 make -j && \
		 mkdir -p whisper.xcframework/macos-arm64_x86_64 && \
		 lipo -create -output whisper.xcframework/macos-arm64_x86_64/libwhisper.a libwhisper.a)
	@mkdir -p $(FRAMEWORKS_DIR)
	@if [ -d "$(WHISPER_DIR)/whisper.xcframework" ]; then \
		echo "$(GREEN)Copying whisper.xcframework to project...$(NC)"; \
		cp -r $(WHISPER_DIR)/whisper.xcframework $(FRAMEWORKS_DIR)/; \
	else \
		echo "$(RED)Failed to build whisper.xcframework$(NC)"; \
		exit 1; \
	fi
	@echo "$(GREEN)Setup complete!$(NC)"

project: ## Generate Xcode project
	@echo "$(YELLOW)Generating Xcode project...$(NC)"
	@swift package generate-xcodeproj
	@echo "$(GREEN)Xcode project generated!$(NC)"

build: ## Build the application
	@echo "$(GREEN)Building VoiceForge...$(NC)"
	@xcodebuild -project $(PROJECT_NAME).xcodeproj \
		-scheme $(SCHEME) \
		-configuration $(CONFIGURATION) \
		-derivedDataPath $(BUILD_DIR) \
		CODE_SIGN_IDENTITY="-" \
		CODE_SIGNING_REQUIRED=NO \
		CODE_SIGNING_ALLOWED=NO \
		| xcpretty || true
	@echo "$(GREEN)Build complete!$(NC)"
	@echo "$(YELLOW)App location: $(BUILD_DIR)/Build/Products/$(CONFIGURATION)/$(PROJECT_NAME).app$(NC)"

build-signed: ## Build with code signing
	@echo "$(GREEN)Building signed VoiceForge...$(NC)"
	@xcodebuild -project $(PROJECT_NAME).xcodeproj \
		-scheme $(SCHEME) \
		-configuration $(CONFIGURATION) \
		-derivedDataPath $(BUILD_DIR) \
		| xcpretty || true
	@echo "$(GREEN)Signed build complete!$(NC)"

archive: ## Create an archive for distribution
	@echo "$(GREEN)Creating archive...$(NC)"
	@xcodebuild archive \
		-project $(PROJECT_NAME).xcodeproj \
		-scheme $(SCHEME) \
		-configuration $(CONFIGURATION) \
		-archivePath $(BUILD_DIR)/$(PROJECT_NAME).xcarchive \
		| xcpretty || true
	@echo "$(GREEN)Archive created!$(NC)"

dmg: build ## Create DMG installer
	@echo "$(GREEN)Creating DMG installer...$(NC)"
	@if ! command -v create-dmg &> /dev/null; then \
		echo "$(YELLOW)Installing create-dmg...$(NC)"; \
		brew install create-dmg; \
	fi
	@rm -f $(DMG_NAME)
	@create-dmg \
		--volname "VoiceForge" \
		--volicon "VoiceForge/Resources/AppIcon.icns" \
		--window-pos 200 120 \
		--window-size 600 400 \
		--icon-size 100 \
		--icon "$(PROJECT_NAME).app" 175 190 \
		--hide-extension "$(PROJECT_NAME).app" \
		--app-drop-link 425 190 \
		--no-internet-enable \
		"$(DMG_NAME)" \
		"$(BUILD_DIR)/Build/Products/$(CONFIGURATION)/$(PROJECT_NAME).app" || \
	(echo "$(YELLOW)Falling back to hdiutil...$(NC)" && \
	 hdiutil create -volname "VoiceForge" -srcfolder "$(BUILD_DIR)/Build/Products/$(CONFIGURATION)/$(PROJECT_NAME).app" -ov -format UDZO "$(DMG_NAME)")
	@echo "$(GREEN)DMG created: $(DMG_NAME)$(NC)"

install: build ## Install to /Applications
	@echo "$(GREEN)Installing VoiceForge to /Applications...$(NC)"
	@sudo rm -rf /Applications/$(PROJECT_NAME).app
	@sudo cp -R $(BUILD_DIR)/Build/Products/$(CONFIGURATION)/$(PROJECT_NAME).app /Applications/
	@echo "$(GREEN)Installation complete!$(NC)"

run: build ## Build and run the application
	@echo "$(GREEN)Launching VoiceForge...$(NC)"
	@open $(BUILD_DIR)/Build/Products/$(CONFIGURATION)/$(PROJECT_NAME).app

test: ## Run tests
	@echo "$(GREEN)Running tests...$(NC)"
	@xcodebuild test \
		-project $(PROJECT_NAME).xcodeproj \
		-scheme $(SCHEME) \
		-configuration Debug \
		-derivedDataPath $(BUILD_DIR) \
		| xcpretty || true

clean: ## Clean build artifacts
	@echo "$(YELLOW)Cleaning build artifacts...$(NC)"
	@rm -rf $(BUILD_DIR)
	@rm -rf DerivedData
	@rm -f $(DMG_NAME)
	@echo "$(GREEN)Clean complete!$(NC)"

clean-all: clean ## Clean everything including whisper.cpp
	@echo "$(YELLOW)Cleaning all dependencies...$(NC)"
	@rm -rf $(WHISPER_DIR)
	@rm -rf $(FRAMEWORKS_DIR)
	@echo "$(GREEN)Deep clean complete!$(NC)"

download-models: ## Download recommended Whisper models
	@echo "$(GREEN)Downloading Whisper models...$(NC)"
	@mkdir -p ~/Library/Application\ Support/VoiceForge/Models
	@cd ~/Library/Application\ Support/VoiceForge/Models && \
		echo "$(YELLOW)Downloading base model...$(NC)" && \
		curl -L -o ggml-base.bin https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin && \
		echo "$(YELLOW)Downloading large-v3-turbo-q5 model...$(NC)" && \
		curl -L -o ggml-large-v3-turbo-q5_0.bin https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo-q5_0.bin
	@echo "$(GREEN)Models downloaded!$(NC)"

check-deps: ## Check for required dependencies
	@echo "$(GREEN)Checking dependencies...$(NC)"
	@command -v xcodebuild >/dev/null 2>&1 || { echo "$(RED)xcodebuild not found. Install Xcode.$(NC)"; exit 1; }
	@command -v swift >/dev/null 2>&1 || { echo "$(RED)swift not found. Install Xcode Command Line Tools.$(NC)"; exit 1; }
	@command -v git >/dev/null 2>&1 || { echo "$(RED)git not found.$(NC)"; exit 1; }
	@echo "$(GREEN)All dependencies satisfied!$(NC)"

quick-start: check-deps setup build download-models install ## Complete setup and installation
	@echo ""
	@echo "$(GREEN)═══════════════════════════════════════════════$(NC)"
	@echo "$(GREEN)  VoiceForge is ready to use!$(NC)"
	@echo "$(GREEN)═══════════════════════════════════════════════$(NC)"
	@echo ""
	@echo "$(YELLOW)Launch from:$(NC) /Applications/VoiceForge.app"
	@echo "$(YELLOW)Or run:$(NC) open /Applications/VoiceForge.app"
	@echo ""
