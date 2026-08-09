.PHONY: dev dev-chrome dev-web dev-macos build-apk build-web clean lint format

# Run the app on the default device
dev:
	flutter run

# Run the app on Chrome (opens a new sandboxed browser window)
dev-chrome:
	flutter run -d chrome

# Run the app via local web server (prints a localhost URL you can open in a new tab!)
dev-web:
	flutter run -d web-server

# Run the app specifically on macOS desktop
dev-macos:
	flutter run -d macos

# Build the Android APK
build-apk:
	flutter build apk

# Build the Web version
build-web:
	flutter build web

# Clean the Flutter project and reinstall dependencies (useful when things get weird)
clean:
	flutter clean
	flutter pub get

lint:
	flutter analyze

format:
	dart format .
