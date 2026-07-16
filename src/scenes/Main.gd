extends Node2D
## 主场景 - 游戏入口，管理场景切换

@onready var _scene_container: Node = $SceneContainer
@onready var _ui_layer: CanvasLayer = $UILayer
@onready var _hud: Control = $UILayer/HUD

var _current_scene: Node = null

func _ready() -> void:
    EventBus.world_switched.connect(_on_world_switched)
    EventBus.player_died.connect(_on_player_died)
    _show_main_menu()

func _show_main_menu() -> void:
    _clear_scene()
    var menu = preload("res://src/ui/MainMenu.tscn").instantiate()
    _scene_container.add_child(menu)
    _hud.visible = false

func start_game() -> void:
    _clear_scene()
    GameManager.start_new_game()
    _load_level("C1", "C1-1")
    _hud.visible = true

func _load_level(chapter_id: String, sub_level_id: String) -> void:
    _clear_scene()
    # TODO: 根据章节加载对应关卡场景
    var level_scene = preload("res://src/levels/shared/TestLevel.tscn").instantiate()
    _scene_container.add_child(level_scene)
    LevelManager.load_level(chapter_id, sub_level_id)

func _clear_scene() -> void:
    for child in _scene_container.get_children():
        child.queue_free()

func _on_world_switched(layer: int) -> void:
    # TODO: 双层世界切换视觉效果
    pass

func _on_player_died(cause: String) -> void:
    _clear_scene()
    var game_over = preload("res://src/ui/GameOverScreen.tscn").instantiate()
    _scene_container.add_child(game_over)
    _hud.visible = false

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("escape") and GameManager.get_current_state() == GameManager.GameState.PLAYING:
        GameManager.change_state(GameManager.GameState.PAUSED)
        var pause_menu = preload("res://src/ui/PauseMenu.tscn").instantiate()
        _ui_layer.add_child(pause_menu)
