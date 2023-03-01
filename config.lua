Config = {}

-- Enables /statusRoll for testing / setup of the StatMaxImpactOnStatusRoll / StatusPointToRollAgainst
Config.Debug = false

-- Seconds between status ticks - be mindful of this value when setting up tickDecay on status types
Config.TickTime = 5

-- Both used for ease of use below
local statMidpoint = 100000 / 2

-- The max impact that the difficulty can have on a status roll
Config.StatMaxImpactOnStatusRoll = 100000 / 3

-- The value that status rolls must be rolled against to be considered a pass
Config.StatusPointToRollAgainst = 100000 / 3

-- A function to kill a player randomly within the next 0.001-10s
local function kill(source)
    local ped = GetPlayerPed(source)

    if ped ~= 0 and GetEntityHealth(ped) ~= 0 then
        CreateThread(function()
            local roll = math.random(1, 10000)
            Wait(roll)
            TriggerClientEvent('esx:killPlayer', source)
        end)
    end
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
    defaultAmount = 0,
    precedence = 5,
    availableToClient = false,
    tickDecay = 0,
    onTick = nil
}

Config.Status.gathering = {
    defaultAmount = 0,
    precedence = 6,
    availableToClient = false,
    tickDecay = 0,
    onTick = nil
}

Config.Status.hunger = {
    defaultAmount = 100000,
    precedence = 7,
    availableToClient = true,
    tickDecay = 50,
    onTick = function(source, identifier, value)
        if value == 0 then -- If no hunger, kill
            kill(source)
        end
    end
}

Config.Status.thirst = {
    defaultAmount = 100000,
    precedence = 8,
    availableToClient = true,
    tickDecay = 80,
    onTick = function(source, identifier, value)
        if value == 0 then -- If no thirst, kill
            kill(source)
        end
    end
}

Config.Status.stress = {
    defaultAmount = 0,
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

        if value == 100000 then -- If fully stressed, kill
            kill(source)
        end
    end
}

Config.Status.caffeine = {
    defaultAmount = 0,
    precedence = 10,
    availableToClient = true,
    tickDecay = 3000,
    onTick = function(source, identifier, value)
        if value == 100000 then -- Full caffeine should kill
            kill(source)
            TriggerClientEvent('pc-needs:client:SetWalkSpeed', source, 1.2)
        elseif value >= statMidpoint then -- Half caffeine should have a "noticeably" boosted walk speed
            TriggerClientEvent('pc-needs:client:SetWalkSpeed', source, 1.2)
        elseif value > 0 then -- Any caffeine should have a slightly boosted walk speed
            TriggerClientEvent('pc-needs:client:SetWalkSpeed', source, 1.1)
        else -- No caffeine should have a normal walk speed
            TriggerClientEvent('pc-needs:client:SetWalkSpeed', source, 1)
        end
    end
}

local outburstEmotes = {'stumble', 'idledrunk', 'idledrunk2', 'idledrunk3'}

Config.Status.alcohol = {
    defaultAmount = 0,
    precedence = 11,
    availableToClient = true,
    tickDecay = 1000,
    onTick = function(source, identifier, value)
        if value == 100000 then -- Full alcohol should kill
            kill(source)
            TriggerClientEvent('pc-needs:client:SetDrunkEffect', source, true)
        elseif value >= 100000 / 3 then -- 33.33% alcohol should impose random drunk animations and screen effect
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
    defaultAmount = 0,
    precedence = 12,
    availableToClient = true,
    tickDecay = 2000,
    onTick = function(source, identifier, value)
        if value == 100000 then -- Full acid should kill
            kill(source)
            TriggerClientEvent('pc-needs:client:SetAcidEffect', source, true)
        elseif value > 0 then -- Any acid should give screen effect
            TriggerClientEvent('pc-needs:client:SetAcidEffect', source, true)
        else -- No acid should have no screen effect
            TriggerClientEvent('pc-needs:client:SetAcidEffect', source, false)
        end
    end
}

Config.Status.thc = {
    defaultAmount = 0,
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
    defaultAmount = 0,
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

        if newAmount == 100000 then -- If a linear sum of drug status amounts adds to full toxicity the player should die
            kill(source)
        end
    end
}
