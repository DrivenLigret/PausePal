# PausePal

An iOS app for recording short-video viewing and taking breaks.

## Current step
Viewing records can be entered on Today and saved locally. Saving opens Pause; Today shows the day's total and entries. Mood is optional.

Restore offers four activities with 2, 3, 5 and 10 minute breaks. Only one break can be active. Its start time is saved, so the countdown continues after reopening the app.

A break can be completed once its timer reaches zero, or cancelled after confirmation. Cancelling does not add a completed break. Weekly reflection will be added in the next step.

Viewing duration must be 1–1,440 minutes. Future end times and duplicate time/duration pairs are rejected.

The repository loads and saves the journal in Application Support. Invalid or unsupported files produce an error when loaded and are left in place.

## Run
Open PausePal.xcodeproj, select the PausePal scheme and an iPhone simulator, then press Command-R.

Requires Xcode 16 or later and iOS 17 or later. No external packages.

## Tests
Press Command-U to run the journal storage, viewing-record and break tests.
