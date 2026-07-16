extends Node

enum SanStage { SOBER, UNEASY, MAD, COLLAPSE, ZERO }

const BASE_SAN_MAX: float = 100.0
const MIN_SAN_MAX: float = 30.0
const BASE_SAN_REGEN: float = 1.0  # 每秒
const SAFE_ZONE_REGEN: float = 5.0  # 每秒
const LOW_SAN_THRESHOLD: float = 30.0
const LOW_SAN_DRAIN: float = 0.5  # 每秒
const INHERIT_RATIO: float = 0.5  # 跨轮回继承比例

var current_san: float = BASE_SAN_MAX
var san_max: float = BASE_SAN_MAX
var san_cap_loss: float = 0.0  # 永久上限损失累计
var current_stage: SanStage = SanStage.SOBER
var current_pollution_multiplier: float = 1.0
var sedative_resistance: float = 0.0  # 镇静剂抗药性
var tindalos_marked: bool = false  # 廷达罗斯追猎标记
var inherited_madness_rate: float = 0.0  # 疯狂继承触发率

func _ready() -> void:
    _update_stage()

func _process(delta: float) -> void:
    _handle_natural_regen(delta)
    _handle_pollution_drain(delta)
    _handle_tindalos_hunt(delta)
    _handle_low_san_drain(delta)

func apply_temporary_loss(amount: float, source: String) -> void:
    # 临时损失，可恢复
    current_san = max(0.0, current_san - amount)
    _update_stage()
    EventBus.san_temporary_loss.emit(amount, source)
    _check_madness_trigger(amount, source)

func apply_permanent_cap_loss(amount: float, source: String) -> void:
    # 永久上限损失，不可恢复
    san_max = max(MIN_SAN_MAX, san_max - amount)
    san_cap_loss += amount
    current_san = min(current_san, san_max)
    _update_stage()
    EventBus.san_permanent_loss.emit(amount, source)

func recover(amount: float, source: String) -> void:
    var actual_amount = amount * (1.0 - sedative_resistance if source == "sedative" else 1.0)
    current_san = min(san_max, current_san + actual_amount)
    _update_stage()

func recover_full() -> void:
    current_san = san_max
    _update_stage()

func set_pollution_multiplier(mult: float) -> void:
    current_pollution_multiplier = mult

func is_in_safe_zone() -> bool:
    return false  # 由场景设置

var _in_safe_zone: bool = false
func set_safe_zone(active: bool) -> void:
    _in_safe_zone = active

func get_stage() -> SanStage:
    return current_stage

func get_san_ratio() -> float:
    return current_san / san_max if san_max > 0 else 0.0

func reset_for_new_run(inherited_loss: float) -> void:
    var actual_inherited = inherited_loss * INHERIT_RATIO
    san_max = max(MIN_SAN_MAX, BASE_SAN_MAX - actual_inherited)
    current_san = san_max
    san_cap_loss = actual_inherited
    sedative_resistance = 0.0
    tindalos_marked = false
    _update_stage()

func mark_tindalos() -> void:
    tindalos_marked = true

func _handle_natural_regen(delta: float) -> void:
    if _in_safe_zone:
        current_san = min(san_max, current_san + SAFE_ZONE_REGEN * delta)
    elif current_stage != SanStage.ZERO:
        current_san = min(san_max, current_san + BASE_SAN_REGEN * delta)
    _update_stage_if_needed()

func _handle_pollution_drain(delta: float) -> void:
    if current_pollution_multiplier > 1.0 and not _in_safe_zone:
        var drain = (current_pollution_multiplier - 1.0) * delta / 60.0
        apply_temporary_loss(drain, "pollution")

func _handle_tindalos_hunt(delta: float) -> void:
    if tindalos_marked and not _in_safe_zone:
        apply_temporary_loss(1.0 * delta, "tindalos")
        # 每分钟1点永久损失
        _tindalos_timer += delta
        if _tindalos_timer >= 60.0:
            _tindalos_timer = 0.0
            apply_permanent_cap_loss(1.0, "tindalos")

var _tindalos_timer: float = 0.0

func _handle_low_san_drain(delta: float) -> void:
    if current_san < LOW_SAN_THRESHOLD and current_san > 0 and not _in_safe_zone:
        apply_temporary_loss(LOW_SAN_DRAIN * delta, "low_san_drain")

func _update_stage() -> void:
    var new_stage: SanStage
    if current_san <= 0:
        new_stage = SanStage.ZERO
    elif current_san <= 14:
        new_stage = SanStage.COLLAPSE
    elif current_san <= 39:
        new_stage = SanStage.MAD
    elif current_san <= 69:
        new_stage = SanStage.UNEASY
    else:
        new_stage = SanStage.SOBER
    
    if new_stage != current_stage:
        current_stage = new_stage
        EventBus.san_stage_changed.emit(current_stage)
        if current_stage == SanStage.ZERO:
            EventBus.player_died.emit("san_zero")

func _update_stage_if_needed() -> void:
    var prev = current_stage
    _update_stage()
    if prev != current_stage:
        EventBus.san_changed.emit(current_san, san_max)

func _check_madness_trigger(loss_amount: float, source: String) -> void:
    if loss_amount >= 5.0:
        var trigger_chance = 0.3 + inherited_madness_rate
        if randf() < trigger_chance:
            MadnessManager.trigger_random_madness(loss_amount, source)
