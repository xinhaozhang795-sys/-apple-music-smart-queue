package com.xinhao.smartqueue.android

import com.apple.android.music.playback.queue.PlaybackQueueItemProvider

/**
 * Platform coordinator for Android automatic queue refill.
 *
 * The coordinator deliberately does not start playback. It only appends a
 * prepared batch when the remaining queue falls below the configured threshold.
 */
class AutoRefillCoordinator(
    private val playback: AppleMusicPlaybackAdapter,
    private val refillThreshold: Int = 3
) {
    private var refilling = false

    fun shouldRefill(): Boolean =
        !refilling && playback.currentQueueCount() <= refillThreshold && playback.canAppend()

    fun refill(provider: PlaybackQueueItemProvider): Boolean {
        if (!shouldRefill()) return false

        refilling = true
        return try {
            playback.append(provider)
            true
        } finally {
            refilling = false
        }
    }
}
