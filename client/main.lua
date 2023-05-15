local currentCaffeineEffect
local caffeineThreadSpawn
local currentAcidEffect
local currentDrunkEffect
local currentHighEffect
local currentOxyRegenEffect
local currentOxyEffect
local currentMethEffect
local methThreadSpawn

RegisterNetEvent('pc-needs:client:SetCaffeineEffect', function(caffeineEffect)
    if currentCaffeineEffect == nil or currentCaffeineEffect ~= caffeineEffect then
        currentCaffeineEffect = caffeineEffect

        if currentCaffeineEffect then
            if not caffeineThreadSpawn then
                caffeineThreadSpawn = true

                CreateThread(function()
                    local playerId = PlayerId()
                    local maxStamina = GetPlayerMaxStamina(playerId)
                    local newStamina
 
                    while currentCaffeineEffect do
                        newStamina = math.floor(maxStamina / 12 + GetPlayerStamina(playerId))

                        if newStamina > maxStamina then
                            newStamina = maxStamina
                        end

                        SetPlayerStamina(playerId, newStamina * 1.0)
                        Wait(1000)
                    end

                    caffeineThreadSpawn = false
                end)
            end
        end
    end
end)

RegisterNetEvent('pc-needs:client:SetAcidEffect', function(acidEffect)
    if currentAcidEffect == nil or currentAcidEffect ~= acidEffect then
        currentAcidEffect = acidEffect

        if currentAcidEffect then
            AnimpostfxPlay('DMT_flight', 0, true)
        else
            AnimpostfxStop('DMT_flight')
        end
    end
end)

RegisterNetEvent('pc-needs:client:SetDrunkEffect', function(drunkEffect)
    if currentDrunkEffect == nil or currentDrunkEffect ~= drunkEffect then
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
    if currentWeedEffect == nil or currentWeedEffect ~= weedEffect then
        currentWeedEffect = weedEffect

        if currentWeedEffect then
            AnimpostfxPlay('DrugsMichaelAliensFightOut', 0, true)
        else
            AnimpostfxStop('DrugsMichaelAliensFightOut')
        end
    end
end)

RegisterNetEvent('pc-needs:client:SetOxyEffect', function(regenEffect, screenEffect)
    if currentOxyRegenEffect == nil or currentOxyRegenEffect ~= regenEffect then
        currentOxyRegenEffect = regenEffect

        if currentOxyRegenEffect then
            CreateThread(function()
                local ped = PlayerPedId()
                local maxHealth = 200

                while (not IsPedDeadOrDying(ped, 1)) and currentOxyRegenEffect do
                    SetEntityHealth(ped, math.min(maxHealth, math.floor(maxHealth / 128 + GetEntityHealth(ped))))
                    Wait(1000)
                end
            end)
        end
    end

    if currentOxyEffect == nil or currentOxyEffect ~= screenEffect then
        currentOxyEffect = screenEffect

        if currentOxyEffect then
            AnimpostfxPlay('DrugsDrivingIn', 0, true)
        else
            AnimpostfxStop('DrugsDrivingIn')
        end
    end
end)

RegisterNetEvent('pc-needs:client:SetMethEffect', function(methEffect)
    if currentMethEffect == nil or currentMethEffect ~= methEffect then
        currentMethEffect = methEffect

        if currentMethEffect then
            AnimpostfxPlay('BikerFilter', 0, true)
            SetRunSprintMultiplierForPlayer(PlayerId(), 1.2)

            if not methThreadSpawn then
                methThreadSpawn = true

                CreateThread(function()
                    local ped = PlayerPedId()
                    local maxArmour = GetPlayerMaxArmour(PlayerId())

                    while currentMethEffect do
                        AddArmourToPed(ped, math.floor(maxArmour / 8))
                        Wait(5000)
                    end

                    methThreadSpawn = false
                end)
            end
        else
            AnimpostfxStop('BikerFilter')
            SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
        end
    end
end)
