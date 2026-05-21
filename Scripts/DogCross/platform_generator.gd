extends Node2D
class_name RiverGenerator

@export var level_config: LevelConfig
@export var platform_scene: PackedScene
@export var start_area_scene: PackedScene
@export var finish_area_scene: PackedScene

# Reference ke entity buat starting position
@export var player: CharacterBody2D
@export var dog: CharacterBody2D

var lanes: Array[Node2D] = []  # container per lane

func _ready() -> void:
	if level_config == null:
		push_error("LevelConfig belum di-assign!")
		return
	generate_level()

func generate_level() -> void:
	var current_y: float = 0.0  # mulai dari bawah (start area di y=0)
	
	# 1. Spawn start area di paling bawah
	var start = start_area_scene.instantiate()
	start.position = Vector2(level_config.level_width / 2, current_y)
	add_child(start)
	
	# Posisikan player & dog di start area
	if player:
		player.global_position = Vector2(level_config.level_width / 2 - 100, current_y)
	if dog:
		dog.global_position = Vector2(level_config.level_width / 2 + 100, current_y)
	
	# 2. Generate lane dari bawah ke atas
	for lane_config in level_config.lane_configs:
		current_y -= level_config.lane_height
		_generate_lane(lane_config, current_y)
	
	# 3. Spawn finish area di paling atas
	current_y -= level_config.lane_height
	var finish = finish_area_scene.instantiate()
	finish.position = Vector2(level_config.level_width / 2, current_y)
	add_child(finish)

func _generate_lane(config: LaneConfig, lane_y: float) -> void:
	# Container per lane biar gampang manage
	var lane_container = Node2D.new()
	lane_container.position.y = lane_y
	add_child(lane_container)
	lanes.append(lane_container)
	
	match config.type:
		LaneConfig.LaneType.ROCK_LANE:
			_spawn_rocks(lane_container, config)
		LaneConfig.LaneType.LOG_LANE:
			_spawn_logs(lane_container, config)
		LaneConfig.LaneType.MIXED_LANE:
			_spawn_mixed(lane_container, config)

func _spawn_rocks(container: Node2D, config: LaneConfig) -> void:
	# Distribusi rock secara horizontal, dengan random size
	var available_width = level_config.level_width
	var positions = _distribute_positions(config.platform_count, available_width, config.min_gap)
	
	for pos_x in positions:
		var rock = platform_scene.instantiate()
		# Random pilih small atau big rock
		if randf() > 0.5:
			rock.type = Platform.PlatformType.SMALL_ROCK
			rock.size = Vector2(90, 90)
		else:
			rock.type = Platform.PlatformType.BIG_ROCK
			rock.size = Vector2(180, 90)
		rock.position = Vector2(pos_x, 0)
		container.add_child(rock)

func _spawn_logs(container: Node2D, config: LaneConfig):
	# Hitung interval spawn berdasarkan speed & desired spacing
	var desired_spacing = config.min_gap # jarak antar log yang diinginkan (pixel)
	var spawn_interval = desired_spacing / config.current_speed
	
	# Hitung berapa log yang muat di layar (buat prefill)
	var total_distance = level_config.level_width + 400  # layar + buffer
	var logs_to_prefill = int(total_distance / desired_spacing)
	
	# Tentuin posisi awal masing-masing log
	# Posisi-nya disusun dari edge spawn ke arah aliran
	var start_x: float
	var direction_sign: float
	if config.current_direction.x > 0:
		# Arus ke kanan: log paling awal di kiri (luar layar), log terakhir udah jauh ke kanan
		start_x = -200.0
		direction_sign = 1.0
	else:
		# Arus ke kiri: log paling awal di kanan (luar layar)
		start_x = level_config.level_width + 200.0
		direction_sign = -1.0
	
	# Prefill: spawn log dengan jarak yang sesuai dengan timing spawn
	for i in range(logs_to_prefill):
		var x_pos = start_x + (i * desired_spacing * direction_sign)
		_create_log(container, config, x_pos)
	
	# Timer buat spawn berikutnya
	var timer = Timer.new()
	timer.wait_time = spawn_interval
	timer.autostart = true
	timer.timeout.connect(func(): _spawn_log_at_edge(container, config))
	container.add_child(timer)
	
func _create_log(container: Node2D, config: LaneConfig, x_pos: float):
	var log_platform = platform_scene.instantiate()
	log_platform.type = Platform.PlatformType.WOOD_LOG
	log_platform.size = Vector2(180, 90)
	log_platform.current_speed = config.current_speed
	log_platform.current_direction = config.current_direction
	log_platform.position = Vector2(x_pos, 0)
	container.add_child(log_platform)
	
func _spawn_log_at_edge(container: Node2D, config: LaneConfig):
	# Spawn dari sisi yang berlawanan arah arus
	var spawn_x: float
	if config.current_direction.x > 0:
		spawn_x = -200.0 # arus ke kanan → spawn dari kiri
	else:
		spawn_x = level_config.level_width + 200.0 # arus ke kiri → spawn dari kanan
	
	_create_log(container, config, spawn_x)

func _spawn_mixed(container: Node2D, config: LaneConfig):
	# Mixed lane = campur small rock & big rock (tanpa log)
	var positions = _distribute_positions(config.platform_count, level_config.level_width, config.min_gap)
	
	for pos_x in positions:
		var platform = platform_scene.instantiate()
		# Random small atau big rock aja
		if randf() > 0.5:
			platform.type = Platform.PlatformType.SMALL_ROCK
			platform.size = Vector2(120, 120)
		else:
			platform.type = Platform.PlatformType.BIG_ROCK
			platform.size = Vector2(220, 120)
		platform.position = Vector2(pos_x, 0)
		container.add_child(platform)

func _distribute_positions(count: int, total_width: float, min_gap: float) -> Array:
	# Bagi width jadi N segment, taruh platform di tengah-tengah segment dengan random offset
	var positions = []
	var segment_width = total_width / count
	
	for i in range(count):
		var center = (i + 0.5) * segment_width
		# Offset lebih kecil biar gak ke pinggir segment
		var max_offset = max(0, (segment_width - min_gap) / 2)
		var offset = randf_range(-max_offset, max_offset)
		positions.append(center + offset)
	
	return positions
