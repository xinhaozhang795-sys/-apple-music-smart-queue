package com.xinhao.smartqueue.android

import com.apple.android.music.playback.controller.MediaPlayerController
import com.apple.android.music.playback.queue.PlaybackQueueInsertionType
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
        check(canAppend()) { "Apple Music playback queue cannot be appended to right now." }
        controller.addQueueItems(
            provider,
            PlaybackQueueInsertionType.INSERTION_TYPE_AT_END
        )
    }

    fun play() = controller.play()

    fun pause() = controller.pause()
}
