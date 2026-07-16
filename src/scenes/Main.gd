extends Node2D
## 主场景 - 游戏入口，管理场景切换

const MutationSelectScene = preload("res://src/ui/MutationSelectScreen.tscn")
const BodyPartEquipScene = preload("res://src/ui/BodyPartEquipScreen.tscn")

@onready var _scene_container: Node = $SceneContainer
@onready var _ui_layer: CanvasLayer = $UILayer
@onready var _hud: Control = $UILayer/HUD

var _current_scene: Node = null
var _mutation_screen: Control = null
var _equip_screen: Control = null

func _ready() -> void:
    EventBus.world_switched.connect(_on_world_switched)
    EventBus.player_died.connect(_on_player_died)
    EventBus.request_mutation_select.connect(_on_request_mutation_select)
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

## 通关后弹出变异选择界面
func _on_request_mutation_select() -> void:
    if _mutation_screen != null:
        return
    get_tree().paused = true
    _mutation_screen = MutationSelectScene.instantiate()
    _ui_layer.add_child(_mutation_screen)
    _mutation_screen.show_selection()
    _mutation_screen.mutation_selected.connect(_on_mutation_selected)


## 变异选择完成 -> 恢复游戏并加载下一关
func _on_mutation_selected(mutation_id: String) -> void:
    EventBus.mutation_select_finished.emit(mutation_id)
    _mutation_screen = null
    # 立即恢复暂停, 让关闭动画和后续timer正常运行
    get_tree().paused = false
    # 等待关闭动画结束后加载下一关 (动画约0.18s)
    get_tree().create_timer(0.25).timeout.connect(func():
        if not LevelManager.load_next_sub_level():
            EventBus.show_notification.emit("章节完成!", 0)
    )

## 打开部件装备界面 (B键)
func _open_equip_screen() -> void:
    if _equip_screen != null or _mutation_screen != null:
        return
    if GameManager.get_current_state() != GameManager.GameState.PLAYING:
        return
    get_tree().paused = true
    _equip_screen = BodyPartEquipScene.instantiate()
    _ui_layer.add_child(_equip_screen)
    _equip_screen.open()
    _equip_screen.closed.connect(_on_equip_closed)

func _on_equip_closed() -> void:
    _equip_screen = null
    get_tree().paused = false

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("escape") and GameManager.get_current_state() == GameManager.GameState.PLAYING:
        GameManager.change_state(GameManager.GameState.PAUSED)
        var pause_menu = preload("res://src/ui/PauseMenu.tscn").instantiate()
        _ui_layer.add_child(pause_menu)
    # B键打开部件装备界面
    if event is InputEventKey and event.pressed and event.keycode == KEY_B:
        if GameManager.get_current_state() == GameManager.GameState.PLAYING:
            _open_equip_screen()
            get_viewport().set_input_as_handled()
