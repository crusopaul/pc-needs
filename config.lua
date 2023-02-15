Config = {}

-- Enables /statusRoll for testing / setup of the StatMaxImpactOnStatusRoll / StatusPointToRollAgainst
Config.Debug = false

-- Seconds between status ticks - be mindful of this value when setting up tickDecay on status types
Config.TickTime = 5

-- Bounds for the status values - adjust and rerun SQL if modified
Config.StatMinimum = 0
Config.StatMaximum = 100000

-- Both used for ease of use below
local statInterval = Config.StatMaximum - Config.StatMinimum
local statMidpoint = statInterval / 2

-- The max impact that the difficulty can have on a status roll
Config.StatMaxImpactOnStatusRoll = statInterval / 3

-- The value that status rolls must be rolled against to be considered a pass
Config.StatusPointToRollAgainst = statInterval / 3

-- A function to kill a player randomly within the next 0.001-10s
local function kill(source)
    CreateThread(function()
        local roll = math.random(1, 10000)
        Wait(roll)
        TriggerClientEvent('esx:killPlayer', source)
    end)
end

-- Status types
Config.Status = {}

Config.Status.dexterity = {
    defaultAmount = statMidpoint,
    precedence = 1,
    availableToClient = false,
    tickDecay = 0,
    onTick = nil
}

Config.Status.intelligence = {
    defaultAmount = statMidpoint,
    precedence = 2,
    availableToClient = false,
    tickDecay = 0,
    onTick = nil
}

Config.Status.luck = {
    defaultAmount = statMidpoint,
    precedence = 3,
    availableToClient = false,
    tickDecay = 0,
    onTick = nil
}

Config.Status.strength = {
    defaultAmount = statMidpoint,
    precedence = 4,
    availableToClient = false,
    tickDecay = 0,
    onTick = nil
}

Config.Status.crafting = {
    defaultAmount = Config.StatMinimum,
    precedence = 5,
    availableToClient = false,
    tickDecay = 0,
    onTick = nil
}

Config.Status.gathering = {
    defaultAmount = Config.StatMinimum,
    precedence = 6,
    availableToClient = false,
    tickDecay = 0,
    onTick = nil
}

Config.Status.hunger = {
    defaultAmount = Config.StatMaximum,
    precedence = 7,
    availableToClient = true,
    tickDecay = 50,
    onTick = function(source, identifier, value)
        if value == Config.StatMinimum then -- If no hunger, kill
            kill(source)
        end
    end
}

Config.Status.thirst = {
    defaultAmount = Config.StatMaximum,
    precedence = 8,
    availableToClient = true,
    tickDecay = 80,
    onTick = function(source, identifier, value)
        if value == Config.StatMinimum then -- If no thirst, kill
            kill(source)
        end
    end
}

Config.Status.stress = {
    defaultAmount = Config.StatMinimum,
    precedence = 9,
    availableToClient = true,
    tickDecay = 150,
    onTick = function(source, identifier, value)
        local vehicle = GetVehiclePedIsIn(GetPlayerPed(source), false)

        if vehicle then
            local speed = GetEntitySpeed(vehicle)

            if speed >= 89.4 then -- at 200 mph add More stress
                alterStatus(identifier, 'stress', 1200)
                value = bindValue(value + 1200)
            elseif speed >= 67.1 then -- at 150 mph add more stress
                alterStatus(identifier, 'stress', 1000)
                value = bindValue(value + 1000)
            elseif speed >= 44.7 then -- at 100 mph begin adding stress
                alterStatus(identifier, 'stress', 800)
                value = bindValue(value + 800)
            end
        end

        if value == Config.StatMaximum then -- If fully stressed, kill
            kill(source)
        end
    end
}

Config.Status.caffeine = {
    defaultAmount = Config.StatMinimum,
    precedence = 10,
    availableToClient = true,
    tickDecay = 3000,
    onTick = function(source, identifier, value)
        if value == Config.StatMaximum then -- Full caffeine should kill
            kill(source)
            TriggerClientEvent('pc-needs:client:SetWalkSpeed', source, 1.49)
        elseif value >= statMidpoint then -- Any caffeine should have a noticeably boosted walk speed
            TriggerClientEvent('pc-needs:client:SetWalkSpeed', source, 1.49)
        elseif value > Config.StatMinimum then -- Any caffeine should have a slightly boosted walk speed
            TriggerClientEvent('pc-needs:client:SetWalkSpeed', source, 1.2)
        else -- No caffeine should have a normal walk speed
            TriggerClientEvent('pc-needs:client:SetWalkSpeed', source, 1)
        end
    end
}

local outburstEmotes = {'stumble', 'idledrunk', 'idledrunk2', 'idledrunk3'}

Config.Status.alcohol = {
    defaultAmount = Config.StatMinimum,
    precedence = 11,
    availableToClient = true,
    tickDecay = 1000,
    onTick = function(source, identifier, value)
        if value == Config.StatMaximum then -- Full alcohol should kill
            kill(source)
            TriggerClientEvent('pc-needs:client:SetDrunkEffect', source, true)
        elseif value >= statInterval / 3 then -- 33.33% alcohol should impose random drunk animations and screen effect
            TriggerClientEvent('pc-needs:client:SetDrunkEffect', source, true)
            local outburstRoll = math.random(1, 100)

            if outburstRoll > 95 then
                local outburstEmote = outburstEmotes[math.random(1,4)]
                TriggerClientEvent('pc-needs:client:SetDrunkOutburst', source, outburstEmote)
            end
        else -- No alcohol should mean no screen effect
            TriggerClientEvent('pc-needs:client:SetDrunkEffect', source, false)
        end
    end
}

Config.Status.acid = {
    defaultAmount = Config.StatMinimum,
    precedence = 12,
    availableToClient = true,
    tickDecay = 2000,
    onTick = function(source, identifier, value)
        if value == Config.StatMaximum then -- Full acid should kill
            kill(source)
            TriggerClientEvent('pc-needs:client:SetAcidEffect', source, true)
        elseif value > Config.StatMinimum then -- Any acid should give screen effect
            TriggerClientEvent('pc-needs:client:SetAcidEffect', source, true)
        else -- No acid should have no screen effect
            TriggerClientEvent('pc-needs:client:SetAcidEffect', source, false)
        end
    end
}

Config.Status.thc = {
    defaultAmount = Config.StatMinimum,
    precedence = 13,
    availableToClient = true,
    tickDecay = 6969,
    onTick = function(source, identifier, value)
        if value >= statMidpoint then -- Half thc should have screen effect
            TriggerClientEvent('pc-needs:client:SetWeedEffect', source, true)
        else -- Less than half thc should not have screen effect
            TriggerClientEvent('pc-needs:client:SetWeedEffect', source, false)
        end
    end
}

Config.Status.toxicity = {
    defaultAmount = Config.StatMinimum,
    precedence = 14,
    availableToClient = true,
    tickDecay = 0,
    onTick = function(source, identifier, value)
        local str = getStatusAmount(identifier, 'stress')
        local caf = getStatusAmount(identifier, 'caffeine')
        local alc = getStatusAmount(identifier, 'alcohol')
        local aci = getStatusAmount(identifier, 'acid')
        local thc = getStatusAmount(identifier, 'thc')
        local newAmount = bindValue((str * 0.05) + (caf * 0.5) + (alc * 0.8) + (aci * 0.3) + (thc * 0.01))
        setStatus(identifier, 'toxicity', newAmount)

        if newAmount == Config.StatMaximum then -- If a linear sum of drug status amounts adds to full toxicity the player should die
            kill(source)
        end
    end
}
