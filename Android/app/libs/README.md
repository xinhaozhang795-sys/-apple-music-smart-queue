# Apple Music Android SDK

The Apple Music Android SDK is distributed by Apple as AAR files rather than as
an ordinary Maven Central dependency in the current integration path.

Place the SDK files supplied by Apple in this directory:

- `mediaplayback-release-1.1.1.aar`
- `musickitauth-release-1.1.2.aar`

Do not commit Apple-provided SDK binaries to this repository unless their
redistribution terms explicitly permit it.

The official Android MusicKit documentation exposes the playback and
authentication packages under `com.apple.android.music.*` and
`com.apple.android.sdk.authentication.*`.
