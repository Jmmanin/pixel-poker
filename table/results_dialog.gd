extends Node2D

signal send_new_ready

var player_id_index_map = {}
var im_readied = false

var countdown_remaining = 10

func _ready():
    get_node('/root/Main/Networking').connect('update_player_ready', _on_update_player_ready)
    get_node('/root/Main/Networking').connect('do_start_lobby_countdown', _on_do_start_lobby_countdown)
    get_node('/root/Main/Networking').connect('do_stop_lobby_countdown', _on_do_stop_lobby_countdown)

    connect('send_new_ready', get_node('/root/Main/Networking')._on_update_ready)

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
    update_my_ready(!im_readied)

func update_my_ready(new_ready):
    im_readied = new_ready

    if im_readied:
        get_node('LobbyFrame/PlayerReady' +\
                 str(player_id_index_map[multiplayer.get_unique_id()] + 1) +\
                 '/ReadyTexture').modulate = Color(1, 1, 1)
        $LobbyFrame/ReadyButton/ButtonLabel.text = 'Unready'
    else:
        get_node('LobbyFrame/PlayerReady' +\
                 str(player_id_index_map[multiplayer.get_unique_id()] + 1) +\
                 '/ReadyTexture').modulate = Color(137.0/255.0, 137.0/255.0, 137.0/255.0)
        $LobbyFrame/ReadyButton/ButtonLabel.text = 'Ready'

    emit_signal('send_new_ready', im_readied)

func _on_update_player_ready(player_id, new_ready):
    if new_ready:
        get_node('LobbyFrame/PlayerReady' +\
                str(player_id_index_map[player_id] + 1) +\
                '/ReadyTexture').modulate = Color(1, 1, 1)
    else:
        get_node('LobbyFrame/PlayerReady' +\
                 str(player_id_index_map[player_id] + 1) +\
                 '/ReadyTexture').modulate = Color(137.0/255.0, 137.0/255.0, 137.0/255.0)

func _on_do_start_lobby_countdown():
    visible = true # Force self visible so countdown can be seen

    var dialog = load('res://dialog_box.tscn').instantiate()
    dialog.name = 'CountdownDialog'
    dialog.set_title('Hand Starting')
    dialog.set_message('Next hand starting in ' + str(countdown_remaining) + ' seconds.')
    dialog.set_single_button_text('Unready')
    dialog.get_node('DialogBoxFrame/CenterButton').pressed.connect(_on_countdown_dialog_button_pressed)

    var countdown_timer = Timer.new()
    countdown_timer.autostart = true
    countdown_timer.timeout.connect(_on_countdown_timer_timeout)

    dialog.add_child(countdown_timer)
    add_child(dialog)

func _on_countdown_timer_timeout():
    if countdown_remaining > 0:
        countdown_remaining -= 1
        get_node('CountdownDialog').set_message('Next hand starting in ' + str(countdown_remaining) + (' seconds.' if (countdown_remaining > 1) else ' second.'))

func _on_countdown_dialog_button_pressed():
    update_my_ready(false)

func _on_do_stop_lobby_countdown():
    var dialog = get_node('CountdownDialog')
    if dialog:
        dialog.queue_free()

    countdown_remaining = 10
