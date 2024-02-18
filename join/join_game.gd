extends Node

signal change_scene
signal do_join

var password_enabled = false

func _ready():
    connect('do_join', get_node('/root/Main/Networking')._on_do_join)

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
    print('back clicked from join')
    emit_signal('change_scene', 'title')

func _on_join_game_button_pressed():
    var stripped_ip = $IP_Parent/IP_LineEdit.text.rstrip(' ')
    var port = int($PortParent/PortLineEdit.text)
    var stripped_game_name = $GameNameParent/GameNameLineEdit.text.rstrip(' ')
    var stripped_password = $PasswordParent/PasswordLineEdit.text.rstrip(' ')
    var stripped_player_name = $PlayerNameParent/PlayerNameLineEdit.text.rstrip(' ')

    if (!stripped_ip.is_empty() \
            && (port >= 0) && (port <= 65535) \
            && !stripped_game_name.is_empty() \
            && !stripped_password.is_empty() \
            && !stripped_player_name.is_empty()):
        emit_signal('do_join',
                    stripped_ip,
                    port,
                    stripped_game_name,
                    stripped_password if password_enabled else '',
                    stripped_player_name)
    else:
        # TO-DO - show error message
        print('Bad join input')
