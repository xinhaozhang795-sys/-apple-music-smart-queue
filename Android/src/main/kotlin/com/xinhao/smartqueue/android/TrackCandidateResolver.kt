package com.xinhao.smartqueue.android

/**
 * Resolves Smart Queue track IDs into Android MusicKit playback items.
 *
 * MusicKit-specific catalog lookup and queue-item construction stay behind
 * this Android boundary. SmartQueueCore remains platform-neutral.
 */
interface TrackCandidateResolver {
    suspend fun resolve(trackIDs: List<String>): ResolvedQueueItems
}

/** Result of resolving candidate IDs for playback. */
interface ResolvedQueueItems {
    val itemCount: Int
}
