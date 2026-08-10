# Smart Queue Android

This directory is the Android platform layer for Smart Queue.

## Architecture

The recommendation and queue-planning logic remains platform-neutral in `SmartQueueCore`.
Android-specific playback and Apple Music integration should be implemented here using Kotlin and MusicKit for Android.

The Android layer is intentionally not a port of the iOS implementation. It should use Android-native lifecycle, coroutine, media-session, and background execution patterns while exposing the same product-level capabilities.

## Apple Music integration

Use MusicKit for Android for authentication, catalog access, playback, and queue control.

The Android implementation must support:

- current playback context
- playback state changes
- queue append/refill
- play/pause/skip
- personalized Apple Music data where available
- Smart Queue decisions produced by the shared core

Android does not currently provide Apple Music AutoMix in the same way as iOS. Smart Queue should therefore use its own transition-aware queue planning on Android rather than treating AutoMix as a required capability.

## Boundary rule

Do not put recommendation or scoring rules in this directory. Platform-specific code adapts Android and MusicKit APIs to the shared Smart Queue contracts.