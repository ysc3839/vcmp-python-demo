from vcmp.player import Player
from vcmp.utils import MAX_PLAYERS
from typing import List

players = [None] * MAX_PLAYERS

class _MyPlayer(Player):
    def __init__(self, player_id):
        super().__init__(player_id)

def MyPlayer(player_id) -> _MyPlayer:
    global players
    if not players[player_id]:
        players[player_id] = _MyPlayer(player_id)
    return players[player_id]
