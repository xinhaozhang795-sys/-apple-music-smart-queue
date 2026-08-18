# Apple Music Smart Queue — Cross-Platform Architecture

## Goal

Provide the same Smart Queue intelligence on iOS and Android while keeping Apple Music as the music service.

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

Use MusicKit for Swift. The transition-aware playback path uses `ApplicationMusicPlayer` because it exposes a fully controllable application queue and the `transition` API. `SystemMusicPlayer` remains a distinct optional integration when the product explicitly needs to control the Music app's system playback state.

The Smart Queue queue controller, playback context, monitor, and transition adapter must use the same player instance so queue state and transition state cannot diverge.

### Android

Use MusicKit for Android. Apple provides Android authentication, Apple Music API access, and media playback/queue-control APIs. Android authentication requires explicit Music User Token handling rather than the automatic token management available on Apple platforms.

## AutoMix and transition intelligence

AutoMix is a platform capability, not a dependency of the Smart Queue engine. iOS may expose Apple Music's native AutoMix when available. Android should not assume AutoMix exists.

The shared engine therefore focuses on **transition intelligence**: selecting musically compatible consecutive tracks and expressing a platform-neutral transition intent. Native audio-transition behavior remains an optional platform capability.

The iOS implementation uses MusicKit's application-player transition support. Apple notes that transitions cannot be applied in every scenario, so a high transition score is a request rather than a guarantee of audible crossfade behavior.

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
          │           └── ApplicationMusicPlayer
          │
          └── Android adapter
                └── MusicKit for Android
```

The platform adapters must not contain recommendation logic. This keeps iOS and Android behavior equivalent even though their playback capabilities differ.
