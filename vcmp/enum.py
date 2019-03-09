from enum import IntEnum

class ServerOption(IntEnum):
    SyncFrameLimiter = 0
    FrameLimiter = 1
    TaxiBoostJump = 2
    DriveOnWater = 3
    FastSwitch = 4
    FriendlyFire = 5
    DisableDriveBy = 6
    PerfectHandling = 7
    FlyingCars = 8
    JumpSwitch = 9
    ShowMarkers = 10
    OnlyShowTeamMarkers = 11
    StuntBike = 12
    ShootInAir = 13
    ShowNameTags = 14
    JoinMessages = 15
    DeathMessages = 16
    ChatTagsEnabled = 17
    UseClasses = 18
    WallGlitch = 19
    DisableBackfaceCulling = 20
    DisableHeliBladeDamage = 21

class PlayerOption(IntEnum):
    Controllable = 0
    DriveBy = 1
    WhiteScanlines = 2
    GreenScanlines = 3
    Widescreen = 4
    ShowMarkers = 5
    CanAttack = 6
    HasMarker = 7
    ChatTagsEnabled = 8
    DrunkEffects = 9
