extends TextureRect

func set_number(player_number):
    $NumberLabel.text = str(player_number)

func set_player_name(player_name):
    $NameLabel.text = player_name
    # Set other elements visible once a player name has been set
    $NumberLabel.visible  = true
    $ReadyTexture.visible = true

func set_is_ready(new_ready):
    if new_ready:
        $ReadyTexture.modulate = Color(1, 1, 1)
    else:
        $ReadyTexture.modulate = Color(137.0/255.0, 137.0/255.0, 137.0/255.0)

func set_is_me(is_me):
    $IsMeTexture.visible = is_me

func clear_player():
    set_player_name("")
    $NumberLabel.visible  = false
    $ReadyTexture.visible = false
