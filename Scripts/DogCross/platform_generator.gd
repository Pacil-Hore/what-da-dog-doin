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
	_spawn_platforms_sequential(container, config, [
		{"type": Platform.PlatformType.SMALL_ROCK, "size": Vector2(90, 90)},
		{"type": Platform.PlatformType.BIG_ROCK, "size": Vector2(180, 90)},
	])

func _spawn_mixed(container: Node2D, config: LaneConfig) -> void:
	_spawn_platforms_sequential(container, config, [
		{"type": Platform.PlatformType.SMALL_ROCK, "size": Vector2(120, 120)},
		{"type": Platform.PlatformType.BIG_ROCK, "size": Vector2(220, 120)},
	])

# Helper baru: spawn platforms dengan edge-to-edge gap guarantee
func _spawn_platforms_sequential(container: Node2D, config: LaneConfig, platform_types: Array) -> int:
	var margin = 50.0  # margin dari edge level
	var current_x = margin  # mulai dari kiri
	var spawned_count = 0
	
	for i in range(config.platform_count):
		# Pilih random tipe platform
		var chosen = platform_types.pick_random()
		var chosen_size: Vector2 = chosen["size"]
		var chosen_type = chosen["type"]
		
		# Cek apakah masih muat
		# Butuh: current_x + width + margin <= level_width
		if current_x + chosen_size.x + margin > level_config.level_width:
			print("Lane penuh, cuma muat ", spawned_count, " dari ", config.platform_count, " platform")
			break
		
		# Random extra offset (biar gak terlalu rapi/predictable)
		var max_extra = 50.0  # max offset acak ke kanan
		var extra_offset = randf_range(0, max_extra)
		
		# Cek kalau ditambah extra_offset masih muat
		if current_x + extra_offset + chosen_size.x + margin > level_config.level_width:
			extra_offset = 0
		
		current_x += extra_offset
		
		# Center platform = current_x + half width
		var center_x = current_x + chosen_size.x / 2
		
		# Spawn
		var platform = platform_scene.instantiate()
		platform.type = chosen_type
		platform.size = chosen_size
		platform.position = Vector2(center_x, 0)
		container.add_child(platform)
		spawned_count += 1
		
		# Update current_x ke edge kanan + min_gap untuk platform berikutnya
		current_x = center_x + chosen_size.x / 2 + config.min_gap
	
	return spawned_count

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
