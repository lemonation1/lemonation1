extends CharacterBody2D

const GRAVITY: float = 980.0
const MOVE_SPEED: float = 200.0
const JUMP_VELOCITY: float = -400.0
const ACCELERATION: float = 1200.0
const FRICTION: float = 1400.0
const COYOTE_TIME: float = 0.1
const JUMP_BUFFER: float = 0.1

var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _can_double_jump: bool = false
var _has_double_jumped: bool = false
var _facing: int = 1  # 1=右, -1=左

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _anim_player: AnimationPlayer = $AnimationPlayer
@onready var _attack_area: Area2D = $AttackArea
@onready var _attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D

func _ready() -> void:
    _attack_shape.disabled = true
    # 根据部件能力解锁二段跳
    if BodyPartManager.has_ability("double_jump"):
        _can_double_jump = true

func _physics_process(delta: float) -> void:
    _apply_gravity(delta)
    _handle_movement(delta)
    _handle_jump(delta)
    _handle_attack()
    move_and_slide()
    _update_facing()
    _update_animation()

func _apply_gravity(delta: float) -> void:
    if not is_on_floor():
        velocity.y += GRAVITY * delta
        _coyote_timer -= delta
    else:
        _coyote_timer = COYOTE_TIME
        _has_double_jumped = false

func _handle_movement(delta: float) -> void:
    var input_x = Input.get_axis("move_left", "move_right")
    if input_x != 0:
        velocity.x = move_toward(velocity.x, input_x * MOVE_SPEED, ACCELERATION * delta)
    else:
        velocity.x = move_toward(velocity.x, 0, FRICTION * delta)

func _handle_jump(delta: float) -> void:
    if Input.is_action_just_pressed("jump"):
        _jump_buffer_timer = JUMP_BUFFER

    if _jump_buffer_timer > 0:
        _jump_buffer_timer -= delta

    if _jump_buffer_timer > 0 and _coyote_timer > 0:
        velocity.y = JUMP_VELOCITY
        _coyote_timer = 0
        _jump_buffer_timer = 0
    elif _jump_buffer_timer > 0 and _can_double_jump and not _has_double_jumped and not is_on_floor():
        velocity.y = JUMP_VELOCITY * 0.85
        _has_double_jumped = true
        _jump_buffer_timer = 0

    # 可变跳跃高度
    if Input.is_action_just_released("jump") and velocity.y < 0:
        velocity.y *= 0.5

func _handle_attack() -> void:
    if Input.is_action_just_pressed("attack"):
        _attack_shape.disabled = false
        # 攻击方向跟随面朝
        _attack_area.position.x = 24 * _facing
        # TODO: 根据装备部件修改攻击范围/伤害
        await get_tree().create_timer(0.2).timeout
        _attack_shape.disabled = true

    # 快捷栏道具
    if Input.is_action_just_pressed("use_active_1"):
        InventoryManager.use_active_item(0)
    elif Input.is_action_just_pressed("use_active_2"):
        InventoryManager.use_active_item(1)
    elif Input.is_action_just_pressed("use_active_3"):
        InventoryManager.use_active_item(2)

func _update_facing() -> void:
    if velocity.x > 5:
        _facing = 1
        _sprite.flip_h = false
    elif velocity.x < -5:
        _facing = -1
        _sprite.flip_h = true

func _update_animation() -> void:
    if not is_on_floor():
        if velocity.y < 0:
            _anim_player.play("jump")
        else:
            _anim_player.play("fall")
    elif abs(velocity.x) > 10:
        _anim_player.play("run")
    else:
        _anim_player.play("idle")

func apply_knockback(direction: Vector2, force: float) -> void:
    velocity = direction * force

func get_facing() -> int:
    return _facing
