extends CharacterBody2D
## 玩家控制器 - 丝之歌级手感
## 统一输入缓冲队列 · 土狼时间 · 墙跳滑墙 · 空中冲刺
## 上劈/下劈/冲刺攻击 · pogo反弹 · 残影 · 硬直取消链

# === 节点引用 ===
@onready var _visual: Node2D = $VisualRoot
@onready var _anim_player: AnimationPlayer = $AnimationPlayer
@onready var _attack_area: Area2D = $AttackArea
@onready var _attack_shape: CollisionShape2D = $AttackArea/AttackShape
@onready var _camera: Camera2D = $Camera2D
@onready var _land_dust: CPUParticles2D = $LandDust
@onready var _dash_dust: CPUParticles2D = $DashDust
@onready var _wall_ray_l: RayCast2D = $WallRayL
@onready var _wall_ray_r: RayCast2D = $WallRayR
@onready var _ghost_container: Node2D = $GhostContainer

# === 移动状态 ===
var _facing: int = 1
var _coyote_timer: float = 0.0
var _can_double_jump: bool = false
var _has_double_jumped: bool = false
var _was_in_air: bool = false
var _prev_velocity_y: float = 0.0
var _is_fast_falling: bool = false
var _turn_velocity_x: float = 0.0  # 转身衰减缓存

# === 墙跳状态 ===
var _is_wall_sliding: bool = false
var _wall_dir: int = 0  # -1 左墙, 1 右墙, 0 无
var _wall_stick_timer: float = 0.0  # 离墙后仍可蹬墙的宽限时间
var _wall_jump_lock_timer: float = 0.0  # 蹬墙后锁定水平输入

# === 冲刺 ===
var _is_dashing: bool = false
var _dash_timer: float = 0.0
var _dash_cooldown: float = 0.0
var _dash_direction: Vector2 = Vector2.ZERO
var _air_dash_count: int = 0
var _ghost_timer: float = 0.0

# === 攻击 ===
enum AttackType { NORMAL, UP, DOWN, DASH }
var _attack_type: AttackType = AttackType.NORMAL
var _is_attacking: bool = false
var _attack_timer: float = 0.0
var _attack_elapsed: float = 0.0
var _combo_count: int = 0
var _combo_window: float = 0.0
var _hit_targets: Array[Node2D] = []

# === 输入缓冲队列 ===
var _buffer_jump: float = 0.0
var _buffer_dash: float = 0.0
var _buffer_attack: float = 0.0

# === Squash & Stretch ===
var _squash_target: Vector2 = Vector2.ONE
var _squash_reset_timer: float = 0.0

# === 无敌 ===
var _is_invincible: bool = false
var _hurt_invincible_timer: float = 0.0


func _ready() -> void:
	_attack_shape.disabled = true
	_attack_area.body_entered.connect(_on_attack_body_entered)
	_attack_area.area_entered.connect(_on_attack_area_entered)
	if _wall_ray_l:
		_wall_ray_l.enabled = true
	if _wall_ray_r:
		_wall_ray_r.enabled = true
	if BodyPartManager.has_ability("double_jump"):
		_can_double_jump = true


func _physics_process(delta: float) -> void:
	# 全局命中停顿 - 冻结所有物理实体
	if GameManager.is_in_hit_stop():
		return

	_update_buffers(delta)
	_update_timers(delta)
	_update_wall_detection()

	if _is_dashing:
		_handle_dash(delta)
	else:
		_apply_gravity(delta)
		_handle_wall_slide(delta)
		_handle_movement(delta)
		_handle_jump()
		_handle_dash_input()
		_handle_attack()

	_handle_items()
	_handle_attack_cancel_into_dash()

	move_and_slide()

	_check_landing()
	_update_facing()
	_update_camera_lookahead()
	_prev_velocity_y = velocity.y


func _process(delta: float) -> void:
	_update_squash(delta)
	_update_modulate(delta)


# ====================
# 输入缓冲系统
# ====================
func _update_buffers(delta: float) -> void:
	if _buffer_jump > 0.0:
		_buffer_jump -= delta
	if _buffer_dash > 0.0:
		_buffer_dash -= delta
	if _buffer_attack > 0.0:
		_buffer_attack -= delta


func _update_timers(delta: float) -> void:
	if _dash_cooldown > 0.0:
		_dash_cooldown -= delta
	if _wall_stick_timer > 0.0:
		_wall_stick_timer -= delta
	if _wall_jump_lock_timer > 0.0:
		_wall_jump_lock_timer -= delta
	if _combo_window > 0.0:
		_combo_window -= delta
		if _combo_window <= 0.0:
			_combo_count = 0
	if _is_attacking:
		_attack_elapsed += delta
		_attack_timer -= delta
		if _attack_timer <= 0.0:
			_end_attack()
	if _hurt_invincible_timer > 0.0:
		_hurt_invincible_timer -= delta
		if _hurt_invincible_timer <= 0.0:
			_is_invincible = false


# ====================
# 墙体检测
# ====================
func _update_wall_detection() -> void:
	var was_on_wall := _wall_dir != 0
	_wall_dir = 0
	if not is_on_floor():
		if _wall_ray_l and _wall_ray_l.is_colliding():
			_wall_dir = -1
		elif _wall_ray_r and _wall_ray_r.is_colliding():
			_wall_dir = 1
		elif is_on_wall():
			# 后备：用 CharacterBody2D 的墙检
			_wall_dir = -1 if velocity.x < 0 else 1

	if _wall_dir != 0:
		_wall_stick_timer = GameConstants.PLAYER_WALL_STICK_TIME
	# 滑墙状态判定：贴墙 + 在空中 + 朝墙方向有输入或自然下落
	var input_x := Input.get_axis("move_left", "move_right")
	_is_wall_sliding = _wall_dir != 0 and not is_on_floor() and velocity.y > 0.0


# ====================
# 重力
# ====================
func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		_coyote_timer = GameConstants.PLAYER_COYOTE_TIME
		_has_double_jumped = false
		_air_dash_count = 0
		_is_fast_falling = false
		return

	# 快落判定：长按下键且正在下落
	var input_y := Input.get_axis("move_up", "move_down")
	if input_y > 0.3 and velocity.y > GameConstants.PLAYER_FAST_FALL_THRESHOLD:
		_is_fast_falling = true

	var max_fall := GameConstants.PLAYER_MAX_FALL_SPEED
	if _is_fast_falling:
		max_fall = GameConstants.PLAYER_FAST_FALL_SPEED

	velocity.y = minf(velocity.y + GameConstants.PLAYER_GRAVITY * delta, max_fall)
	_coyote_timer -= delta


# ====================
# 滑墙
# ====================
func _handle_wall_slide(delta: float) -> void:
	if not _is_wall_sliding:
		return
	# 贴墙时限制下落速度
	var target := GameConstants.PLAYER_WALL_SLIDE_SPEED
	if velocity.y < GameConstants.PLAYER_CLING_SPEED:
		target = GameConstants.PLAYER_CLING_SPEED
	velocity.y = move_toward(velocity.y, target, GameConstants.PLAYER_WALL_SLIDE_ACCEL * delta)
	# 滑墙形变
	if _squash_reset_timer <= 0.0:
		_squash(GameConstants.PLAYER_SQUASH_WALL_SLIDE, 0.05)


# ====================
# 移动
# ====================
func _handle_movement(delta: float) -> void:
	var input_x := Input.get_axis("move_left", "move_right")
	var on_floor := is_on_floor()
	var accel := GameConstants.PLAYER_ACCELERATION if on_floor else GameConstants.PLAYER_AIR_ACCELERATION
	var friction := GameConstants.PLAYER_FRICTION if on_floor else GameConstants.PLAYER_AIR_FRICTION

	# 蹬墙跳后锁定水平输入，让弹射更干脆
	if _wall_jump_lock_timer > 0.0:
		# 锁定期间仍允许反方向输入来提前取消锁定
		if input_x != 0 and signf(input_x) != _facing:
			_wall_jump_lock_timer = 0.0
		else:
			velocity.x = move_toward(velocity.x, 0.0, friction * delta * 0.5)
			return

	if input_x != 0.0:
		# 转身检测：方向反转时给一个快速的减速→加速过渡
		if signf(input_x) != signf(velocity.x) and absf(velocity.x) > 30.0:
			velocity.x = move_toward(velocity.x, 0.0, friction * delta * 1.5)
			if absf(velocity.x) < 20.0:
				_squash(GameConstants.PLAYER_SQUASH_TURN, 0.06)
		else:
			velocity.x = move_toward(velocity.x, input_x * GameConstants.PLAYER_MOVE_SPEED, accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)


# ====================
# 跳跃（普通/二段/蹬墙跳）
# ====================
func _handle_jump() -> void:
	if Input.is_action_just_pressed("jump"):
		_buffer_jump = GameConstants.PLAYER_BUFFER_JUMP

	# 可变跳跃高度 - 松开跳跃键截断上升
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= GameConstants.PLAYER_JUMP_CUT_MULTIPLIER

	if _buffer_jump <= 0.0:
		return

	# 优先级 1：蹬墙跳（贴墙或墙宽限时间内）
	if _wall_dir != 0 or _wall_stick_timer > 0.0:
		var wdir := _wall_dir if _wall_dir != 0 else (_wall_stick_timer > 0.0 and _wall_dir == 0)
		_wall_jump()
		_buffer_jump = 0.0
		return

	# 优先级 2：普通跳跃（含土狼时间）
	if _coyote_timer > 0.0:
		velocity.y = GameConstants.PLAYER_JUMP_VELOCITY
		_coyote_timer = 0.0
		_buffer_jump = 0.0
		_squash(GameConstants.PLAYER_SQUASH_JUMP, 0.1)
		_dash_dust.direction = Vector2(0, -1)
		_dash_dust.emitting = true
		return

	# 优先级 3：二段跳
	if _can_double_jump and not _has_double_jumped:
		velocity.y = GameConstants.PLAYER_JUMP_VELOCITY * GameConstants.PLAYER_DOUBLE_JUMP_MULT
		_has_double_jumped = true
		_buffer_jump = 0.0
		_squash(GameConstants.PLAYER_SQUASH_JUMP, 0.08)
		# 二段跳粒子
		_dash_dust.direction = Vector2(0, 1)
		_dash_dust.emitting = true


func _wall_jump() -> void:
	# 蹬墙跳：向墙的反方向弹出
	var push_dir := -_wall_dir if _wall_dir != 0 else -_facing
	velocity.x = push_dir * GameConstants.PLAYER_WALL_JUMP_VX
	velocity.y = GameConstants.PLAYER_WALL_JUMP_VY
	_facing = push_dir
	_wall_jump_lock_timer = GameConstants.PLAYER_WALL_JUMP_LOCK_TIME
	_wall_stick_timer = 0.0
	_has_double_jumped = false
	_air_dash_count = 0
	_squash(GameConstants.PLAYER_SQUASH_JUMP, 0.08)
	_camera.add_trauma(GameConstants.SHAKE_DASH * 0.5)
	# 墙跳粒子
	_dash_dust.direction = Vector2(push_dir, 0)
	_dash_dust.emitting = true


# ====================
# 冲刺（地面/空中 + 残影）
# ====================
func _handle_dash_input() -> void:
	if Input.is_action_just_pressed("dash"):
		_buffer_dash = GameConstants.PLAYER_BUFFER_DASH

	if _buffer_dash <= 0.0:
		return
	if _dash_cooldown > 0.0 or _is_dashing:
		return

	# 空中冲刺次数限制
	if not is_on_floor() and _air_dash_count >= GameConstants.PLAYER_AIR_DASH_COUNT:
		return

	# 冲刺取消攻击
	if _is_attacking:
		_end_attack()

	_start_dash()
	_buffer_dash = 0.0


func _start_dash() -> void:
	_is_dashing = true
	_is_invincible = true
	_dash_timer = GameConstants.PLAYER_DASH_DURATION
	_dash_cooldown = GameConstants.PLAYER_DASH_COOLDOWN
	_ghost_timer = 0.0

	# 方向：优先输入方向，否则朝 facing
	var input_x := Input.get_axis("move_left", "move_right")
	var input_y := Input.get_axis("move_up", "move_down")
	if input_x != 0.0 or input_y != 0.0:
		_dash_direction = Vector2(input_x, input_y).normalized()
		if input_x != 0.0:
			_facing = int(signf(input_x))
	else:
		_dash_direction = Vector2(_facing, 0.0)

	velocity = _dash_direction * GameConstants.PLAYER_DASH_SPEED
	_squash(GameConstants.PLAYER_SQUASH_DASH, 0.1)
	_camera.add_trauma(GameConstants.SHAKE_DASH)
	_dash_dust.direction = -_dash_direction
	_dash_dust.emitting = true

	if not is_on_floor():
		_air_dash_count += 1


func _handle_dash(delta: float) -> void:
	_dash_timer -= delta
	velocity = _dash_direction * GameConstants.PLAYER_DASH_SPEED

	# 残影生成
	_ghost_timer -= delta
	if _ghost_timer <= 0.0:
		_spawn_ghost()
		_ghost_timer = GameConstants.PLAYER_DASH_GHOST_INTERVAL

	if _dash_timer <= 0.0:
		_end_dash()


func _end_dash() -> void:
	_is_dashing = false
	_is_invincible = false
	# 保留部分冲刺惯性 + 微上抬
	velocity = _dash_direction * GameConstants.PLAYER_DASH_END_SPEED
	if not is_on_floor() and velocity.y > 0.0:
		velocity.y += GameConstants.PLAYER_DASH_END_LIFT
	_squash(Vector2(0.85, 1.15), 0.08)


# ====================
# 残影系统
# ====================
func _spawn_ghost() -> void:
	if not _ghost_container:
		return
	# 复制视觉外观做残影
	var ghost := ColorRect.new()
	ghost.color = Color(0.4, 0.75, 0.85, 0.45)
	ghost.size = Vector2(22, 34)
	ghost.position = _visual.global_position - Vector2(11, 17)
	ghost.scale = _visual.scale
	_ghost_container.add_child(ghost)

	var tween := create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, GameConstants.PLAYER_DASH_GHOST_LIFETIME)
	tween.tween_callback(ghost.queue_free)


# ====================
# 攻击（普通连击/上劈/下劈/冲刺攻击）
# ====================
func _handle_attack() -> void:
	if Input.is_action_just_pressed("attack"):
		_buffer_attack = GameConstants.PLAYER_BUFFER_ATTACK

	if _buffer_attack <= 0.0:
		return

	# 冲刺中按攻击 → 冲刺攻击
	if _is_dashing:
		_start_dash_attack()
		_buffer_attack = 0.0
		return

	if _is_attacking and _combo_window <= 0.0:
		return

	# 判定攻击变体
	var input_y := Input.get_axis("move_up", "move_down")
	if input_y < -0.3 and not is_on_floor():
		_start_attack(AttackType.UP)
	elif input_y > 0.3 and not is_on_floor():
		_start_attack(AttackType.DOWN)
	else:
		_start_attack(AttackType.NORMAL)
	_buffer_attack = 0.0


func _start_attack(type: AttackType) -> void:
	if _is_attacking and type == AttackType.NORMAL and _combo_window > 0.0:
		_combo_count = (_combo_count + 1) % GameConstants.PLAYER_ATTACK_MAX_COMBO
	else:
		_combo_count = 0

	_attack_type = type
	_is_attacking = true
	_attack_elapsed = 0.0
	_hit_targets.clear()
	_attack_shape.disabled = false

	match type:
		AttackType.NORMAL:
			_attack_timer = GameConstants.PLAYER_ATTACK_DURATION
			_attack_area.position = Vector2(24.0 * _facing, 0.0)
			var shape := _attack_shape.shape as RectangleShape2D
			match _combo_count:
				0: shape.size = Vector2(36, 28)
				1: shape.size = Vector2(42, 32)
				2: shape.size = Vector2(50, 36)
			velocity.x += _facing * 60.0  # 攻击微前冲
		AttackType.UP:
			_attack_timer = GameConstants.PLAYER_ATTACK_UP_DURATION
			_attack_area.position = Vector2(0.0, -28.0)
			(_attack_shape.shape as RectangleShape2D).size = GameConstants.PLAYER_ATTACK_UP_SIZE
			velocity.y = minf(velocity.y, -40.0)  # 上劈微上抬
		AttackType.DOWN:
			_attack_timer = GameConstants.PLAYER_ATTACK_DOWN_DURATION
			_attack_area.position = Vector2(0.0, 28.0)
			(_attack_shape.shape as RectangleShape2D).size = GameConstants.PLAYER_ATTACK_DOWN_SIZE
			velocity.y = maxf(velocity.y, 100.0)  # 下劈加速下落
		AttackType.DASH:
			_attack_timer = GameConstants.PLAYER_ATTACK_DASH_DURATION
			_attack_area.position = Vector2(28.0 * _facing, 0.0)
			(_attack_shape.shape as RectangleShape2D).size = GameConstants.PLAYER_ATTACK_DASH_SIZE


func _start_dash_attack() -> void:
	# 冲刺攻击：打断冲刺，向前高速突进挥砍
	_end_dash()
	_dash_cooldown = 0.0  # 冲刺攻击不消耗冲刺CD，鼓励组合使用
	_attack_type = AttackType.DASH
	_is_attacking = true
	_attack_elapsed = 0.0
	_attack_timer = GameConstants.PLAYER_ATTACK_DASH_DURATION
	_hit_targets.clear()
	_attack_shape.disabled = false
	_attack_area.position = Vector2(28.0 * _facing, 0.0)
	(_attack_shape.shape as RectangleShape2D).size = GameConstants.PLAYER_ATTACK_DASH_SIZE
	velocity = Vector2(_facing, 0.0) * GameConstants.PLAYER_ATTACK_DASH_SPEED
	_squash(GameConstants.PLAYER_SQUASH_DASH, 0.1)
	_camera.add_trauma(GameConstants.SHAKE_DASH)


func _end_attack() -> void:
	_is_attacking = false
	_attack_shape.disabled = true
	if _attack_type == AttackType.NORMAL:
		_combo_window = GameConstants.PLAYER_ATTACK_COMBO_WINDOW
	else:
		_combo_window = 0.0


# 攻击启动后短窗口内可用冲刺取消
func _handle_attack_cancel_into_dash() -> void:
	if _is_attacking and _buffer_dash > 0.0 and _attack_elapsed <= GameConstants.PLAYER_ATTACK_CANCEL_WINDOW:
		if _dash_cooldown <= 0.0:
			_end_attack()
			# _buffer_dash 仍 > 0，下一帧的 _handle_dash_input 会消费它


func _on_attack_body_entered(body: Node2D) -> void:
	_process_hit(body)


func _on_attack_area_entered(area: Area2D) -> void:
	# 可击中可破坏物等 Area
	_process_hit(area)


func _process_hit(target: Node) -> void:
	if target in _hit_targets:
		return
	if target is Node2D and not target.is_in_group(GameConstants.GROUP_ENEMIES):
		# 允许命中非敌人但可受击的对象（如可破坏物）
		if not target.has_method("apply_knockback"):
			return
	_hit_targets.append(target)

	# 根据攻击类型决定反馈
	match _attack_type:
		AttackType.UP:
			GameManager.trigger_hit_stop(GameConstants.PLAYER_ATTACK_HIT_STOP_UP)
			_camera.add_trauma(GameConstants.SHAKE_ATTACK_HIT)
			# 上劈命中向下反作用
			velocity.y = maxf(velocity.y, GameConstants.PLAYER_ATTACK_RECOIL * 0.5)
		AttackType.DOWN:
			GameManager.trigger_hit_stop(GameConstants.PLAYER_ATTACK_HIT_STOP_DOWN)
			_camera.add_trauma(GameConstants.SHAKE_ATTACK_HIT * 1.3)
			# pogo 反弹 - 丝之歌标志性的下劈弹跳
			var bounce := GameConstants.PLAYER_POGO_BOUNCE
			if target.is_in_group(GameConstants.GROUP_ENEMIES):
				bounce = GameConstants.PLAYER_POGO_BOUNCE_ENEMY
			velocity.y = bounce
			_squash(GameConstants.PLAYER_SQUASH_POGO, 0.1)
			# pogo 粒子
			_land_dust.emitting = true
			# 重置空中能力 - pogo 给予新的冲刺和二段跳机会
			_air_dash_count = 0
			_has_double_jumped = false
		AttackType.DASH:
			GameManager.trigger_hit_stop(GameConstants.PLAYER_ATTACK_HIT_STOP_DASH)
			_camera.add_trauma(GameConstants.SHAKE_ATTACK_HIT * 1.2)
			# 冲刺攻击命中后后坐力减速
			velocity.x *= 0.2
		AttackType.NORMAL:
			GameManager.trigger_hit_stop(GameConstants.PLAYER_HIT_STOP_DURATION)
			_camera.add_trauma(GameConstants.SHAKE_ATTACK_HIT)
			velocity.x *= 0.3  # 命中减速增强打击感

	# 击退敌人
	if target.has_method("apply_knockback"):
		var kb_dir := Vector2(_facing, -0.3)
		if _attack_type == AttackType.UP:
			kb_dir = Vector2(0.0, -1.0)
		elif _attack_type == AttackType.DOWN:
			kb_dir = Vector2(0.0, 1.0)
		elif _attack_type == AttackType.DASH:
			kb_dir = Vector2(_facing, 0.0)
		target.apply_knockback(kb_dir.normalized(), GameConstants.PLAYER_ATTACK_KNOCKBACK)


# ====================
# 道具快捷栏
# ====================
func _handle_items() -> void:
	if Input.is_action_just_pressed("use_active_1"):
		InventoryManager.use_active_item(0)
	elif Input.is_action_just_pressed("use_active_2"):
		InventoryManager.use_active_item(1)
	elif Input.is_action_just_pressed("use_active_3"):
		InventoryManager.use_active_item(2)


# ====================
# 落地检测
# ====================
func _check_landing() -> void:
	var in_air := not is_on_floor()
	if _was_in_air and not in_air:
		var fall_speed := absf(_prev_velocity_y)
		var intensity := clampf(fall_speed / 400.0, 0.0, 1.0)
		_squash(GameConstants.PLAYER_SQUASH_LAND, 0.08)
		if fall_speed > 150.0:
			_land_dust.emitting = true
			_camera.add_trauma(lerpf(GameConstants.SHAKE_LAND_LIGHT, GameConstants.SHAKE_LAND_HEAVY, intensity))
		# 落地重置空中能力
		_air_dash_count = 0
		_has_double_jumped = false
		_is_fast_falling = false
	_was_in_air = in_air


# ====================
# 朝向
# ====================
func _update_facing() -> void:
	var input_x := Input.get_axis("move_left", "move_right")
	if input_x > 0.1:
		_facing = 1
	elif input_x < -0.1:
		_facing = -1


# ====================
# 相机前瞻
# ====================
func _update_camera_lookahead() -> void:
	var dir := Vector2.ZERO
	if absf(velocity.x) > 20.0:
		dir.x = signf(velocity.x)
	if _is_dashing and _dash_direction.y < -0.3:
		dir.y = -1.0
	elif _is_dashing and _dash_direction.y > 0.3:
		dir.y = 1.0
	_camera.set_lookahead(dir)


# ====================
# Squash & Stretch
# ====================
func _squash(target: Vector2, reset_delay: float) -> void:
	_squash_target = target
	_squash_reset_timer = reset_delay


func _update_squash(delta: float) -> void:
	if _squash_reset_timer > 0.0:
		_squash_reset_timer -= delta
		if _squash_reset_timer <= 0.0:
			_squash_target = Vector2.ONE
	var abs_x := absf(_visual.scale.x)
	abs_x = lerpf(abs_x, _squash_target.x, delta * GameConstants.PLAYER_SQUASH_LERP)
	var sy := lerpf(_visual.scale.y, _squash_target.y, delta * GameConstants.PLAYER_SQUASH_LERP)
	_visual.scale = Vector2(abs_x * _facing, sy)


# ====================
# 透明度/闪烁
# ====================
func _update_modulate(delta: float) -> void:
	if _is_dashing:
		_visual.modulate.a = lerpf(_visual.modulate.a, 0.65, delta * 10.0)
	elif _is_invincible:
		_visual.modulate.a = 0.35 if fmod(Time.get_ticks_msec(), 120.0) < 60.0 else 1.0
	else:
		_visual.modulate.a = lerpf(_visual.modulate.a, 1.0, delta * 10.0)


# ====================
# 外部接口
# ====================
func apply_knockback(direction: Vector2, force: float) -> void:
	if _is_invincible:
		return
	velocity = direction * force
	_is_invincible = true
	_hurt_invincible_timer = 0.6
	_camera.add_trauma(GameConstants.SHAKE_HURT)


func get_facing() -> int:
	return _facing
