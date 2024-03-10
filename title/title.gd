extends Node

signal change_scene

func _on_sign_timer_timeout():
    # "Blink" sign
    $Sign/SignMask1.visible = !$Sign/SignMask1.visible
    $Sign/SignMask2.visible = !$Sign/SignMask2.visible

func _on_host_game_button_pressed():
    emit_signal("change_scene", "host")

func _on_join_game_button_pressed():
    emit_signal("change_scene", "join")

func _on_settings_button_pressed():
    print("settings clicked from title")
    #get_tree().change_scene_to_file("res://table/table.tscn")

func _on_quit_button_pressed():
    get_tree().quit()
