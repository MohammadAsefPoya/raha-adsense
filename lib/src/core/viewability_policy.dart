/// The minimum fraction of an ad that must be visible to record an
/// impression for banner / native / interstitial formats.
const bannerVisibleFraction = 0.5;

/// The minimum duration that a banner / native / interstitial ad must remain
/// visible before recording an impression.
const bannerVisibleDuration = Duration(seconds: 1);

/// The minimum fraction of the video surface that must be visible to record
/// a video impression.
const videoVisibleFraction = 0.5;

/// The minimum duration that a video ad must remain visible before recording
/// an impression.
const videoVisibleDuration = Duration(seconds: 2);
