extends Node

var ships_path = "res://shipBuilding/ships/"
var ship_prefabs: Array[PackedScene]

@onready var button_parent: VBoxContainer = $VBoxContainer
@onready var save_manager: EditorSaveManager = $"../../../SaveManager"

func _ready() -> void:
	load_ships()
	$VBoxContainer/UpdateAll.pressed.connect(update_all)

func load_ship(index: int) -> void:
	save_manager.save_name.text = ship_prefabs[index].resource_path.get_file().get_basename()
	save_manager.load_tscn()

func load_ships() -> void:
	var dir = DirAccess.open(ships_path)
	if not dir: return
		
	for file_name in dir.get_files():
		var final_name = file_name.trim_suffix(".remap")
		if final_name.ends_with(".tscn") or final_name.ends_with(".scn"):
			var path = ships_path.path_join(final_name)
			var scene = load(path)
			ship_prefabs.append(scene)
			_create_button(final_name.get_basename(), ship_prefabs.size() - 1)

func _create_button(label: String, index: int) -> void:
	var button = Button.new()
	button.text = label
	button.pressed.connect(load_ship.bind(index))
	button_parent.add_child(button)

func get_ship_index(ship_instance: Ship) -> int:
	return ship_prefabs.find(load(ship_instance.scene_file_path))
	

# If there is a ship this touches you do not want it to edit, discard the changes
# before you commit to gh.
func update_all():
	for i in range(len(ship_prefabs)):
		save_manager.save_name.text = ship_prefabs[i].resource_path.get_file().get_basename()
		save_manager.load_tscn()
		await get_tree().process_frame
		save_manager.save_json()
		await get_tree().process_frame
		save_manager.load_json()
		await get_tree().process_frame
		save_manager.save_tscn()
