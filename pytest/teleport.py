import vcmp
from _vcmp import functions as func

teleports = {}

def load_teleport(t):
    global teleports
    for i in t:
        pos = i[0]
        to = i[1]
        options = {'radius': 2.0, 'move_vehicle': False, 'is_sphere': True}
        if len(i) >= 3:
            options.update(i[2])
        check_point_id = func.create_check_point(-1, 0, options['is_sphere'], *pos, 252, 138, 242, 255, options['radius'])
        teleports[check_point_id] = (to, options['move_vehicle'])

@vcmp.callback
def on_checkpoint_entered(check_point_id, player_id):
    if check_point_id in teleports:
        to, move_vehicle = teleports[check_point_id]
        vehicle_id = func.get_player_vehicle_id(player_id)
        if vehicle_id == 0:
            func.set_player_position(player_id, *to)
        elif move_vehicle:
            # FIXME bikes only
            x, y, z = to
            func.set_vehicle_speed(vehicle_id, 0.0, 0.0, 0.0, False, False)
            func.set_vehicle_rotation(vehicle_id, 0.0, 0.0, 1.0, 0.0)
            func.set_vehicle_position(vehicle_id, x, y, z - 0.5, False)
            func.set_vehicle_speed(vehicle_id, 0.0, 0.0, 0.0, False, False)
            func.set_vehicle_rotation(vehicle_id, 0.0, 0.0, 1.0, 0.0)
