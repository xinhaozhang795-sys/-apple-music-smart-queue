# MusicKit setup

V0.1 is an iOS MusicKit prototype. The repository intentionally keeps MusicKit-specific code separate from the recommendation core.

## Xcode configuration

1. Create/open an iOS app target in Xcode.
2. Add the `MusicKit` framework.
3. Enable the MusicKit capability for the App ID.
4. Add the required MusicKit usage/entitlement configuration for the app target.
5. Ensure the app has an Apple Music subscription when testing catalog playback.
6. Request user authorization with `MusicAuthorization.request()` before reading personalized data or controlling playback.

Apple's current MusicKit documentation and WWDC26 session should be treated as the source of truth for entitlement, developer-token, and playback requirements.

## Important queue limitation

`SystemMusicPlayer` controls the Music app's state, but it intentionally exposes less queue introspection than `ApplicationMusicPlayer`. In particular, the app can set the system player's queue, while it cannot treat the system queue as a fully readable queue database.

That limitation shapes V0.1. We therefore keep queue planning independent from live queue mutation. The first integration path is:

```text
MusicKit recommendations/history
        ↓
SmartQueueCore scoring
        ↓
planned TrackCandidate batch
        ↓
SystemMusicPlayer queue
```

We will not claim seamless append/refill behavior until it is verified on a real iOS device against the current MusicKit SDK.

## Audio principle

The app never downloads, decodes, re-encodes, time-stretches, or mixes Apple Music audio. It only selects playable Apple Music items and delegates playback to MusicKit.
