MAX_PLAYERS = 100

def RGB(r=0, g=0, b=0):
    return r << 16 | g << 8 | b

def RGBA(r=0, g=0, b=0, a=0):
    return r << 24 | g << 16 | b << 8 | a
