extends Node

# Hosting Type
enum {HT_JOINING, HT_HOSTING, HT_SELF_HOSTING}

# Pre-bet options
enum {PB_ANTE, PB_BLIND}

# Table button actions
enum {TB_NONE,
      TB_CALL,
      TB_RAISE,
      TB_FOLD,
      TB_SETTINGS}

# Blind button options
enum {BB_NONE, BB_DEALER, BB_SMALL_BLIND, BB_BIG_BLIND}

# Suites
enum {CS_SPADES, CS_CLUBS, CS_DIAMONDS, CS_HEARTS}
