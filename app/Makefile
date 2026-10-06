.PHONY: dev dev-chrome dev-web dev-macos build-apk build-web clean lint format icons

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

# Build the Android Universal Release APK
build-apk:
	flutter build apk --release

# Build the Web version (root domain e.g. Vercel, Netlify, custom domain)
build-web:
	flutter build web --release --base-href "/"

# Build the Web version for GitHub Pages (repo subpath /just-tenuki/)
build-web-gh-pages:
	flutter build web --release --base-href "/just-tenuki/"

# Clean the Flutter project and reinstall dependencies (useful when things get weird)
clean:
	flutter clean
	flutter pub get

lint:
	flutter analyze

format:
	dart format .

# Generate app launcher icons across Android, Web, and macOS
icons:
	flutter pub get
	dart run flutter_launcher_icons
