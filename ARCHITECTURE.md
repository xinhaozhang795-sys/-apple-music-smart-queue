# Apple Music Smart Queue — Cross-Platform Architecture

## Goal

Provide the same Smart Queue intelligence on iOS and Android while keeping Apple Music as the playback service.

## Shared features

Both platforms should provide:

- Smart Flow scoring
- Personalized candidate selection
- Recently played context
- Exploration and freshness balancing
- Artist/repetition penalties
- Music-feature-aware continuity
- Automatic queue refill
- Queue planning without interrupting the current track
- The same core recommendation behavior and user settings

## Platform adapters

### iOS

Use MusicKit for Swift and `SystemMusicPlayer` where system Music app control is desired.

### Android

Use MusicKit for Android. Apple provides Android authentication, Apple Music API access, and media playback/queue-control APIs. Android authentication requires explicit Music User Token handling rather than the automatic token management available on Apple platforms.

## AutoMix

AutoMix is a platform capability, not a dependency of the Smart Queue engine. iOS may expose Apple Music's native AutoMix when available. Android should not assume AutoMix exists.

The shared engine therefore focuses on **transition intelligence**: selecting musically compatible consecutive tracks and preparing the queue. Native audio-transition behavior remains an optional platform capability.

## Layering

```text
Shared Smart Queue Core
  ├── TrackCandidate
  ├── TrackProfile
  ├── Smart Flow Scorer
  ├── Queue Planner
  ├── Exploration / Freshness
  └── Auto-refill policy
          │
          ├── iOS adapter
          │     └── MusicKit for Swift
          │
          └── Android adapter
                └── MusicKit for Android
```

The platform adapters must not contain recommendation logic. This keeps iOS and Android behavior equivalent even though their playback capabilities differ.
