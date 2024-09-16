extends Node

signal change_scene
signal init_self_host

var self_host = true
var password_enabled = false
var prebet = PokerTypes.PrebetTypes.PB_BLIND

var my_ip = ''

func _ready():
    connect('init_self_host', get_node('/root/Main/Networking')._on_init_self_host)

    # Get my public IP address for use if self-hosting
    var http = HTTPRequest.new()
    add_child(http)
    http.request_completed.connect(_http_request_completed)
    http.request('http://api.ipify.org/')
    await(http.request_completed)
    http.queue_free()

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
    # 'Blink' sign
    $Sign/SignMask1.visible = !$Sign/SignMask1.visible
    $Sign/SignMask2.visible = !$Sign/SignMask2.visible

func _on_ip_line_edit_focus_entered():
    if self_host:
        $IP_Parent/IP_LineEdit.clear()
    self_host = false
    $IP_Parent/IP_Background.modulate = Color(1, 1, 1)

func _on_ip_line_edit_focus_exited():
    if $IP_Parent/IP_LineEdit.text.is_empty():
        self_host = true
        $IP_Parent/IP_Background.modulate = Color(95.0/255.0, 95.0/255.0, 95.0/255.0)
        $IP_Parent/IP_LineEdit.text = 'Self-Host'

func _on_ante_button_pressed():
    prebet = PokerTypes.PrebetTypes.PB_ANTE
    $IP_Parent/IP_LineEdit.focus_previous = $AnteParent/AnteLineEdit.get_path()
    $StartingBalanceParent/StartingBalanceLineEdit.focus_next = $AnteParent/AnteLineEdit.get_path()
    $PreBetParent/AnteButton/AnteDisabledMask.visible   = false
    $PreBetParent/BlindButton/BlindDisabledMask.visible = true
    $AnteParent.visible  = true
    $BlindParent.visible = false

func _on_blind_button_pressed():
    prebet = PokerTypes.PrebetTypes.PB_BLIND
    $IP_Parent/IP_LineEdit.focus_previous = $BlindParent/BigBlindLineEdit.get_path()
    $StartingBalanceParent/StartingBalanceLineEdit.focus_next = $BlindParent/SmallBlindLineEdit.get_path()
    $PreBetParent/AnteButton/AnteDisabledMask.visible   = true
    $PreBetParent/BlindButton/BlindDisabledMask.visible = false
    $AnteParent.visible  = false
    $BlindParent.visible = true

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

func _on_host_game_button_pressed():
    var stripped_ip = $IP_Parent/IP_LineEdit.text.rstrip(' ')
    var port = int($PortParent/PortLineEdit.text)
    var stripped_game_name = $GameNameParent/GameNameLineEdit.text.rstrip(' ')
    var stripped_password = $PasswordParent/PasswordLineEdit.text.rstrip(' ')
    var starting_balance = int($StartingBalanceParent/StartingBalanceLineEdit.text)
    var ante = int($AnteParent/AnteLineEdit.text)
    var small_blind = int($BlindParent/SmallBlindLineEdit.text)
    var big_blind = int($BlindParent/BigBlindLineEdit.text)
    var stripped_player_name = $PlayerNameParent/PlayerNameLineEdit.text.rstrip(' ')

    var prebet_valid = false
    if prebet == PokerTypes.PrebetTypes.PB_ANTE:
        prebet_valid = (starting_balance > 0) \
                       && (ante >= 0) \
                       && (starting_balance >= ante)
    else:
        prebet_valid = (starting_balance > 0) \
                       && (small_blind > 0) \
                       && (big_blind > 0) \
                       && (big_blind > small_blind) \
                       && (starting_balance > big_blind)

    if (!stripped_ip.is_empty() \
            && (port >= 0) && (port <= 65535) \
            && !stripped_game_name.is_empty() \
            && !stripped_password.is_empty() \
            && prebet_valid \
            && !stripped_player_name.is_empty()):
        if self_host:
            var multiplayer_peer = ENetMultiplayerPeer.new()
            var error = multiplayer_peer.create_server(port)

            if error:
                var dialog = load('res://dialog_box.tscn').instantiate()
                dialog.set_title('Error')
                dialog.set_message('Failed to create server with error code ' + str(error) + '.')
                dialog.set_single_button_text('Dismiss')
                dialog.get_node('DialogBoxFrame/CenterButton').pressed.connect(func(): dialog.queue_free())
                add_child(dialog)
            else:
                multiplayer.multiplayer_peer = multiplayer_peer

                var game_info = PokerTypes.GameInfo.new(stripped_ip if not self_host else my_ip,
                                                        port,
                                                        stripped_game_name,
                                                        stripped_password if password_enabled else '',
                                                        starting_balance,
                                                        prebet,
                                                        ante,
                                                        small_blind,
                                                        big_blind)

                emit_signal('init_self_host', game_info, stripped_player_name)
        else:
            # TO-DO - implement hosting games by connecting to separate server application
            var dialog = load('res://dialog_box.tscn').instantiate()
            dialog.set_title('Unsupported')
            dialog.set_message('Only self-hosting is supported currently.')
            dialog.set_single_button_text('Dismiss')
            dialog.get_node('DialogBoxFrame/CenterButton').pressed.connect(func(): dialog.queue_free())
            add_child(dialog)
    else:
        var dialog = load('res://dialog_box.tscn').instantiate()
        dialog.set_title('Error')
        dialog.set_message('Invalid input provided.\nCheck input\nand try again.')
        dialog.set_single_button_text('Dismiss')
        dialog.get_node('DialogBoxFrame/CenterButton').pressed.connect(func(): dialog.queue_free())
        add_child(dialog)

func _http_request_completed(_result, _response_code, _headers, body):
    my_ip = body.get_string_from_utf8()
