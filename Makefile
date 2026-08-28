.PHONY: all build_renderer generate app install install-debug dmg release delete-release

all: app

build_renderer:
	cd web-renderer && npm install --no-audit --no-fund --loglevel=warn && npm run build

generate: build_renderer
	@if ! command -v xcodegen >/dev/null; then \
		echo "Error: xcodegen is not installed. Please install it with 'brew install xcodegen'"; \
		exit 1; \
	fi
	@if [ ! -f .version ]; then echo "1.0.0" > .version; fi
	@full_v=$$(cat .version); \
	commit_count=$$(git rev-list --count HEAD 2>/dev/null || echo "1"); \
	echo "Generating Project with Version: $$full_v (Build: $$commit_count)"; \
	rm -rf Osh.xcodeproj; \
	MARKETING_VERSION=$$full_v CURRENT_PROJECT_VERSION=$$commit_count xcodegen generate --quiet

app: generate
	@echo "🔨 Building application in $(or $(CONFIGURATION),Release) configuration..."
	@xcodebuild -project Osh.xcodeproj -scheme Osh -configuration $(or $(CONFIGURATION),Release) -destination 'platform=macOS,arch=arm64' clean build -quiet 2> build_error.log || (cat build_error.log; rm -f build_error.log; exit 1)
	@rm -f build_error.log
	@echo "✅ Build completed: $(or $(CONFIGURATION),Release) configuration"

install:
	@echo "🚀 Building and installing Release configuration..."; \
	make app CONFIGURATION=Release && \
	./scripts/install.sh Release true development

install-debug:
	@echo "🚀 Building and installing Debug configuration..."; \
	make app CONFIGURATION=Debug && \
	./scripts/install.sh Debug true development

dmg:
	./scripts/create_dmg.sh

release:
	./scripts/release.sh $(filter-out $@,$(MAKECMDGOALS))

delete-release:
	./scripts/delete_release.sh $(filter-out $@,$(MAKECMDGOALS))

%:
	@:
