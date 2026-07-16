extends Node

# SAN 系统
signal san_changed(current_san: float, max_san: float)
signal san_stage_changed(stage: SANManager.SanStage)
signal san_temporary_loss(amount: float, source: String)
signal san_permanent_loss(amount: float, source: String)
signal madness_triggered(madness_id: String)

# 道具系统
signal item_picked_up(item_id: String, count: int)
signal item_used(item_id: String)
signal item_removed(item_id: String, count: int)
signal active_item_used(slot_index: int)
signal set_bonus_activated(set_id: String)
signal set_bonus_deactivated(set_id: String)

# 部件系统
signal body_part_equipped(part_id: String, slot: int)
signal body_part_unequipped(slot: int)
signal body_part_overloaded(is_overloaded: bool)
signal ability_unlocked(ability: String)

# 流派系统
signal faction_level_changed(faction: int, level: int)
signal mutation_selected(mutation_id: String)

# 关卡系统
signal level_loaded(chapter_id: String, sub_level_id: String)
signal level_completed(chapter_id: String, sub_level_id: String)
signal boss_encountered(boss_id: String)
signal boss_defeated(boss_id: String)

# 双层世界
signal world_switched(layer: int)  # 0=reality, 1=dreamlands
signal dream_death_occurred()

# 轮回系统
signal player_died(cause: String)
signal roguelike_reset_started()
signal roguelike_reset_completed()
signal meta_progress_updated(key: String, value)

# UI
signal show_notification(text: String, type: int)
signal show_dialog(text: String, speaker: String)
signal ui_state_changed(state: String)

# 邪神交易
signal elder_god_trade_offered(god_id: String, offer: Dictionary)
signal elder_god_trade_accepted(god_id: String, cost: Dictionary)
