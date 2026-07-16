extends Node2D

@onready var _player: CharacterBody2D = $Player
@onready var _tile_map: TileMapLayer = $TileMapLayer

func _ready() -> void:
    # 设置区域污染倍率
    SANManager.set_pollution_multiplier(1.0)
    SANManager.set_safe_zone(false)

    # 标记关卡已加载
    EventBus.show_notification.emit("C1-1 普罗维登斯码头", 0)

    # 连接玩家攻击信号
    _player.get_node("AttackArea").body_entered.connect(_on_attack_hit)

func _on_attack_hit(body: Node) -> void:
    if body.is_in_group("enemies"):
        # TODO: 敌人受伤逻辑
        body.queue_free()
