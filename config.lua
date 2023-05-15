-- Config
Config = {}

-- Enables /statusRoll for testing / setup of the StatMaxImpactOnStatusRoll / StatusPointToRollAgainst
Config.Debug = false

-- Use effects - would not recommend for a high latency db connection
Config.UseEffects = true

-- Seconds between status ticks - be mindful of this value when setting up tickDecay on status types
Config.TickTime = 5

-- Both used for ease of use below
local statMidpoint = 100000 / 2

-- The max impact that the difficulty can have on a status roll
Config.StatMaxImpactOnStatusRoll = 100000 / 3

-- The value that status rolls must be rolled against to be considered a pass
Config.StatusPointToRollAgainst = 100000 / 3 - 200

-- A function to kill a player randomly within the next 0.001-10s
local function kill(source)
    local ped = GetPlayerPed(source)

    if ped ~= 0 and GetEntityHealth(ped) ~= 0 and not GetPlayerInvincible(source) then
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
    defaultAmount = 0,
    availableToClient = false,
    tickDecay = 0,
    onTick = nil
}

Config.Status.intelligence = {
    defaultAmount = 0,
    availableToClient = false,
    tickDecay = 0,
    onTick = nil
}

Config.Status.luck = {
    defaultAmount = 0,
    availableToClient = false,
    tickDecay = 0,
    onTick = nil
}

Config.Status.strength = {
    defaultAmount = 0,
    availableToClient = false,
    tickDecay = 0,
    onTick = nil
}

Config.Status.gathering = {
    defaultAmount = 0,
    availableToClient = false,
    tickDecay = 0,
    onTick = nil
}

Config.Status.hunger = {
    defaultAmount = 100000,
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
    availableToClient = true,
    tickDecay = 3000,
    onTick = function(source, identifier, value)
        if value == 100000 then -- Full caffeine should kill
            kill(source)
            TriggerClientEvent('pc-needs:client:SetCaffeineEffect', source, true)
        elseif value > 0 then -- Any caffeine should have a slightly boosted stamina regen speed
            TriggerClientEvent('pc-needs:client:SetCaffeineEffect', source, true)
        else -- No caffeine should have a normal stamina regen speed
            TriggerClientEvent('pc-needs:client:SetCaffeineEffect', source, false)
        end
    end
}

local outburstEmotes = {'stumble', 'idledrunk', 'idledrunk2', 'idledrunk3'}

Config.Status.alcohol = {
    defaultAmount = 0,
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
    availableToClient = true,
    tickDecay = 2000,
    onTick = function(source, identifier, value)
        if value > 0 then -- Any acid should give screen effect
            TriggerClientEvent('pc-needs:client:SetAcidEffect', source, true)
        else -- No acid should have no screen effect
            TriggerClientEvent('pc-needs:client:SetAcidEffect', source, false)
        end
    end
}

Config.Status.thc = {
    defaultAmount = 0,
    availableToClient = true,
    tickDecay = 2500,
    onTick = function(source, identifier, value)
        if value >= statMidpoint then -- Half thc should have screen effect
            TriggerClientEvent('pc-needs:client:SetWeedEffect', source, true)
        else -- Less than half thc should not have screen effect
            TriggerClientEvent('pc-needs:client:SetWeedEffect', source, false)
        end
    end
}

Config.Status.oxy = {
    defaultAmount = 0,
    availableToClient = true,
    tickDecay = 1500,
    onTick = function(source, identifier, value)
        if value == 100000 then -- Full oxy should kill
            kill(source)
            TriggerClientEvent('pc-needs:client:SetOxyEffect', source, true, true)
        elseif value > 30000 then -- Oxy above 30% should give screen effect
            TriggerClientEvent('pc-needs:client:SetOxyEffect', source, true, true)
        elseif value > 20000 then -- Oxy above 20% give healing effect
            TriggerClientEvent('pc-needs:client:SetOxyEffect', source, true, false)
        else -- No oxy should give no healing
            TriggerClientEvent('pc-needs:client:SetOxyEffect', source, false, false)
        end
    end
}

Config.Status.meth = {
    defaultAmount = 0,
    availableToClient = true,
    tickDecay = 2000,
    onTick = function(source, identifier, value)
        if value == 100000 then -- Full meth should kill
            kill(source)
            TriggerClientEvent('pc-needs:client:SetMethEffect', source, true)
        elseif value > 0 then -- Any meth should have a screen effect
            TriggerClientEvent('pc-needs:client:SetMethEffect', source, true)
        else -- No meth should do nothing
            TriggerClientEvent('pc-needs:client:SetMethEffect', source, false)
        end
    end
}
