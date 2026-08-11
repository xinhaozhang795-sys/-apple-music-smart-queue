package com.xinhao.smartqueue.android

/**
 * Platform coordinator for Android automatic queue refill.
 *
 * Smart Queue supplies track IDs. The resolver owns MusicKit catalog lookup and
 * queue-item construction; this coordinator only decides when and how to append.
 */
class AutoRefillCoordinator(
    private val playback: AppleMusicPlaybackAdapter,
    private val resolver: TrackCandidateResolver,
    private val refillThreshold: Int = 3
) {
    private var refilling = false

    fun shouldRefill(): Boolean =
        !refilling && playback.currentQueueCount() <= refillThreshold && playback.canAppend()

    suspend fun refill(trackIDs: List<String>): Boolean {
        if (!shouldRefill() || trackIDs.isEmpty()) return false

        refilling = true
        return try {
            val resolved = resolver.resolve(trackIDs)
            if (resolved.itemCount == 0) return false
            playback.append(resolved.asPlaybackQueueItemProvider())
            true
        } finally {
            refilling = false
        }
    }
}
