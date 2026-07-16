extends Control
## 结算界面 - 沉郁落幕氛围（压抑但不令人不适）

@onready var _overlay: ColorRect = $Overlay
@onready var _overlay_layer: ColorRect = $OverlayLayer
@onready var _title: Label = $Center/VBox/Title
@onready var _subtitle: Label = $Center/VBox/Subtitle
@onready var _panel: Panel = $Center/VBox/MenuPanel
@onready var _retry_button: Button = $Center/VBox/MenuPanel/VBox/RetryButton
@onready var _main_menu_button: Button = $Center/VBox/MenuPanel/VBox/MainMenuButton
@onready var _hint: Label = $Center/VBox/Hint

func _ready() -> void:
	# 沉郁落幕色调（暗珊瑚而非血红）
	_overlay.color = Color(0.08, 0.06, 0.10, 0.78)
	_overlay_layer.color = Color(
		GameConstants.THEME_ACCENT_CORAL.r,
		GameConstants.THEME_ACCENT_CORAL.g,
		GameConstants.THEME_ACCENT_CORAL.b,
		0.12
	)

	# 标题：暗珊瑚色沉郁落幕
	_title.text = "潮汐褪去"
	UITheme.style_label(_title, GameConstants.THEME_ACCENT_CORAL, true)
	_title.add_theme_font_size_override("font_size", 40)

	# 副标题
	_subtitle.text = "下一次浪潮，定能更远"
	UITheme.style_label(_subtitle, GameConstants.THEME_TEXT_DIM, false)
	_subtitle.add_theme_font_size_override("font_size", 14)

	_hint.text = "按 Enter 重新启航"
	UITheme.style_label(_hint, GameConstants.THEME_TEXT_DIM, false)
	_hint.add_theme_font_size_override("font_size", 12)

	# 面板圆角化
	UITheme.style_panel(_panel, GameConstants.THEME_PANEL_BG, GameConstants.THEME_PANEL_BORDER, 12)

	# 按钮样式
	UITheme.style_button(_retry_button)
	UITheme.style_button(_main_menu_button)

	_retry_button.pressed.connect(_on_retry)
	_main_menu_button.pressed.connect(_on_main_menu)

	# 入场动画：标题下落 + 面板缩放
	_title.modulate.a = 0.0
	_title.position.y -= 20
	_subtitle.modulate.a = 0.0
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.92, 0.92)
	_panel.pivot_offset = _panel.size / 2.0
	_hint.modulate.a = 0.0

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_title, "modulate:a", 1.0, 0.5).set_delay(0.2)
	tween.tween_property(_title, "position:y", _title.position.y + 20, 0.5).set_delay(0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	tween.tween_property(_subtitle, "modulate:a", 1.0, 0.4).set_delay(0.6)
	tween.tween_property(_panel, "modulate:a", 1.0, 0.3).set_delay(0.7)
	tween.tween_property(_panel, "scale", Vector2.ONE, 0.3).set_delay(0.7).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(_hint, "modulate:a", 1.0, 0.4).set_delay(1.0)

	_retry_button.grab_focus()

func _on_retry() -> void:
	get_tree().reload_current_scene()

func _on_main_menu() -> void:
	GameManager.change_state(GameManager.GameState.MAIN_MENU)
	get_tree().reload_current_scene()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack") or event.is_action_pressed("jump"):
		if _retry_button.has_focus() or _main_menu_button.has_focus():
			return
		_on_retry()
