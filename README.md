# PausePal

An iOS app for recording short-video viewing and taking breaks.

## Current step
Domain models and local JSON storage are in place. The app currently displays its name.

The repository loads and saves the journal in Application Support. Invalid or unsupported files produce an error when loaded and are left in place.

## Run
Open PausePal.xcodeproj, select the PausePal scheme and an iPhone simulator, then press Command-R.

Requires Xcode 16 or later and iOS 17 or later. No external packages.

## Tests
Press Command-U to run the six journal storage tests.
