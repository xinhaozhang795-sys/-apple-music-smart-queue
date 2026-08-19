import SmartQueueCore

// Transitional compatibility surface.
//
// The repository already has stable domain contracts in SmartQueueCore. These
// aliases let new targets depend on SmartQueueDomain without duplicating or
// breaking the existing public API. The canonical definitions will move here
// incrementally once their downstream users have been migrated.
public typealias TrackCandidate = SmartQueueCore.TrackCandidate
public typealias CandidateSource = SmartQueueCore.CandidateSource
public typealias CurrentTrackContext = SmartQueueCore.CurrentTrackContext
public typealias QueuePolicy = SmartQueueCore.QueuePolicy
public typealias ScoredCandidate = SmartQueueCore.ScoredCandidate

public typealias MusicCandidateSource = SmartQueueCore.MusicCandidateSource
public typealias MusicPlaybackAdapter = SmartQueueCore.MusicPlaybackAdapter
