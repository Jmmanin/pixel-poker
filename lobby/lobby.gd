extends Node

signal change_scene
signal send_new_ready

var im_readied = false
var my_index = 0

var lobby_players = Array()
var lobby_player_map = {}
var next_lobby_index = 0

# Called when the node enters the scene tree for the first time.
func _ready():
    lobby_players = [$LobbyPlayer1, $LobbyPlayer2, $LobbyPlayer3, $LobbyPlayer4,\
                     $LobbyPlayer5, $LobbyPlayer6, $LobbyPlayer7, $LobbyPlayer8]
    for index in len(lobby_players):
        lobby_players[index].set_number(index+1)

    get_node('/root/Main/Networking').connect('player_connected', _on_player_connected)
    get_node('/root/Main/Networking').connect('set_game_info', _on_set_game_info)
    get_node('/root/Main/Networking').connect('update_player_ready', _on_update_player_ready)
    get_node('/root/Main/Networking').connect('player_disconnected', _on_player_disconnected)

    connect('send_new_ready', get_node('/root/Main/Networking')._on_update_ready)

func _on_sign_timer_timeout():
    # 'Blink' sign
    $Sign/SignMask1.visible = !$Sign/SignMask1.visible
    $Sign/SignMask2.visible = !$Sign/SignMask2.visible

func _on_rules_button_pressed():
    print('rules')

func _on_back_button_pressed():
    multiplayer.multiplayer_peer.close()
    emit_signal('change_scene', 'title')

func _on_ready_button_pressed():
    $ReadyButton/ReadyDisabledMask.visible = im_readied
    im_readied = !im_readied
    lobby_players[my_index].set_is_ready(im_readied)
    emit_signal('send_new_ready', im_readied)

func _on_player_connected(new_players):
    for player_id in new_players:
        lobby_player_map[player_id] = next_lobby_index

        lobby_players[next_lobby_index].set_player_name(new_players[player_id]['name'])
        lobby_players[next_lobby_index].set_is_ready(new_players[player_id]['ready'])

        if player_id == multiplayer.get_unique_id():
            lobby_players[next_lobby_index].set_is_me(true)
            my_index = next_lobby_index

        next_lobby_index += 1

func _on_set_game_info(game_info):
    $GameNameLabel.text = game_info['name']

func _on_update_player_ready(player_id, new_ready):
    var index = lobby_player_map[player_id]
    lobby_players[index].set_is_ready(new_ready)

func _on_player_disconnected(player_id):
    var leaving_index = lobby_player_map[player_id]

    lobby_player_map.erase(player_id)

    for index in range(leaving_index, next_lobby_index):
        lobby_players[index].clear_player()
        if index < (next_lobby_index-1):
            lobby_players[index].set_player_name(lobby_players[index+1].get_player_name())
            lobby_players[index].set_is_ready(lobby_players[index+1].get_is_ready())
            lobby_players[index].set_is_me(lobby_players[index+1].get_is_me())

            # find_key should never return null as all indicies before
            # `next_lobby_index` should be occupied
            lobby_player_map[lobby_player_map.find_key(index+1)] = index

    next_lobby_index -= 1
