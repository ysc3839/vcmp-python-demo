import yaml
from math import floor

from _vcmp import functions as func
from vcmp.enum import ServerOption

from .ban import load_ban_list
from .teleport import load_teleport

def _load_server_settings(s):
    for k, v in s.items():
        if k == 'server_name':
            func.set_server_name(v)
        elif k == 'max_players':
            func.set_max_players(v)
        elif k == 'server_password':
            func.set_server_password(v)
        elif k == 'game_mode_text':
            func.set_game_mode_text(v)

def _load_server_option(server_option):
    for k, v in server_option.items():
        func.set_server_option(ServerOption[k].value, v)

def _load_game_env(g):
    for k, v in g.items():
        if k == 'server_option':
            _load_server_option(v)
        elif k == 'world_bounds':
            func.set_world_bounds(*v)
        elif k == 'wasted_settings':
            func.set_wasted_settings(*v)
        elif k == 'time_rate':
            func.set_time_rate(v)
        elif k == 'hour':
            func.set_hour(v)
        elif k == 'minute':
            func.set_minute(v)
        elif k == 'weather':
            func.set_weather(v)
        elif k == 'gravity':
            func.set_gravity(v)
        elif k == 'game_speed':
            func.set_game_speed(v)
        elif k == 'water_level':
            func.set_water_level(v)
        elif k == 'max_flight_altitude':
            func.set_maximum_flight_altitude(v)
        elif k == 'kill_command_delay':
            func.set_kill_command_delay(v)
        elif k == 'vehicles_forced_respawn_height':
            func.set_vehicles_forced_respawn_height(v)
        elif k == 'fall_timer': # Unavailable on 04rel004
            try:
                func.set_fall_timer(v)
            except NotImplementedError:
                pass

def _load_hide_map_object(h):
    for o in h:
        if len(o) == 4:
            for i in range(1, 4):
                if isinstance(o[i], float):
                    o[i] = int(floor(o[i] * 10.0) + 0.5)
            func.hide_map_object(*o)

def load_settings():
    with open('settings.yaml', 'r') as f:
        for k, v in yaml.load(f, Loader=yaml.Loader).items():
            if not v:
                continue
            if k == 'server_settings':
                _load_server_settings(v)
            elif k == 'game_env':
                _load_game_env(v)
            elif k == 'hide_map_object':
                _load_hide_map_object(v)
            elif k == 'weapon_data_value':
                for i in v:
                    func.set_weapon_data_value(*i)
            elif k == 'coord_blip':
                for i in v:
                    func.create_coord_blip(*i)
            elif k == 'radio_stream':
                for i in v:
                    func.add_radio_stream(*i)
            elif k == 'player_class':
                for i in v:
                    func.add_player_class(*i)
            elif k == 'spawn':
                for i, j in v.items():
                    if i == 'pos':
                        func.set_spawn_player_position(*j)
                    elif i == 'camera_pos':
                        func.set_camera_position(*j)
                    elif i == 'camera_look_at':
                        func.set_spawn_camera_look_at(*j)
            elif k == 'ban':
                load_ban_list(v)
            elif k == 'vehicle':
                for i in v:
                    func.create_vehicle(*i)
            elif k == 'vehicle_handling':
                for i in v:
                    func.set_handling_rule(*i)
            elif k == 'object':
                for i in v:
                    func.create_object(*i)
            elif k == 'teleport':
                load_teleport(v)
