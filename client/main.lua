local currentSpeed = 1
local currentAcidEffect = false
local currentDrunkEffect = false
local currentHighEffect = false

RegisterNetEvent('pc-needs:client:SetAcidEffect', function(acidEffect)
    if currentAcidEffect ~= acidEffect then
        currentAcidEffect = acidEffect

        if currentAcidEffect then
            AnimpostfxPlay('DMT_flight', 0, true)
        else
            AnimpostfxStop('DMT_flight')
        end
    end
end)

RegisterNetEvent('pc-needs:client:SetDrunkEffect', function(drunkEffect)
    if currentDrunkEffect ~= drunkEffect then
        currentDrunkEffect = drunkEffect

        if currentDrunkEffect then
            ShakeGameplayCam('DRUNK_SHAKE', 1)
            AnimpostfxPlay('HeistCelebEnd', 0, true)
        else
            ShakeGameplayCam('DRUNK_SHAKE', 0)
            AnimpostfxStop('HeistCelebEnd')
        end
    end
end)

RegisterNetEvent('pc-needs:client:SetDrunkOutburst', function(emote)
    CreateThread(function()
        exports["rpemotes"]:EmoteCommandStart(emote, nil)
    end)
end)

RegisterNetEvent('pc-needs:client:SetWeedEffect', function(weedEffect)
    if currentWeedEffect ~= weedEffect then
        currentWeedEffect = weedEffect

        if currentWeedEffect then
            AnimpostfxPlay('DrugsMichaelAliensFightOut', 0, true)
        else
            AnimpostfxStop('DrugsMichaelAliensFightOut')
        end
    end
end)

RegisterNetEvent('pc-needs:client:SetWalkSpeed', function(speed)
    if currentSpeed ~= speed then
        currentSpeed = speed
        SetRunSprintMultiplierForPlayer(PlayerId(), currentSpeed)
    end
end)
