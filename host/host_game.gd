extends Node

enum {PB_ANTE, PB_BLIND}

var password_enabled = false
var prebet = PB_BLIND

func _on_background_gui_input(event):
    # Release focus from all line edits if background is clicked
    if event is InputEventMouseButton and event.pressed:
        $IP_Parent/IP_LineEdit.release_focus()
        $PortParent/PortLineEdit.release_focus()
        $GameNameParent/GameNameLineEdit.release_focus()
        $PasswordParent/PasswordLineEdit.release_focus()
        $PlayerNameParent/PlayerNameLineEdit.release_focus()
        $StartingBalanceParent/StartingBalanceLineEdit.release_focus()
        $AnteParent/AnteLineEdit.release_focus()
        $BlindParent/BigBlindLineEdit.release_focus()
        $BlindParent/SmallBlindLineEdit.release_focus()
   
func _on_sign_timer_timeout():
    # "Blink" sign
    $Sign/SignMask1.visible = !$Sign/SignMask1.visible
    $Sign/SignMask2.visible = !$Sign/SignMask2.visible

func _on_ante_button_pressed():
    prebet = PB_ANTE
    $PreBetParent/AnteButton/AnteDisabledMask.visible   = false
    $PreBetParent/BlindButton/BlindDisabledMask.visible = true
    $AnteParent.visible  = true
    $BlindParent.visible = false

func _on_blind_button_pressed():
    prebet = PB_BLIND
    $PreBetParent/AnteButton/AnteDisabledMask.visible   = true
    $PreBetParent/BlindButton/BlindDisabledMask.visible = false
    $AnteParent.visible  = false
    $BlindParent.visible = true

func _on_password_line_edit_focus_entered():
    password_enabled = true
    $PasswordParent/PasswordBackground.modulate = Color(1, 1, 1)

func _on_password_line_edit_focus_exited():
    if $PasswordParent/PasswordLineEdit.text.is_empty():
        password_enabled = false
        $PasswordParent/PasswordBackground.modulate = Color(95.0/255.0, 95.0/255.0, 95.0/255.0)

func _on_back_button_pressed():
    get_tree().change_scene_to_file("res://title/title.tscn")

func _on_host_game_button_pressed():
    get_tree().change_scene_to_file("res://lobby/lobby.tscn")
