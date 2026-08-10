package com.xinhao.smartqueue.android

import com.apple.android.music.playback.controller.MediaPlayerController
import com.apple.android.music.playback.queue.PlaybackQueueItemProvider

/**
 * Native Android playback adapter for Smart Queue.
 *
 * Smart Queue Core decides what should be played; this adapter is responsible
 * only for translating those decisions into MusicKit for Android operations.
 */
class AppleMusicPlaybackAdapter(
    private val controller: MediaPlayerController
) {
    fun currentQueueCount(): Int = controller.getPlaybackQueueItemCount()

    fun canAppend(): Boolean = controller.canAppendToPlaybackQueue()

    fun append(provider: PlaybackQueueItemProvider) {
        check(canAppend()) { "Apple Music playback queue cannot be appended right now." }
        controller.addQueueItems(
            provider,
            /* MusicKit insertion constant is supplied by the host integration. */
            APPEND_INSERTION_TYPE
        )
    }

    fun play() = controller.play()

    fun pause() = controller.pause()

    companion object {
        /** Kept behind the adapter so Core never depends on MusicKit constants. */
        const val APPEND_INSERTION_TYPE: Int = 1
    }
}
