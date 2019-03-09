# pylint: disable=missing-docstring

from typing import Tuple

from _vcmp import functions as func

Vector = Tuple[float, float, float]
Quaternion = Tuple[float, float, float, float]

class Object:
    def __init__(self, object_id):
        self._id = object_id

    # Read-write properties

    @property
    def world(self):
        return func.get_object_world(self._id)

    @world.setter
    def world(self, value: int):
        func.set_object_world(self._id, value)

    @property
    def pos(self):
        return func.get_object_position(self._id)

    @pos.setter
    def pos(self, value: Vector):
        func.set_object_position(self._id, *value)

    @property
    def shot_report(self):
        return func.is_object_shot_report_enabled(self._id)

    @shot_report.setter
    def shot_report(self, value: bool):
        func.set_object_shot_report_enabled(self._id, value)

    @property
    def touched_report(self):
        return func.is_object_touched_report_enabled(self._id)

    @touched_report.setter
    def touched_report(self, value: bool):
        func.set_object_touched_report_enabled(self._id, value)

    #Read-only properties

    @property
    def alpha(self):
        return func.get_object_alpha(self._id)

    @property
    def model(self):
        return func.get_object_model(self._id)

    @property
    def rotation(self):
        return func.get_object_rotation(self._id)

    @property
    def rotation_euler(self):
        return func.get_object_rotation_euler(self._id)

    @property
    def id(self):
        return self._id

    # Functions

    def delete(self) -> None:
        func.delete_object(self._id)

    def move_to(self, pos: Vector, time: int) -> None:
        func.move_object_to(self._id, *pos, time)

    def move_by(self, offset: Vector, time: int) -> None:
        func.move_object_by(self._id, *offset, time)

    def rotate_to(self, rotation: Quaternion, time: int) -> None:
        func.rotate_object_to(self._id, *rotation, time)

    def rotate_by(self, rot_offset: Quaternion, time: int) -> None:
        func.rotate_object_by(self._id, *rot_offset, time)

    def rotate_to_euler(self, rotation: Vector, time: int) -> None:
        func.rotate_to_euler(self._id, *rotation, time)

    def rotate_by_euler(self, rot_offset: Vector, time: int) -> None:
        func.rotate_by_euler(self._id, *rot_offset, time)

    def set_alpha(self, alpha: int, fade_time: int) -> None:
        func.set_object_alpha(self._id, alpha, fade_time)
