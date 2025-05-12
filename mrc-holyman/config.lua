Config = Config or {}
Config.WeaponName = `WEAPON_BOOK`
Config.Healing = {
    Cost = 10, -- Cost to heal the player
    Amount = 10, -- Amount to heal the player
}

Config.ReviveRitual = {
    Label = "Revive %s",
    Icon = "fa-solid fa-heart-pulse",
    ParticipantsNeeded = 0, -- Number of players needed to revive a player
    Time = 0,-- Time in seconds to revive a player
    Cost = 10,-- Distance in meters to revive a player
    HealAmount = 500,-- Health to revive the player
    WeaponDamageCheckDistance = 2.0, -- Max distance for weapon damage effect to apply healing
    Followers = {
        ProgressBar = { -- General progress bar settings for all followers during the ritual
            duration = 5000,
            label = "Praying",
            animation = { -- Animation for followers during progress bar
                dict = "anim@amb@business@weed@weed_inspecting_lo_med_hi@",
                name = "weed_spraybottle_crouch_spraying_01_inspectorfemale",
                flag = 1
            },
            prop = { -- Prop for followers during progress bar
                model = "v_res_fa_candle04",
                coords = vector3(0.05, 0.05, 0.0),
                rotation = vector3(0.0, 140.0, 90.0)
            }
        },
        EffectDuration = 5000, -- Total duration of the target's animation sequence
        WaitTimeMin = 1000,    -- Min random wait time (ms) before target's animation starts
        WaitTimeMax = 2000,    -- Max random wait time (ms)
        Animation = {
            dict = "weapon@w_pi_stungun",
            name = "damage"
            -- Duration for target's animation is calculated (EffectDuration - WaitTime)
        }
    },
    Priest = { -- Priest-specific actions AFTER the main progress bar
        ProgressBar = {
            duration = 5000,
            label = "Praying",
            disable = {
                move = true,
                combat = true
            },
            animation = {
                animDict = "anim@amb@business@weed@weed_inspecting_lo_med_hi@",
                anim = "weed_spraybottle_crouch_spraying_01_inspectorfemale",
                flag = 1
            },
            prop = {
                model = "v_res_fa_candle04",
                coords = vector3(0.05, 0.05, 0.0),
                rotation = vector3(0.0, 140.0, 90.0)
            },
        },
        PostProgressBarWait = 2000, -- ms to wait after progress bar before priest's animation
        Animation = {
            dict = "misscommon@response",
            name = "bring_it_on",
            duration = 5000 -- Duration for the priest's animation
        }
    },
    Pedistal = {
        model = 'v_ilev_mp_bedsidebook',
        offset = vector3(0.0, 0.0, 0.0), -- Offset of the book from the pedestal
        rotationOffset = vector3(180.0, 0.0, 0.0), -- Rotation of the book
        particles = {
            {
                dict = 'scr_sr_adversary',
                ptfx = 'scr_sr_lg_weapon_highlight',
                size = 1.0,
                color = vector3(255, 255, 255),
                looped = true,
                loopLength = nil,
            }
        },
        markers = {
            {
                type = 1, -- Type of marker
                offset = vector3(0.0, 0.0, -2.0), -- Offset of the marker from the pedestal
                color = vector3(255, 0, 0), -- Color of the marker
                size = vector3(4.0, 4.0, 2.5), -- Scale of the marker
                alpha = 150, -- Alpha of the marker
                duration = -1, -- Duration of the marker
                distance = 2.0, -- Distance to show the marker
            }
        }
    },
}