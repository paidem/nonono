.PHONY: build test app install uninstall

build:
	swift build -c release

test:
	swift test

app:
	scripts/bundle.sh

# Copies the bundle to /Applications and launches it. Use the menu bar icon to
# enable Start at Login.
install: app
	rm -rf /Applications/nonono.app
	cp -R build/nonono.app /Applications/nonono.app
	open /Applications/nonono.app

uninstall:
	-osascript -e 'tell application "nonono" to quit' 2>/dev/null
	rm -rf /Applications/nonono.app
