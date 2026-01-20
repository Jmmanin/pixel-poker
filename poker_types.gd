extends Node

enum PrebetTypes {PB_ANTE, PB_BLIND}

enum BlindButtons {BB_NONE, BB_DEALER, BB_SMALL_BLIND, BB_BIG_BLIND}

enum ButtonActions {BA_NONE, BA_CHECK, BA_CALL, BA_BET, BA_RAISE, BA_CONFIRM, BA_CANCEL, BA_ALL_IN, BA_FOLD, BA_SETTINGS, BA_RESULTS}

enum GamePhases {GP_PRE_FLOP, GP_FLOP, GP_TURN, GP_RIVER, GP_END}

class GameInfo:
    var address : String
    var port : int
    var game_name : String
    var game_pw : String
    var starting_balance : int
    var prebet_type : int # PokerTypes.PrebetTypes
    var ante_amount : int
    var small_blind_amount : int
    var big_blind_amount : int

    func _init(p_address : String,
           p_port : int,
           p_game_name : String,
           p_game_pw : String,
           p_starting_balance : int,
           p_prebet_type : int,
           p_ante_amount : int,
           p_small_blind_amount : int,
           p_big_blind_amount : int) -> void:
        address = p_address
        port = p_port
        game_name = p_game_name
        game_pw = p_game_pw
        starting_balance = p_starting_balance
        prebet_type = p_prebet_type
        ante_amount = p_ante_amount
        small_blind_amount = p_small_blind_amount
        big_blind_amount = p_big_blind_amount

    func to_dict() -> Dictionary: # Poor man's serialization
        var game_info_as_dict = {}
        game_info_as_dict['address'] = address
        game_info_as_dict['port'] = port
        game_info_as_dict['game_name'] = game_name
        game_info_as_dict['game_pw'] = game_pw
        game_info_as_dict['starting_balance'] = starting_balance
        game_info_as_dict['prebet_type'] = prebet_type
        game_info_as_dict['ante_amount'] = ante_amount
        game_info_as_dict['small_blind_amount'] = small_blind_amount
        game_info_as_dict['big_blind_amount'] = big_blind_amount
        return game_info_as_dict
