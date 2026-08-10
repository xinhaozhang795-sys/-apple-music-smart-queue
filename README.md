# Apple Music Smart Queue

A native Apple Music intelligence layer that keeps Apple Music as the playback experience while improving queue generation, discovery, diversity, and repetition control.

## Product principle

> Apple Music plays. Smart Queue thinks.

This project is **not** a DJ mixer and does not attempt to replace the Apple Music UI. The first goal is to generate and maintain a smarter `Up Next` queue while leaving playback to Apple's MusicKit system player.

## V0.1 scope

- MusicKit authorization boundary
- Apple Music personal recommendations as candidate source
- Recently played history as a signal
- Queue candidate model
- Deterministic scoring engine
- Duplicate and artist-repeat penalties
- Exploration/familiarity controls
- Queue filler abstraction
- Testable core without MusicKit dependencies

## Planned architecture

```text
Apple Music / MusicKit
        |
        v
Candidate Sources
        |
        v
Recommendation Engine
        |
        v
Queue Policy
        |
        v
SystemMusicPlayer queue
        |
        v
Apple Music playback
```

## Important constraint

The project deliberately separates **selection** from **audio rendering**. V0.x will not decode, remix, time-stretch, or re-encode Apple Music audio.

## Status

V0.1 foundation in progress.

## Requirements

- Xcode 26+
- Swift 6+
- iOS 18+ for the initial development target
- An Apple Music subscription for real playback tests

MusicKit capabilities and queue APIs are subject to Apple's platform permissions and entitlements.
