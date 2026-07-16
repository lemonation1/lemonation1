extends Control

@onready var _san_bar: ProgressBar = $TopLeft/SANBar
@onready var _san_label: Label = $TopLeft/SANBar/SANLabel
@onready var _san_stage_label: Label = $TopLeft/SANStageLabel
@onready var _active_slots_container: HBoxContainer = $BottomCenter/ActiveSlots
@onready var _faction_label: Label = $TopRight/FactionLabel
@onready var _notification_label: Label = $Center/Notification
@onready var _world_layer_label: Label = $TopRight/WorldLayerLabel

func _ready() -> void:
    EventBus.san_changed.connect(_on_san_changed)
    EventBus.san_stage_changed.connect(_on_san_stage_changed)
    EventBus.show_notification.connect(_on_show_notification)
    EventBus.world_switched.connect(_on_world_switched)
    EventBus.faction_level_changed.connect(_on_faction_changed)
    EventBus.active_item_used.connect(_on_active_item_used)
    _update_san_display(SANManager.current_san, SANManager.san_max)
    _update_stage_display(SANManager.get_stage())

func _on_san_changed(current: float, max_san: float) -> void:
    _update_san_display(current, max_san)

func _on_san_stage_changed(stage: SANManager.SanStage) -> void:
    _update_stage_display(stage)

func _on_show_notification(text: String, type: int) -> void:
    _notification_label.text = text
    _notification_label.modulate.a = 1.0
    var tween = create_tween()
    tween.tween_interval(2.0)
    tween.tween_property(_notification_label, "modulate:a", 0.0, 1.0)

func _on_world_switched(layer: int) -> void:
    _world_layer_label.text = "现实层" if layer == 0 else "幻梦境"
    _world_layer_label.modulate = Color.WHITE if layer == 0 else Color(0.6, 0.4, 0.9)

func _on_faction_changed(faction: int, level: int) -> void:
    var names = ["血脉", "知识", "守心"]
    var dom = BuildManager.get_dominant_faction()
    _faction_label.text = "流派: %s (Lv.%d)" % [names[dom], BuildManager.get_faction_level(dom)]

func _on_active_item_used(slot_index: int) -> void:
    # 快捷栏使用反馈
    if slot_index < _active_slots_container.get_child_count():
        var slot = _active_slots_container.get_child(slot_index)
        slot.modulate = Color.YELLOW
        var tween = create_tween()
        tween.tween_property(slot, "modulate", Color.WHITE, 0.3)

func _update_san_display(current: float, max_san: float) -> void:
    _san_bar.max_value = max_san
    _san_bar.value = current
    _san_label.text = "SAN: %d / %d" % [int(current), int(max_san)]
    var ratio = current / max_san if max_san > 0 else 0.0
    if ratio > 0.7:
        _san_bar.modulate = Color(0.3, 0.8, 0.3)
    elif ratio > 0.4:
        _san_bar.modulate = Color(0.9, 0.8, 0.2)
    elif ratio > 0.15:
        _san_bar.modulate = Color(0.9, 0.5, 0.1)
    else:
        _san_bar.modulate = Color(0.9, 0.1, 0.1)

func _update_stage_display(stage: SANManager.SanStage) -> void:
    var stage_names = ["清醒", "不安", "疯狂", "崩溃", "归零"]
    _san_stage_label.text = stage_names[stage]
    match stage:
        0: _san_stage_label.modulate = Color.WHITE
        1: _san_stage_label.modulate = Color(0.9, 0.8, 0.4)
        2: _san_stage_label.modulate = Color(0.9, 0.5, 0.3)
        3: _san_stage_label.modulate = Color(0.9, 0.2, 0.2)
        4: _san_stage_label.modulate = Color(0.5, 0.1, 0.1)
