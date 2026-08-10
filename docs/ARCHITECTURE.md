# V0.1 Architecture

## Goal

Generate a continuously refreshed Apple Music queue without becoming a DJ application or replacing Apple's playback UI.

## Layers

### 1. MusicKitAdapter

Owns all Apple-platform integration.

Responsibilities:

- authorization state
- personal recommendations
- recently played
- catalog/library lookup
- current playback state
- system music player queue operations

The rest of the app must not import MusicKit directly.

### 2. Domain

Pure Swift models and policies.

Core concepts:

- `TrackCandidate`
- `CurrentTrackContext`
- `ListeningSignal`
- `QueueItemScore`
- `QueuePolicy`
- `ExplorationProfile`

This layer must be unit-testable on macOS without MusicKit.

### 3. Recommendation Engine

V0.1 uses deterministic weighted scoring rather than an ML model.

Initial weights:

| Signal | Weight |
| --- | ---: |
| Apple personal recommendation relevance | 35% |
| user affinity / library relationship | 25% |
| continuity with current context | 20% |
| freshness | 10% |
| duplicate penalty | 10% |

Weights are configuration, not hard-coded business logic.

### 4. Queue Engine

Maintains a rolling queue.

Default policy:

- target queue size: 8
- refill threshold: 3
- refill batch: 5
- reject exact duplicates already in the active queue
- apply artist repetition penalty
- avoid recently skipped tracks

The engine should make one decision at a time but prepare several future tracks so the user never sees a loading step during ordinary listening.

### 5. Playback Monitor

Observes the system player and triggers queue evaluation when:

- playback starts
- track changes
- queue falls below threshold
- playback context changes materially

### 6. UI

V0.1 intentionally stays small.

Screens:

- Home
- Smart Queue status
- Settings

The UI must not expose DJ controls, decks, waveforms, EQ, crossfaders, or manual mixing controls.

## Data flow

```text
Current playback
      |
      v
CurrentTrackContext
      |
      +------> Personal recommendations
      |
      +------> Recently played
      |
      +------> Library signals
      |
      v
CandidatePool
      |
      v
ScoringEngine
      |
      v
QueuePolicy
      |
      v
QueuePlan
      |
      v
MusicKitAdapter
      |
      v
System music queue
```

## Future versions

V0.2:

- exploration slider
- artist diversity model
- stronger skip/favorite feedback
- adaptive weights

V0.3:

- richer music metadata
- tempo/energy continuity where Apple exposes reliable metadata
- contextual session state

V1.0:

- personalized ranking model
- long-session adaptation
- iOS and Android shared recommendation core
