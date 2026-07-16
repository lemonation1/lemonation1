extends Control
## 主菜单 - 阴郁沉静风格，参考丝之歌的菜单观感

@onready var _bg: ColorRect = $Background
@onready var _bg_layer: ColorRect = $BackgroundLayer
@onready var _title: Label = $Center/VBox/Title
@onready var _subtitle: Label = $Center/VBox/Subtitle
@onready var _start_button: Button = $Center/VBox/MenuPanel/VBox/StartButton
@onready var _continue_button: Button = $Center/VBox/MenuPanel/VBox/ContinueButton
@onready var _quit_button: Button = $Center/VBox/MenuPanel/VBox/QuitButton
@onready var _hint: Label = $Center/VBox/Hint
@onready var _menu_panel: Panel = $Center/VBox/MenuPanel

func _ready() -> void:
	# 背景渐变：深沉暗色叠加灰紫调，营造沉郁氛围
	_bg.color = GameConstants.THEME_BG_DEEP
	_bg_layer.color = Color(
		GameConstants.THEME_ACCENT_PURPLE.r,
		GameConstants.THEME_ACCENT_PURPLE.g,
		GameConstants.THEME_ACCENT_PURPLE.b,
		0.08
	)

	# 标题：金色主色 + 阴影
	_title.text = "潮汐回响"
	UITheme.style_label(_title, GameConstants.THEME_ACCENT_GOLD, true)
	_title.add_theme_font_size_override("font_size", 44)

	# 副标题：暗青色
	_subtitle.text = "Roguelike × 银河恶魔城"
	UITheme.style_label(_subtitle, GameConstants.THEME_ACCENT_CYAN, false)
	_subtitle.add_theme_font_size_override("font_size", 14)

	# 提示文字
	_hint.text = "按 Enter 开始冒险"
	UITheme.style_label(_hint, GameConstants.THEME_TEXT_DIM, false)
	_hint.add_theme_font_size_override("font_size", 12)

	# 面板圆角化
	UITheme.style_panel(_menu_panel, GameConstants.THEME_PANEL_BG, GameConstants.THEME_PANEL_BORDER, 12)

	# 按钮统一样式
	UITheme.style_button(_start_button)
	UITheme.style_button(_continue_button)
	UITheme.style_button(_quit_button)

	# 信号连接
	_start_button.pressed.connect(_on_start)
	_continue_button.pressed.connect(_on_continue)
	_quit_button.pressed.connect(_on_quit)
	_continue_button.disabled = not SaveManager.has_save(0)

	# 入场动画：标题与面板错峰淡入
	_title.modulate.a = 0.0
	_subtitle.modulate.a = 0.0
	_menu_panel.modulate.a = 0.0
	_hint.modulate.a = 0.0

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_title, "modulate:a", 1.0, 0.4).set_delay(0.1)
	tween.tween_property(_title, "position:y", _title.position.y, 0.4).from(_title.position.y - 12)
	tween.tween_property(_subtitle, "modulate:a", 1.0, 0.4).set_delay(0.25)
	tween.tween_property(_menu_panel, "modulate:a", 1.0, 0.4).set_delay(0.35)
	tween.tween_property(_hint, "modulate:a", 1.0, 0.4).set_delay(0.55)

	# 聚焦到开始按钮，方便键盘操作
	_start_button.grab_focus()

func _on_start() -> void:
	var main = get_tree().current_scene
	if main.has_method("start_game"):
		main.start_game()

func _on_continue() -> void:
	if SaveManager.load_game(0):
		var main = get_tree().current_scene
		if main.has_method("start_game"):
			main.start_game()

func _on_quit() -> void:
	get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack") or event.is_action_pressed("jump"):
		if not _continue_button.has_focus() and not _quit_button.has_focus():
			_on_start()
