extends TextureButton

var current_action = PokerTypes.ButtonActions.BA_NONE

func set_action(new_action):
    current_action = new_action
    match current_action:
        PokerTypes.ButtonActions.BA_NONE:
            $ButtonLabel.text = ''
        PokerTypes.ButtonActions.BA_CHECK:
            $ButtonLabel.text = 'Check'
        PokerTypes.ButtonActions.BA_CALL:
            $ButtonLabel.text = 'Call'
        PokerTypes.ButtonActions.BA_BET:
            $ButtonLabel.text = 'Bet'
        PokerTypes.ButtonActions.BA_RAISE:
            $ButtonLabel.text = 'Raise'
        PokerTypes.ButtonActions.BA_CONFIRM:
            $ButtonLabel.text = 'Confirm'
        PokerTypes.ButtonActions.BA_CANCEL:
            $ButtonLabel.text = 'Cancel'
        PokerTypes.ButtonActions.BA_ALL_IN:
            $ButtonLabel.text = 'All-In'
        PokerTypes.ButtonActions.BA_FOLD:
            $ButtonLabel.text = 'Fold'
        PokerTypes.ButtonActions.BA_SETTINGS:
            $ButtonLabel.text = 'Settings'
        PokerTypes.ButtonActions.BA_RESULTS:
            $ButtonLabel.text = 'Results'
        _:
            OS.alert('Attempt made to set table button to an unknown action.\nGame will now exit.', 'Fatal Error')
            get_tree().quit(1)
            return

    if current_action == PokerTypes.ButtonActions.BA_NONE:
        $DisabledMask.visible = true
        self.disabled = true
    else:
        $DisabledMask.visible = false
        self.disabled = false
