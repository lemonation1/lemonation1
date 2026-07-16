extends Control
## Q版柔和风格HUD

@onready var _san_panel: Panel = $TopLeft/SANPanel
@onready var _san_bar: ProgressBar = $TopLeft/SANPanel/SANContainer/SANBar
@onready var _san_label: Label = $TopLeft/SANPanel/SANContainer/SANBar/SANLabel
@onready var _san_stage_label: Label = $TopLeft/SANStageLabel
@onready var _info_panel: Panel = $TopRight/InfoPanel
@onready var _faction_label: Label = $TopRight/InfoPanel/InfoContainer/FactionLabel
@onready var _world_layer_label: Label = $TopRight/InfoPanel/InfoContainer/WorldLayerLabel
@onready var _active_slots_container: HBoxContainer = $BottomCenter/ActiveSlots
@onready var _notification_label: Label = $Center/Notification


func _ready() -> void:
	_apply_theme()
	EventBus.san_changed.connect(_on_san_changed)
	EventBus.san_stage_changed.connect(_on_san_stage_changed)
	EventBus.show_notification.connect(_on_show_notification)
	EventBus.world_switched.connect(_on_world_switched)
	EventBus.faction_level_changed.connect(_on_faction_changed)
	EventBus.active_item_used.connect(_on_active_item_used)
	_update_san_display(SANManager.current_san, SANManager.san_max)
	_update_stage_display(SANManager.get_stage())


func _apply_theme() -> void:
	UITheme.style_panel(_san_panel)
	UITheme.style_panel(_info_panel)

	# SAN 条样式
	var styles := UITheme.make_bar_styles(GameConstants.THEME_SAN_HEALTHY)
	_san_bar.add_theme_stylebox_override("background", styles["background"])
	_san_bar.add_theme_stylebox_override("fill", styles["fill"])

	# 快捷栏槽位样式
	var slot_style := UITheme.make_panel_style(GameConstants.THEME_PANEL_BG, GameConstants.THEME_ACCENT_CYAN, 6)
	for slot in _active_slots_container.get_children():
		slot.add_theme_stylebox_override("panel", slot_style.duplicate())

	# 文字样式
	UITheme.style_label(_san_label, GameConstants.THEME_TEXT_LIGHT)
	UITheme.style_label(_san_stage_label, GameConstants.THEME_TEXT_LIGHT)
	UITheme.style_label(_faction_label, GameConstants.THEME_TEXT_DIM)
	UITheme.style_label(_world_layer_label, GameConstants.THEME_TEXT_DIM)
	UITheme.style_label(_notification_label, GameConstants.THEME_TEXT_LIGHT)
	_notification_label.add_theme_font_size_override("font_size", 18)


func _on_san_changed(current: float, max_san: float) -> void:
	_update_san_display(current, max_san)


func _on_san_stage_changed(stage: SANManager.SanStage) -> void:
	_update_stage_display(stage)


func _on_show_notification(text: String, type: int) -> void:
	_notification_label.text = text
	_notification_label.modulate.a = 1.0
	_notification_label.position.y = 0.0
	var tween := create_tween()
	tween.tween_interval(1.5)
	tween.parallel().tween_property(_notification_label, "modulate:a", 0.0, 0.8)
	tween.parallel().tween_property(_notification_label, "position:y", -10.0, 0.8)


func _on_world_switched(layer: int) -> void:
	_world_layer_label.text = "现实层" if layer == 0 else "幻梦境"
	var color = GameConstants.THEME_TEXT_DIM if layer == 0 else GameConstants.THEME_ACCENT_PURPLE
	_world_layer_label.add_theme_color_override("font_color", color)


func _on_faction_changed(_faction: int, _level: int) -> void:
	var dom = BuildManager.get_dominant_faction()
	_faction_label.text = "流派: %s (Lv.%d)" % [GameConstants.FACTION_NAMES[dom], BuildManager.get_faction_level(dom)]


func _on_active_item_used(slot_index: int) -> void:
	if slot_index < _active_slots_container.get_child_count():
		var slot = _active_slots_container.get_child(slot_index)
		var tween := create_tween()
		tween.tween_property(slot, "modulate", GameConstants.THEME_ACCENT_GOLD, 0.05)
		tween.tween_property(slot, "modulate", Color.WHITE, 0.25)


func _update_san_display(current: float, max_san: float) -> void:
	_san_bar.max_value = max_san
	_san_bar.value = current
	_san_label.text = "SAN: %d / %d" % [int(current), int(max_san)]

	var ratio = current / max_san if max_san > 0 else 0.0
	var color: Color
	if ratio > 0.7:
		color = GameConstants.THEME_SAN_HEALTHY
	elif ratio > 0.4:
		color = GameConstants.THEME_SAN_OKAY
	elif ratio > 0.15:
		color = GameConstants.THEME_SAN_WARN
	else:
		color = GameConstants.THEME_SAN_DANGER
	var fill_style = _san_bar.get_theme_stylebox("fill") as StyleBoxFlat
	if fill_style:
		fill_style.bg_color = color


func _update_stage_display(stage: SANManager.SanStage) -> void:
	var stage_names = ["清醒", "不安", "疯狂", "崩溃", "归零"]
	var stage_colors = [
		GameConstants.THEME_TEXT_LIGHT,
		GameConstants.THEME_SAN_OKAY,
		GameConstants.THEME_SAN_WARN,
		GameConstants.THEME_SAN_DANGER,
		GameConstants.THEME_SAN_CRITICAL
	]
	_san_stage_label.text = stage_names[stage]
	_san_stage_label.add_theme_color_override("font_color", stage_colors[stage])
