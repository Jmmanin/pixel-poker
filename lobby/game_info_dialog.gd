extends Node2D

func set_game_info(game_info):#
    $DialogBoxFrame/StartingBalance/ValueLabel.text = '$' + str(game_info['starting_balance'])

    if game_info['prebet_type'] == PokerTypes.PrebetTypes.PB_ANTE:
        $DialogBoxFrame/PrebetType/ValueLabel.text = 'Ante'
        $DialogBoxFrame/PrebetAmount/ValueLabel.text = '$' + str(game_info['ante_amount'])
    else:
        $DialogBoxFrame/PrebetType/ValueLabel.text = 'Blind'
        $DialogBoxFrame/PrebetAmount/ValueLabel.text = '$' + str(game_info['big_blind_amount']) + '/$' + str(game_info['small_blind_amount'])

    $DialogBoxFrame/IP/ValueLabel.text = game_info['address']
    $DialogBoxFrame/Port/ValueLabel.text = str(game_info['port'])
