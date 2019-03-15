import re
from _vcmp import functions as func

TYPE_UID = 0
TYPE_UID2 = 1
TYPE_FULLSTR = 3
TYPE_SUBSTR = 4
TYPE_REGEX = 5

ban_list = []

def load_ban_list(l):
    global ban_list
    for k, v in l.items():
        if k == 'uid':
            for i in v:
                ban_list.append((i, TYPE_UID))
        elif k == 'uid2':
            for i in v:
                ban_list.append((i, TYPE_UID2))
        elif k == 'name':
            for i in v:
                if isinstance(i, str):
                    ban_list.append((i, TYPE_FULLSTR))
                elif isinstance(i, list):
                    ban_list.append((i[0], i[1] + TYPE_FULLSTR))

def check_ban_list(player_id):
    uid = func.get_player_uid(player_id)
    uid2 = func.get_player_uid2(player_id)
    name = func.get_player_name(player_id)
    for n, t in ban_list:
        if t == TYPE_UID:
            if uid == n:
                return True
        elif t == TYPE_UID2:
            if uid2 == n:
                return True
        elif t == TYPE_FULLSTR:
            if name == n:
                return True
        elif t == TYPE_SUBSTR:
            if name.find(n) != -1:
                return True
        elif t == TYPE_REGEX:
            if not re.search(n, name):
                return True
