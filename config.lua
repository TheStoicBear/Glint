-- config.lua
-- Holds all spotlight and keybinding settings

local Config = {}

-- Keybinds
Config.Keys = {
    ToggleFlood   = 182,   -- L
    ToggleAlley   = 182,   -- L (double tap)
    ToggleTrack   = 0,     -- none by default
    ToggleTakedown= 0,     -- none by default
}

-- Double-tap detection
Config.DoubleTapThreshold = 300  -- ms between taps on the same key

-- UI
Config.UI = {
    CommandOpen   = 'spotlightui',
    CommandFocus  = 'spotlightfocus',
}

-- Tracking (for the “track” spotlight)
Config.Track = {
    MaxDistance    = 250.0,
    AngleDeg       = 90,
    SmoothFactor   = 0.15,
}

-- Floodlight (front-center roof)
Config.Floodlight = {
    Offset = vector3(0.0,  1.5, 1.5),
    Direction = vector3(0.0, 0.0, 0.0),  -- forward from vehicle
    Color    = {255, 255, 255},
    InnerCone= 40.0,
    OuterCone= 40.0,
    Falloff  = 10.0,
    Distance = 50.0,
    Intensity= 40.0,
}

-- Alley lights (roof sides)
Config.Alley = {
    SideOffset   = 0.8,
    FrontOffset  = 0.0,
    Height       = 1.5,
    Color        = {255, 255, 255},
    InnerCone    = 30.0,
    OuterCone    = 20.0,
    Falloff      = 1.0,
    Distance     = 35.0,
    Intensity    =  5.0,
}

-- Takedown lights (front-mount trio)
Config.Takedown = {
    SideOffset   = 0.8,
    FrontOffset  = 1.5,
    Height       = 1.5,
    Color        = {255, 255, 255},
    AimDownZ     = -0.2,    -- tilt
    InnerCone    = 20.0,
    OuterCone    = 10.0,
    Falloff      =  5.0,
    Distance     = 40.0,
    Intensity    = 20.0,
}

-- Return it so client.lua can `require` or pick it up as a shared script
return Config
