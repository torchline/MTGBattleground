typedef enum : NSUInteger {
	UserPositionSouth = 1,
	UserPositionWest,
	UserPositionNorth,
	UserPositionEast
} UserPosition;

typedef enum : NSUInteger {
	MatchPauseReasonScreenLocked = 1,
	MatchPauseReasonUserPaused,
} MatchPauseReason;