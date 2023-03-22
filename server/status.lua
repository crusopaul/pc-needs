-- local states
local statusTypes = {}
local status = {}
local identMap = {}

-- State sync / desync
RegisterNetEvent('esx_multicharacter:CharacterChosen', function(charid, isNew)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    while not xPlayer do
        Wait(100)
        xPlayer = ESX.GetPlayerFromId(src)
    end

    local identifier = xPlayer.identifier
    identMap[src] = identifier

    if not status[identifier] then
        status[identifier] = {}
    end

    for k,v in pairs(statusTypes) do
        status[identifier][k] = MySQL.prepare.await('SELECT amount from status where identifier = ? and statusTypeName = ?', { identifier, k }) or v.defaultAmount
    end
end)

AddEventHandler('esx:playerDropped', function(playerId, reason)
    local src = playerId
    local identifier = identMap[src]

    if identifier then
        for k,v in pairs(status[identifier]) do
            MySQL.prepare.await('INSERT INTO status values ( ?, ?, ? ) on duplicate key update amount = values(amount)', { identMap[src], k, v })
        end

        status[identifier] = nil
        identMap[src] = nil
    end
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        statusTypes = Config.Status
        status = {}

        for k,v in pairs(ESX.GetExtendedPlayers()) do
            identMap[v.source] = v.identifier

            for l,q in pairs(statusTypes) do
                if not status[v.identifier] then
                    status[v.identifier] = {}
                end

                status[v.identifier][l] = MySQL.prepare.await('SELECT amount from status where identifier = ? and statusTypeName = ?', { v.identifier, l }) or q.defaultAmount
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        for _,v in pairs(identMap) do
            for l,q in pairs(status) do
                MySQL.prepare.await('UPDATE status set amount = ? where identifier = ? and statusTypeName = ?', { q, v.identifier, l })
            end
        end
    end
end)

AddEventHandler('txAdmin:events:scheduledRestart', function(eventData)
    if eventData.secondsRemaining == 60 then
        for _,v in pairs(identMap) do
            for l,q in pairs(status) do
                MySQL.prepare.await('UPDATE status set amount = ? where identifier = ? and statusTypeName = ?', { q, v.identifier, l })
            end
        end
    end
end)

-- global interaction
function addType(name, defaultAmount, availableToClient, tickDecay, onTick)
    statusTypes[name] = {
        defaultAmount = defaultAmount,
        availableToClient = availableToClient,
        tickDecay = tickDecay,
        onTick = onTick,
    }
end

exports('addType', addType)

-- global status interaction
function getStatusAmount(identifier, name)
    if status[identifier] then
        return status[identifier][name] or statusTypes[name].defaultAmount
    else -- offline player, undefined
        return statusTypes[name].defaultAmount
    end
end

exports('getStatusAmount', getStatusAmount)

function alterStatus(identifier, name, amount)
    local currentAmount

    if status[identifier] then
        currentAmount = status[identifier][name] or statusTypes[name].defaultAmount
    else -- offline player, undefined
        currentAmount = statusTypes[name].defaultAmount
    end

    local newAmount = currentAmount + amount

    if newAmount > 100000 then
        newAmount = 100000
    elseif newAmount < 0 then
        newAmount = 0
    end

    if status[identifier] then
        status[identifier][name] = newAmount
    else -- offline player, undefined
        -- ...
    end
end

exports('alterStatus', alterStatus)

function setStatus(identifier, name, amount)
    local newAmount = amount

    if newAmount > 100000 then
        newAmount = 100000
    elseif newAmount < 0 then
        newAmount = 0
    end

    if status[identifier] then
        status[identifier][name] = amount
    else -- offline player, undefined
        -- ...
    end
end

exports('setStatus', setStatus)

local statImpact = Config.StatMaxImpactOnStatusRoll
local statRollPoint = Config.StatusPointToRollAgainst

function statusRoll(identifier, name, mode)
    local amount

    if status[identifier] then
        amount = status[identifier][name] or statusTypes[name].defaultAmount
    else -- offline player, undefined
        amount = statusTypes[name].defaultAmount
    end

    local difficultyEffect

    if mode == 'easy' then
        difficultyEffect = math.random(1, math.floor(statImpact))
    elseif mode == 'medium' then
        difficultyEffect = 0
    elseif mode == 'hard' then
        difficultyEffect = -math.random(1, math.floor(statImpact))
    end

    if amount ~= 0 then
        return statRollPoint <= math.random(0, amount) + difficultyEffect
    else
        return statRollPoint <= difficultyEffect
    end
end

exports('statusRoll', statusRoll)

function tickSingleStatus(identifier, name)
    local src = ESX.GetPlayerFromIdentifier(identifier).source
    local currentAmount

    if status[identifier] then
        currentAmount = status[identifier][name] or statusTypes[name].defaultAmount
    else -- offline player, undefined
        currentAmount = statusTypes[name].defaultAmount
    end

    if statusTypes[name].onTick then
        statusTypes[name].onTick(src, identifier, currentAmount)
    end
end

-- global effect interaction-- local effect relations
local function checkEffectTableExistence(identifier, name, type)
    return 1 == MySQL.prepare.await('SELECT 1 from effect where identifier = ? and statusTypeName = ? and `type` = ?;',
        { identifier, name, type })
end

local function getEffectAmount(identifier, name, type)
    return MySQL.prepare.await('SELECT amount from effect where identifier = ? and statusTypeName = ? and `type` = ?;',
        { identifier, name, type })
end

function addEffect(identifier, name, type, amount, duration)
    if amount ~= 0 then
        if checkEffectTableExistence(identifier, name, type) then
            MySQL.prepare.await([[UPDATE effect
set
    amount = case
        when type = 'buff'
        then greatest(?, amount)
        else least(?, amount)
    end,
    expires = case
        when expires is null
        then null
        when type = 'buff'
        then date_add(expires, interval ? second)
        else date_add(expires, interval ? second)
    end
where
    identifier = ?
    and statusTypeName = ?
    and type = ?;
]], { amount, amount, math.floor(duration * 0.5), duration, identifier, name, type })
        else
            MySQL.prepare.await('INSERT into effect values (?, ?, ?, ?, now(), date_add(now(), interval ? second));', { identifier, name, type, amount, duration })
            alterStatus(identifier, name, amount)
        end
    end
end

exports('addEffect', addEffect)

function removeEffect(identifier, name, type)
    local effectAmount = getEffectAmount(identifier, name, type)

    if effectAmount then
        alterStatus(identifier, name, -effectAmount)
        MySQL.prepare.await('DELETE A from effect A where A.identifier = ? and A.statusTypeName = ? and A.`type` = ?;',
            { identifier, name, type })
    end
end

exports('removeEffect', removeEffect)

function bindValue(field)
    local val = field

    if val < 0 then
        val = 0
    elseif val > 100000 then
        val = 100000
    end

    return val
end

exports('bindValue', bindValue)

-- global tick control
function statusTick()
    for k,v in pairs(statusTypes) do
        local tickDecay = v.tickDecay

        for l,q in pairs(identMap) do
            local identifier = q
            local currentAmount

            if status[identifier] then
                currentAmount = status[identifier][k] or v.defaultAmount
            else -- offline player, undefined
                currentAmount = v.defaultAmount
            end

            if v.onTick then
                v.onTick(l, identifier, currentAmount)
            end

            if tickDecay ~= 0 then
                alterStatus(identifier, k, -tickDecay)
            end
        end
    end
end

local effectTickRunning = false

function effectTick()
    if not effectTickRunning then
        effectTickRunning = true

        for _,v in pairs(ESX.GetExtendedPlayers()) do
            local data = MySQL.prepare.await('SELECT statusTypeName, type from effect where expires <= now() and identifier = ?',
                { v.identifier })

            if type(data) == 'table' then
                for _,q in pairs(data) do
                    if type(q) ~= 'table' then
                        removeEffect(v.identifier, data.statusTypeName, data.type)
                        break
                    else
                        removeEffect(v.identifier, q.statusTypeName, q.type)
                    end
                end
            end
        end

        effectTickRunning = false
    end
end
