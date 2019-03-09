# pylint: disable=missing-docstring, line-too-long

from typing import Tuple, Union

from math import nan

from _vcmp import functions as func
from .enum import PlayerOption

Vector = Tuple[float, float, float]

class Player:
    def __init__(self, player_id):
        self._id = player_id

    # Read-write properties

    @property
    def admin(self):
        return func.is_player_admin(self._id)

    @admin.setter
    def admin(self, value):
        func.set_player_admin(self._id, value)

    @property
    def angle(self):
        return func.get_player_heading(self._id)

    @angle.setter
    def angle(self, value):
        func.set_player_heading(self._id, value)

    @property
    def armor(self):
        return func.get_player_armour(self._id)

    @armor.setter
    def armor(self, value):
        func.set_player_armour(self._id, value)

    @property
    def armour(self):
        return self.armor

    @armour.setter
    def armour(self, value):
        self.armor = value

    @property
    def can_attack(self):
        return func.get_player_option(self._id, PlayerOption.CanAttack.value)

    @can_attack.setter
    def can_attack(self, value):
        func.set_player_option(self._id, PlayerOption.CanAttack.value, value)

    @property
    def can_driveby(self):
        return func.get_player_option(self._id, PlayerOption.DriveBy.value)

    @can_driveby.setter
    def can_driveby(self, value):
        func.set_player_option(self._id, PlayerOption.DriveBy.value, value)

    @property
    def cash(self):
        return func.get_player_money(self._id)

    @cash.setter
    def cash(self, value):
        func.set_player_money(self._id, value)

    @property
    def color(self): # FIXME EntityRGB
        return func.get_player_colour(self._id)

    @color.setter
    def color(self, value):
        func.set_player_colour(self._id, value)

    @property
    def colour(self):
        return self.color

    @colour.setter
    def colour(self, value):
        self.color = value

    @property
    def driveby_ability(self):
        return self.can_driveby

    @driveby_ability.setter
    def driveby_ability(self, value):
        func.CanDriveby = value

    @property
    def frozen(self):
        return func.get_player_option(self._id, PlayerOption.Controllable.value)

    @frozen.setter
    def frozen(self, value):
        func.set_player_option(self._id, PlayerOption.Controllable.value, value)

    @property
    def green_scanlines(self):
        return func.get_player_option(self._id, PlayerOption.GreenScanlines.value)

    @green_scanlines.setter
    def green_scanlines(self, value):
        func.set_player_option(self._id, PlayerOption.GreenScanlines.value, value)

    @property
    def has_chat_tags(self):
        return func.get_player_option(self._id, PlayerOption.ChatTagsEnabled.value)

    @has_chat_tags.setter
    def has_chat_tags(self, value):
        func.set_player_option(self._id, PlayerOption.ChatTagsEnabled.value, value)

    @property
    def has_marker(self):
        return func.get_player_option(self._id, PlayerOption.HasMarker.value)

    @has_marker.setter
    def has_marker(self, value: bool):
        func.set_player_option(self._id, PlayerOption.HasMarker.value, value)

    @property
    def heading(self):
        return self.angle

    @heading.setter
    def heading(self, value):
        self.angle = value

    @property
    def health(self):
        return func.get_player_health(self._id)

    @health.setter
    def health(self, value):
        func.set_player_health(self._id, value)

    @property
    def immunity(self):
        return func.get_player_immunity_flags(self._id)

    @immunity.setter
    def immunity(self, value):
        func.set_player_immunity_flags(self._id, value)

    @property
    def is_admin(self):
        return self.admin

    @is_admin.setter
    def is_admin(self, value):
        self.admin = value

    @property
    def is_drunk(self):
        return func.get_player_option(self._id, PlayerOption.DrunkEffects.value)

    @is_drunk.setter
    def is_drunk(self, value):
        func.set_player_option(self._id, PlayerOption.DrunkEffects.value, value)

    @property
    def is_frozen(self):
        return self.frozen

    @is_frozen.setter
    def is_frozen(self, value):
        self.frozen = value

    @property
    def is_on_radar(self):
        return self.has_marker

    @is_on_radar.setter
    def is_on_radar(self, value):
        self.has_marker = value

    @property
    def is_weapon_sync_blocked(self):
        return self.can_attack

    @is_weapon_sync_blocked.setter
    def is_weapon_sync_blocked(self, value):
        self.can_attack = value

    @property
    def money(self):
        return self.cash

    @money.setter
    def money(self, value):
        self.cash = value

    @property
    def name(self):
        return func.get_player_name(self._id)

    @name.setter
    def name(self, value):
        func.set_player_name(self._id, value)

    @property
    def pos(self): # FIXME EntityVector
        return func.get_player_position(self._id)

    @pos.setter
    def pos(self, value):
        func.set_player_position(self._id, *value)

    @property
    def score(self):
        return func.get_player_score(self._id)

    @score.setter
    def score(self, value):
        func.set_player_score(self._id, value)

    @property
    def sec_world(self):
        return func.get_player_secondary_world(self._id)

    @sec_world.setter
    def sec_world(self, value):
        func.set_player_secondary_world(self._id, value)

    @property
    def show_markers(self):
        return func.get_player_option(self._id, PlayerOption.ShowMarkers.value)

    @show_markers.setter
    def show_markers(self, value):
        func.set_player_option(self._id, PlayerOption.ShowMarkers.value, value)

    @property
    def slot(self):
        return func.get_player_weapon_slot(self._id)

    @slot.setter
    def slot(self, value):
        func.set_player_weapon_slot(self._id, value)

    @property
    def skin(self):
        return func.get_player_skin(self._id)

    @skin.setter
    def skin(self, value):
        func.set_player_skin(self._id, value)

    @property
    def spectate_target(self):
        return func.get_player_spectate_target(self._id)

    @spectate_target.setter
    def spectate_target(self, value):
        if isinstance(value, int):
            func.set_player_spectate_target(self._id, value)
        elif isinstance(value, type(self)):
            func.set_player_spectate_target(self._id, value.id)
        else:
            raise TypeError('spectate_target must be a player id or a player instance')

    @property
    def speed(self): # FIXME EntityVector
        return func.get_player_speed(self._id)

    @speed.setter
    def speed(self, value):
        func.set_player_speed(self._id, *value)

    @property
    def team(self):
        return func.get_player_team(self._id)

    @team.setter
    def team(self, value):
        func.set_player_team(self._id, value)

    @property
    def vehicle(self): # FIXME Vehicle class
        return func.get_player_vehicle_id(self._id)

    @vehicle.setter
    def vehicle(self, value):
        func.put_player_in_vehicle(self._id, value, 0, False, True)

    @property
    def wanted_level(self):
        return func.get_player_wanted_level(self._id)

    @wanted_level.setter
    def wanted_level(self, value):
        func.set_player_wanted_level(self._id, value)

    @property
    def white_scanlines(self):
        return func.get_player_option(self._id, PlayerOption.WhiteScanlines.value)

    @white_scanlines.setter
    def white_scanlines(self, value):
        func.set_player_option(self._id, PlayerOption.WhiteScanlines.value, value)

    @property
    def widescreen(self):
        return func.get_player_option(self._id, PlayerOption.Widescreen.value)

    @widescreen.setter
    def widescreen(self, value):
        func.set_player_option(self._id, PlayerOption.Widescreen.value, value)

    @property
    def world(self):
        return func.get_player_world(self._id)

    @world.setter
    def world(self, value):
        func.set_player_world(self._id, value)

    #Read-only properties

    @property
    def action(self):
        return func.get_player_action(self._id)

    @property
    def aim_dir(self):
        return func.get_player_aim_direction(self._id)

    @property
    def aim_pos(self):
        return func.get_player_aim_position(self._id)

    @property
    def alpha(self):
        return func.get_player_alpha(self._id)

    @property
    def ammo(self):
        return func.get_player_weapon_ammo(self._id)

    @property
    def away(self):
        return func.is_player_away(self._id)

    @property
    def camera_locked(self):
        return func.is_camera_locked(self._id)

    @property
    def class_(self):
        return func.get_player_class(self._id)

    @property
    def fps(self):
        return func.get_player_fps(self._id)

    @property
    def game_keys(self):
        return func.get_player_game_keys(self._id)

    @property
    def id(self):
        return self._id

    @property
    def ip(self):
        return func.get_player_ip(self._id)

    @property
    def is_crouching(self):
        return func.is_player_crouching(self._id)

    @property
    def is_on_fire(self):
        return func.is_player_on_fire(self._id)

    @property
    def is_spawned(self):
        return func.is_player_spawned(self._id)

    @property
    def key(self):
        return func.get_player_key(self._id)

    @property
    def ping(self):
        return func.get_player_ping(self._id)

    @property
    def spawned(self):
        return self.is_spawned

    @property
    def standing_on_object(self):
        return func.get_player_standing_on_object(self._id)

    @property
    def standing_on_vehicle(self):
        return func.get_player_standing_on_vehicle(self._id)

    @property
    def state(self):
        return func.get_player_state(self._id)

    @property
    def typing(self):
        return func.is_player_typing(self._id)

    @property
    def unique_world(self):
        return func.get_player_unique_world(self._id)

    @property
    def unique_id(self):
        return func.get_player_uid(self._id)

    @property
    def uid(self):
        return self.unique_id

    @property
    def unique_id2(self):
        return func.get_player_uid2(self._id)

    @property
    def uid2(self):
        return self.unique_id2

    @property
    def vehicle_slot(self):
        return func.get_player_in_vehicle_slot(self._id)

    @property
    def vehicle_status(self):
        return func.get_player_in_vehicle_status(self._id)

    @property
    def weapon(self):
        return func.get_player_weapon(self._id)

    # Functions

    def add_speed(self, speed: Vector) -> None:
        func.add_player_speed(self._id, *speed)

    def ban(self) -> None:
        func.ban_player(self._id)

    def disarm(self) -> None:
        func.remove_all_weapons(self._id)

    def eject(self) -> None:
        func.remove_player_from_vehicle(self._id)

    def get_ammo_at_slot(self, slot: int):
        return func.get_player_ammo_at_slot(self._id, slot)

    def get_weapon_at_slot(self, slot: int):
        return func.get_player_weapon_at_slot(self._id, slot)

    def give_money(self, money: int) -> None:
        func.give_player_money(self._id, money)

    def give_weapon(self, weapon: int, ammo: int) -> None:
        func.give_player_weapon(self._id, weapon, ammo)

    def kick(self) -> None:
        func.kick_player(self._id)

    def play_sound(self, sound_id: int) -> None: # FIXME chack NaN working
        func.play_sound(self.unique_world, sound_id, nan, nan, nan)

    def redirect(self, ip: str, port: int, nick: str, server_password: str, user_password: str) -> None:
        func.redirect_player_to_server(self._id, ip, port, nick, server_password, user_password)

    def remove_weapon(self, weapon: int) -> None:
        func.remove_player_weapon(self._id, weapon)

    def remove_marker(self) -> None:
        self.has_marker = False

    def restore_camera(self) -> None:
        func.restore_camera(self._id)

    def select(self) -> None:
        func.force_player_select(self._id)

    def set_alpha(self, alpha: int, fade_time: int) -> None:
        func.set_player_alpha(self._id, alpha, fade_time)

    def set_anim(self, anim: int, group: int = 0) -> None:
        func.set_player_animation(self._id, group, anim)

    def set_camera_pos(self, pos: Vector, look: Vector) -> None:
        func.set_camera_position(self._id, *pos, *look)

    # FIXME deprecated
    #def set_drunk_level(self) -> None: ...

    # FIXME deprecated
    #def set_interior(self, arg: Type) -> None: ...

    # FIXME useless
    #def set_marker(self) -> None:
    #    self.has_marker = True

    # FIXME useless
    #def set_wanted_level(self, wanted_level: int) -> None:
    #    self.wanted_level = wanted_level

    def set_weapon(self, weapon: int, ammo: int) -> None:
        func.set_player_weapon(self._id, weapon, ammo)

    def spawn(self) -> None:
        func.force_player_spawn(self._id)

    def streamed_to_player(self, target) -> None:
        if isinstance(target, int):
            return func.is_player_streamed_for_player(self._id, target)
        elif isinstance(target, type(self)):
            return func.is_player_streamed_for_player(self._id, target.id)
        raise TypeError('streamed_to_player target must be a player id or a player instance')

    # FIXME Vehicle class, player enter vehicle callback
    def put_in_vehicle_slot(self, vehicle: int, slot: int) -> None:
        func.put_player_in_vehicle(self._id, vehicle, slot, True, False)

    def request_module_list(self) -> None:
        func.get_player_module_list(self._id)
