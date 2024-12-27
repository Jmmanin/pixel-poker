extends Node2D

var player_id_index_map = {}

func _ready():
    pass

func set_results(server_results):
    for index in server_results.size():
        get_node('ResultsFrame/PlayerResults' + str(index + 1) + '/PlayerName').text = server_results[index]['name']
        get_node('ResultsFrame/PlayerResults' + str(index + 1) + '/PlayerWinnings').text = str(server_results[index]['winnings'])
        get_node('ResultsFrame/PlayerResults' + str(index + 1) + '/PlayerBalance').text = str(server_results[index]['balance'])
        get_node('LobbyFrame/PlayerReady' + str(index + 1) + '/PlayerName').text = server_results[index]['name']
        get_node('LobbyFrame/PlayerReady' + str(index + 1) + '/ReadyTexture').visible = true

        player_id_index_map[server_results[index]['id']] = index

func _on_table_button_pressed():
    visible = false

func _on_continue_button_pressed():
    $ResultsFrame.visible = false
    $LobbyFrame.visible = true

func _on_results_button_pressed():
    $ResultsFrame.visible = true
    $LobbyFrame.visible = false

func _on_ready_button_pressed():
    pass # Replace with function body.
