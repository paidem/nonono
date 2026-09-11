.PHONY: build test install uninstall

build:
	swift build -c release

test:
	swift test

# Copies the binary to ~/.local/bin and registers a launchd agent that starts at login.
# Extra daemon flags: make install ARGS="--quiet 1.0"
install: build
	.build/release/nonono install $(ARGS)

uninstall:
	.build/release/nonono uninstall
