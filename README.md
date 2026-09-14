# PausePal

Zhengyang Yu | zhengyang.yu-2@student.uts.edu.au

PausePal allows teens to log short video viewing, select a weekly break and reflect on their week. Time will be entered manually, and mood will be optional.

## Project

The app consists of four screens: Today, Pause, Restore and Reflect. It has 5 use cases which include viewing, starting a break, ending a break, cancelling a break and setting the weekly viewing budget.

ViewModel of WellnessViewModel is used by SwiftUI views to call the use cases. Journal domain models represent the rules and the journal. FileWellnessJournalRepository is responsible for persisting the wellness journal to the file system as JSON. The Swift files include DocC comments for the documentation of the model.

## Run and test

Open the PausePal.xcodeproj file, choose the PausePal scheme and an iPhone simulator. To run, press Command-R, to run the 33 unit tests, press Command-U.

Must be running iOS 17 or newer. No external packages. Validated using Xcode 26.6 on an iPhone 17 Pro simulator running on iOS 26.5.

## Repository

https://github.com/DrivenLigret/PausePal

Source version: `44eb63e`.

## Documents

Human_System_Architecture.pdf: One page architecture diagram.
Reflective_Report.pdf: 640-word reflective report.
