extends Node

signal change_scene

func _on_sign_timer_timeout():
    # "Blink" sign
    $Sign/SignMask1.visible = !$Sign/SignMask1.visible
    $Sign/SignMask2.visible = !$Sign/SignMask2.visible

func _on_host_game_button_pressed():
    change_scene.emit('host')

func _on_join_game_button_pressed():
    change_scene.emit('join')

func _on_settings_button_pressed():
    print('settings clicked from title')

func _on_quit_button_pressed():
    get_tree().quit()
