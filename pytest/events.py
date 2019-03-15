import vcmp
from _vcmp import functions as func
from .settings import load_settings

@vcmp.callback
def on_server_initialise():
    load_settings()

@vcmp.callback
def on_player_command(player_id, cmd):
    if cmd == 'pos':
        print('%.3f, %.3f, %.3f' % func.get_player_position(player_id))
        vehicle_id = func.get_player_vehicle_id(player_id)
        if vehicle_id != 0:
            print('%.3f, %.3f, %.3f' % func.get_vehicle_position(vehicle_id))
