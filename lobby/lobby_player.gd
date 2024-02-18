extends TextureRect

var is_ready = false

func set_number(player_number):
    $NumberLabel.text = str(player_number)

func set_player_name(player_name):
    $NameLabel.text = player_name
    # Set other elements visible once a player name has been set
    $NumberLabel.visible  = true
    $ReadyTexture.visible = true

func get_player_name():
    return $NameLabel.text

func set_is_ready(new_ready):
    is_ready = new_ready
    if is_ready:
        $ReadyTexture.modulate = Color(1, 1, 1)
    else:
        $ReadyTexture.modulate = Color(137.0/255.0, 137.0/255.0, 137.0/255.0)

func get_is_ready():
    return is_ready

func set_is_me(is_me):
    $IsMeTexture.visible = is_me

func get_is_me():
    return $IsMeTexture.visible

func clear_player():
    set_player_name("")
    $NumberLabel.visible  = false
    $ReadyTexture.visible = false
    $IsMeTexture.visible = false
