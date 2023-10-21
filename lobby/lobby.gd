extends Node

var im_readied = false
var lobby_players = Array()

# Called when the node enters the scene tree for the first time.
func _ready():
    $GameNameLabel.text = "Test Game"
    lobby_players = [$LobbyPlayer1, $LobbyPlayer2, $LobbyPlayer3, $LobbyPlayer4,\
                     $LobbyPlayer5, $LobbyPlayer6, $LobbyPlayer7, $LobbyPlayer8]
    for index in len(lobby_players):
        lobby_players[index].set_number(index+1)

func _on_sign_timer_timeout():
    # "Blink" sign
    $Sign/SignMask1.visible = !$Sign/SignMask1.visible
    $Sign/SignMask2.visible = !$Sign/SignMask2.visible

func _on_rules_button_pressed():
    print("rules")
    lobby_players[1].set_player_name("1234Jeremy")
    lobby_players[6].set_player_name("Jeremy1234")
    lobby_players[6].set_is_me(true)

func _on_back_button_pressed():
    get_tree().change_scene_to_file("res://title/title.tscn")

func _on_ready_button_pressed():
    $ReadyButton/ReadyDisabledMask.visible = im_readied
    im_readied = !im_readied
    lobby_players[6].set_is_ready(im_readied)
