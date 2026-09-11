.PHONY: build test app install uninstall release notarize

VERSION ?= 0.0.0
ZIP = build/nonono-$(VERSION).zip

build:
	swift build -c release

test:
	swift test

app:
	scripts/bundle.sh

# Copies the bundle to /Applications and launches it. Use the menu bar icon to
# enable Start at Login.
install: app
	-osascript -e 'tell application "nonono" to quit' 2>/dev/null
	rm -rf /Applications/nonono.app
	cp -R build/nonono.app /Applications/nonono.app
	open /Applications/nonono.app

uninstall:
	-osascript -e 'tell application "nonono" to quit' 2>/dev/null
	rm -rf /Applications/nonono.app

# Universal (arm64 + x86_64) bundle zipped for a GitHub release:
#   make release VERSION=0.0.1
# With a Developer ID certificate, sign it for notarization too:
#   make release VERSION=0.0.1 SIGN_IDENTITY="Developer ID Application: Name (TEAMID)"
release:
	UNIVERSAL=1 VERSION=$(VERSION) SIGN_IDENTITY="$(SIGN_IDENTITY)" scripts/bundle.sh
	rm -f $(ZIP)
	ditto -c -k --keepParent build/nonono.app $(ZIP)
	@echo "release archive: $(ZIP)"

# Optional. Needs a notarytool keychain profile, created once with:
#   xcrun notarytool store-credentials nonono --apple-id ... --team-id ... --password <app-specific>
# Run after `make release` with SIGN_IDENTITY set; re-zips the stapled app.
notarize:
	xcrun notarytool submit $(ZIP) --keychain-profile nonono --wait
	xcrun stapler staple build/nonono.app
	rm -f $(ZIP)
	ditto -c -k --keepParent build/nonono.app $(ZIP)
	@echo "notarized and stapled: $(ZIP)"
