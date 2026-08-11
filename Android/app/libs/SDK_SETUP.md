# MusicKit for Android SDK setup

Apple currently distributes the Android MusicKit libraries as SDK downloads. The official Apple documentation lists the Android playback and authentication packages under `com.apple.android.music.*` and `com.apple.android.sdk.authentication.*`.

## Local setup

1. Download the current MusicKit for Android SDK from Apple's developer site.
2. Put the Apple-provided AAR files in this directory.
3. Do not commit the AAR binaries unless Apple's redistribution terms explicitly allow it.

The current repository integration expects the playback and authentication AARs documented in `README.md`.

## Why this is local

The project deliberately does not invent a Maven coordinate or bundle Apple's proprietary binaries. The exact SDK package supplied by Apple is the source of truth.

Once the AARs are present, the Android MusicKit adapter can compile against the official `MediaPlayerController`, `PlaybackQueueItemProvider`, `CatalogPlaybackQueueItemProvider`, and authentication APIs.
