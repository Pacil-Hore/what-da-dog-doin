extends Resource
class_name LaneConfig

enum LaneType { ROCK_LANE, LOG_LANE, MIXED_LANE }

@export var type: LaneType = LaneType.ROCK_LANE
@export var current_speed: float = 50.0  # cuma dipake LOG_LANE
@export var current_direction: Vector2 = Vector2.RIGHT
@export var platform_count: int = 3  # berapa platform di lane ini
@export var min_gap: float = 100.0  # gap minimum antar platform
