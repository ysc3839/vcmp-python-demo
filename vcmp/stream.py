from typing import AnyStr
from io import BytesIO
from struct import Struct

struct_int32 = Struct('<i')
struct_float = Struct('<f')
struct_uint16_be = Struct('>H')

class Stream(BytesIO):
    def write_byte(self, b: int) -> None:
        self.write(bytes([b]))

    def write_int(self, i: int) -> None:
        self.write(struct_int32.pack(i))

    def write_float(self, f: float) -> None:
        self.write(struct_float.pack(f))

    def write_string(self, s: AnyStr, encoding='utf-8') -> None:
        if isinstance(s, str):
            s = s.encode(encoding)
        self.write(struct_uint16_be.pack(len(s)))
        self.write(s)

    def read_byte(self) -> int:
        return self.read(1)[0]

    def read_int(self) -> int:
        return struct_int32.unpack(self.read(struct_int32.size))[0]

    def read_float(self) -> float:
        return struct_float.unpack(self.read(struct_float.size))[0]

    def read_string(self, to_str=True, encoding='utf-8') -> AnyStr:
        length = struct_uint16_be.unpack(self.read(struct_uint16_be.size))[0]
        s = self.read(length)
        if to_str:
            s = s.decode(encoding)
        return s
