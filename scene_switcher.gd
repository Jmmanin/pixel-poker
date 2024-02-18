extends Node

var current_scene

func _ready():
    current_scene = load('res://title/title.tscn').instantiate()
    add_child(current_scene)
    current_scene.connect('change_scene', _on_change_scene)

func _on_change_scene(new_scene_name):
    var next_scene = null

    match new_scene_name:
        'title':
            next_scene = load('res://title/title.tscn').instantiate()
        'host':
            next_scene = load('res://host/host_game.tscn').instantiate()
        'join':
            next_scene = load('res://join/join_game.tscn').instantiate()
        'lobby':
            next_scene = load('res://lobby/lobby.tscn').instantiate()
        'table':
            next_scene = load('res://table/table.tscn').instantiate()
        _:
            #TO-DO - handle error
            return

    add_child(next_scene)
    next_scene.connect('change_scene', _on_change_scene)
    current_scene.queue_free()
    current_scene = next_scene
