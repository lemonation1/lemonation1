extends Node

enum GameState { MAIN_MENU, PLAYING, PAUSED, GAME_OVER, VICTORY, LOADING }

var _current_state: GameState = GameState.MAIN_MENU
var _hit_stop_timer: float = 0.0

func _ready() -> void:
    EventBus.player_died.connect(_on_player_died)

func _physics_process(delta: float) -> void:
    if _hit_stop_timer > 0.0:
        _hit_stop_timer -= delta

## 触发全局命中停顿 - 冻结所有物理实体
func trigger_hit_stop(duration: float) -> void:
    _hit_stop_timer = duration

func is_in_hit_stop() -> bool:
    return _hit_stop_timer > 0.0

func change_state(new_state: GameState) -> void:
    if new_state == _current_state:
        return
    _current_state = new_state
    match new_state:
        GameState.PLAYING:
            get_tree().paused = false
        GameState.PAUSED:
            get_tree().paused = true
        GameState.GAME_OVER:
            _handle_game_over()
        GameState.VICTORY:
            _handle_victory()

func get_current_state() -> GameState:
    return _current_state

func start_new_game() -> void:
    MetaProgressManager.start_new_run()
    change_state(GameState.PLAYING)
    LevelManager.load_level("C1", "C1-1")

func _on_player_died(cause: String) -> void:
    change_state(GameState.GAME_OVER)

func _handle_game_over() -> void:
    pass

func _handle_victory() -> void:
    pass

func save_game(slot: int = 0) -> void:
    SaveManager.save_game(slot)

func load_game(slot: int = 0) -> void:
    SaveManager.load_game(slot)
