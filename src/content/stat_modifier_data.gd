class_name StatModifierData
extends Resource

@export var stat: String = ""
@export var type: String = "flat"
@export var value: float = 0.0

func to_dict() -> Dictionary:
	return {"stat": stat, "type": type, "value": value}
