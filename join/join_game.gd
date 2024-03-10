extends Node

signal change_scene
signal do_join_request

var password_enabled = false

var stripped_game_name = ''
var stripped_password = ''
var stripped_player_name = ''

var joining_period_count = 0
var suppress_connected_fail = false

func _ready():
    multiplayer.connected_to_server.connect(_on_connected_ok)
    multiplayer.connection_failed.connect(_on_connected_fail)

    connect('do_join_request', get_node('/root/Main/Networking')._do_join_request)

func _on_background_gui_input(event):
    # Release focus from all line edits if background is clicked
    if event is InputEventMouseButton and event.pressed:
        $IP_Parent/IP_LineEdit.release_focus()
        $PortParent/PortLineEdit.release_focus()
        $GameNameParent/GameNameLineEdit.release_focus()
        $PasswordParent/PasswordLineEdit.release_focus()
        $PlayerNameParent/PlayerNameLineEdit.release_focus()

func _on_sign_timer_timeout():
    # 'Blink' sign
    $Sign/SignMask1.visible = !$Sign/SignMask1.visible
    $Sign/SignMask2.visible = !$Sign/SignMask2.visible

func _on_password_line_edit_focus_entered():
    if not password_enabled:
        $PasswordParent/PasswordLineEdit.clear()
    password_enabled = true
    $PasswordParent/PasswordBackground.modulate = Color(1, 1, 1)

func _on_password_line_edit_focus_exited():
    if $PasswordParent/PasswordLineEdit.text.is_empty():
        password_enabled = false
        $PasswordParent/PasswordBackground.modulate = Color(95.0/255.0, 95.0/255.0, 95.0/255.0)
        $PasswordParent/PasswordLineEdit.text = 'No Password'

func _on_back_button_pressed():
    emit_signal('change_scene', 'title')

func _on_join_game_button_pressed():
    var stripped_ip = $IP_Parent/IP_LineEdit.text.rstrip(' ')
    var port = int($PortParent/PortLineEdit.text)

    stripped_game_name = $GameNameParent/GameNameLineEdit.text.rstrip(' ')
    stripped_password = $PasswordParent/PasswordLineEdit.text.rstrip(' ')
    stripped_player_name = $PlayerNameParent/PlayerNameLineEdit.text.rstrip(' ')

    if (!stripped_ip.is_empty() \
            && (port >= 0) && (port <= 65535) \
            && !stripped_game_name.is_empty() \
            && !stripped_password.is_empty() \
            && !stripped_player_name.is_empty()):
        var multiplayer_peer = ENetMultiplayerPeer.new()
        # TO-DO - investigate set_timeout
        #multiplayer_peer.get_peer(1).set_timeout(0,0,3000)#get_unique_id()
        var error = multiplayer_peer.create_client(stripped_ip, port)

        if error:
            var dialog = load('res://dialog_box.tscn').instantiate()
            dialog.set_title('Error')
            dialog.set_message('Failed to create client with error code ' + str(error) + '.')
            dialog.set_single_button_text('Dismiss')
            dialog.get_node('DialogBoxFrame/CenterButton').pressed.connect(func(): dialog.queue_free())
            add_child(dialog)
        else:
            multiplayer.multiplayer_peer = multiplayer_peer

            suppress_connected_fail = false
            joining_period_count = 0

            var dialog = load('res://dialog_box.tscn').instantiate()
            dialog.name = 'JoiningDialog'
            dialog.set_message('Joining game')
            dialog.set_single_button_text('Cancel')
            dialog.get_node('DialogBoxFrame/CenterButton').pressed.connect(_on_cancel_join)

            var dialog_timer = Timer.new()
            dialog_timer.autostart = true
            dialog_timer.wait_time = 0.5
            dialog_timer.timeout.connect(_on_join_dialog_timer_timeout)

            dialog.add_child(dialog_timer)
            add_child(dialog)
    else:
        var dialog = load('res://dialog_box.tscn').instantiate()
        dialog.set_title('Error')
        dialog.set_message('Invalid input provided.\nCheck input\nand try again.')
        dialog.set_single_button_text('Dismiss')
        dialog.get_node('DialogBoxFrame/CenterButton').pressed.connect(func(): dialog.queue_free())
        add_child(dialog)

func _on_cancel_join():
    get_node('JoiningDialog').queue_free()
    suppress_connected_fail = true
    multiplayer.multiplayer_peer.close()

func _on_join_dialog_timer_timeout():
    joining_period_count = (joining_period_count + 1) % 4
    get_node('JoiningDialog').set_message('Joining game' + '.'.repeat(joining_period_count))

func _on_connected_ok():
    do_join_request.emit(stripped_game_name,
                         stripped_password if password_enabled else '',
                         stripped_player_name)

func _on_connected_fail():
    if not suppress_connected_fail:
        get_node('JoiningDialog').queue_free()

        var dialog = load('res://dialog_box.tscn').instantiate()
        dialog.name = 'ConnectTimeoutDialog'
        dialog.set_title('Error')
        dialog.set_message('Connection attempt timed out.')
        dialog.set_single_button_text('Dismiss')
        dialog.get_node('DialogBoxFrame/CenterButton').pressed.connect(_on_timeout_dialog_button_pressed)
        add_child(dialog)

func _on_timeout_dialog_button_pressed():
    multiplayer.multiplayer_peer.close()
    get_node('ConnectTimeoutDialog').queue_free()
