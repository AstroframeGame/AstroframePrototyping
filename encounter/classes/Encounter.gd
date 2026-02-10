# Encounter.gd
extends Node2D

signal encounter_completed(rewards)

var encounter_data: Dictionary
var active_npcs: Array = []
var player: Node

func initialize(data: Dictionary):
	encounter_data = data
	if encounter_data.protocols && encounter_data.protocols.entities:
		spawn_npcs()

func spawn_npcs():
	for npc in encounter_data.protocols.entities:
		var npc_data = encounter_data.protocols.entities[npc]
		for i in range(npc_data.amount):
			var new_npc = create_npc(npc, npc_data)
			active_npcs.append(new_npc)
			add_child(new_npc)

func create_npc(name: String, data: Dictionary) -> Node:
	var npc_scene = load("res://encounter/%s/%s.tscn" % [data.type, name])
	var npc = npc_scene.instantiate()
	
	return npc

func _on_npc_destroyed(npc: Node):
	active_npcs.erase(npc)
	if active_npcs.is_empty():
		complete_encounter()

func _on_npc_exit(npc: Node):
	active_npcs.erase(npc)
	if active_npcs.is_empty():
		complete_encounter()

func complete_encounter():
	emit_signal("encounter_completed")
	queue_free()  # Clean up encounter
