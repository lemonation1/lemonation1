extends Control
## Q版暂停菜单 - 柔和半透明遮罩 + 圆角面板

@onready var _overlay: ColorRect = $Overlay
@onready var _panel: Panel = $Center/VBox/MenuPanel
@onready var _title: Label = $Center/VBox/Title
@onready var _hint: Label = $Center/VBox/Hint
@onready var _resume_button: Button = $Center/VBox/MenuPanel/VBox/ResumeButton
@onready var _save_button: Button = $Center/VBox/MenuPanel/VBox/SaveButton
@onready var _main_menu_button: Button = $Center/VBox/MenuPanel/VBox/MainMenuButton

func _ready() -> void:
	# 柔和半透明遮罩（深蓝调而非纯黑）
	_overlay.color = Color(0.04, 0.05, 0.10, 0.65)

	# 标题
	_title.text = "暂停休憩"
	UITheme.style_label(_title, GameConstants.THEME_ACCENT_CYAN, true)
	_title.add_theme_font_size_override("font_size", 32)

	# 提示
	_hint.text = "按 Esc 继续"
	UITheme.style_label(_hint, GameConstants.THEME_TEXT_DIM, false)
	_hint.add_theme_font_size_override("font_size", 12)

	# 面板圆角化
	UITheme.style_panel(_panel, GameConstants.THEME_PANEL_BG, GameConstants.THEME_PANEL_BORDER, 12)

	# 按钮样式
	UITheme.style_button(_resume_button)
	UITheme.style_button(_save_button)
	UITheme.style_button(_main_menu_button)

	# 信号
	_resume_button.pressed.connect(_on_resume)
	_save_button.pressed.connect(_on_save)
	_main_menu_button.pressed.connect(_on_main_menu)

	# 入场动画：面板缩放淡入
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.92, 0.92)
	_panel.pivot_offset = _panel.size / 2.0

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_panel, "modulate:a", 1.0, 0.22)
	tween.tween_property(_panel, "scale", Vector2.ONE, 0.22).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	_resume_button.grab_focus()

func _on_resume() -> void:
	GameManager.change_state(GameManager.GameState.PLAYING)
	queue_free()

func _on_save() -> void:
	SaveManager.save_game(0)
	EventBus.show_notification.emit("旅程已记录", 0)

func _on_main_menu() -> void:
	GameManager.change_state(GameManager.GameState.MAIN_MENU)
	get_tree().reload_current_scene()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("escape"):
		_on_resume()
		get_viewport().set_input_as_handled()
