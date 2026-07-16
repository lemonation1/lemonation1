class_name Dice
extends RefCounted
## 骰子工具 - 解析 "1d6" "2d4" "1d100" 等表达式

static func roll(expression: String) -> int:
	## 解析并投掷骰子表达式，如 "1d6" 返回 1-6 的随机值
	expression = expression.strip_edges().to_lower()
	if expression.is_valid_int():
		return expression.to_int()

	if "d" in expression:
		var parts = expression.split("d")
		if parts.size() == 2 and parts[0].is_valid_int() and parts[1].is_valid_int():
			var count = parts[0].to_int()
			var sides = parts[1].to_int()
			var total = 0
			for i in count:
				total += randi_range(1, sides)
			return total

	if "/" in expression:
		# "0/1" 格式表示 0 或 1
		var parts = expression.split("/")
		if parts.size() == 2 and parts[0].is_valid_int() and parts[1].is_valid_int():
			return parts[0].to_int() if randf() < 0.5 else parts[1].to_int()

	return 0

static func roll_float(expression: String) -> float:
	return float(roll(expression))

static func roll_san_loss(expression: String) -> float:
	## 专门用于 SAN 损失的骰子投掷
	return float(roll(expression))
