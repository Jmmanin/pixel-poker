extends Node

var current_scene

func _ready():
    current_scene = load('res://title/title.tscn').instantiate()
    current_scene.name = 'Title'
    add_child(current_scene)
    current_scene.connect('change_scene', _on_change_scene)

func _on_change_scene(new_scene_name):
    var next_scene = null

    current_scene.name = 'Old' + current_scene.name

    match new_scene_name:
        'title':
            next_scene = load('res://title/title.tscn').instantiate()
            next_scene.name = 'Title'
        'host':
            next_scene = load('res://host/host_game.tscn').instantiate()
            next_scene.name = 'Host'
        'join':
            next_scene = load('res://join/join_game.tscn').instantiate()
            next_scene.name = 'Join'
        'lobby':
            next_scene = load('res://lobby/lobby.tscn').instantiate()
            next_scene.name = 'Lobby'
        'table':
            next_scene = load('res://table/table.tscn').instantiate()
            next_scene.name = 'Table'
        _:
            OS.alert('Attempt made to switch to an unknown scene.\nGame will now exit.', 'Fatal Error')
            get_tree().quit(1)
            return

    add_child(next_scene)
    next_scene.connect('change_scene', _on_change_scene)
    current_scene.queue_free()
    current_scene = next_scene
