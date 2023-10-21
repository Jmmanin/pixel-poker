extends Node

var password_enabled = false

func _on_background_gui_input(event):
    # Release focus from all line edits if background is clicked
    if event is InputEventMouseButton and event.pressed:
        $IP_Parent/IP_LineEdit.release_focus()
        $PortParent/PortLineEdit.release_focus()
        $GameNameParent/GameNameLineEdit.release_focus()
        $PasswordParent/PasswordLineEdit.release_focus()
        $PlayerNameParent/PlayerNameLineEdit.release_focus()

func _on_sign_timer_timeout():
    # "Blink" sign
    $Sign/SignMask1.visible = !$Sign/SignMask1.visible
    $Sign/SignMask2.visible = !$Sign/SignMask2.visible

func _on_password_line_edit_focus_entered():
    password_enabled = true
    $PasswordParent/PasswordBackground.modulate = Color(1, 1, 1)

func _on_password_line_edit_focus_exited():
    if $PasswordParent/PasswordLineEdit.text.is_empty():
        password_enabled = false
        $PasswordParent/PasswordBackground.modulate = Color(95.0/255.0, 95.0/255.0, 95.0/255.0)

func _on_back_button_pressed():
    get_tree().change_scene_to_file("res://title/title.tscn")

func _on_join_game_button_pressed():
    get_tree().change_scene_to_file("res://lobby/lobby.tscn")
