package com.xinhao.smartqueue.android

/**
 * Boundary for the Apple Music catalog-backed queue provider.
 *
 * The implementation is intentionally isolated from SmartQueueCore. Once the
 * Apple Music Android SDK AARs are supplied by the app, this boundary can be
 * implemented with CatalogPlaybackQueueItemProvider.Builder without changing
 * the Smart Queue algorithm or AutoRefill coordinator.
 */
class MusicKitCatalogResolver : TrackCandidateResolver {
    override suspend fun resolve(trackIDs: List<String>): ResolvedQueueItems {
        require(trackIDs.isNotEmpty()) { "trackIDs must not be empty" }
        throw UnsupportedOperationException(
            "MusicKit Android SDK integration is not bundled yet. " +
                "Provide Apple's MusicKit Android AARs and implement the SDK-specific resolver here."
        )
    }

    private data class PendingQueueItems(
        override val itemCount: Int
    ) : ResolvedQueueItems
}
