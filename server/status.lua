-- local statusTypes relations
local statusType = {}

local function checkTypeExistence(name)
    return 1 == MySQL.prepare.await('SELECT 1 from statusTypes where name = ?;', { name })
end

local function getStatusTypes()
    return MySQL.query.await('SELECT name from statusTypes order by precedence;', {})
end

local function getStatusTypeTickDecay(name)
    return MySQL.prepare.await('SELECT tickDecay from statusTypes where name = ?;',
        { name })
end

local function checkStatusTypeAvailable(name)
    return MySQL.prepare.await('SELECT availableToClient from statusTypes where name = ?;',
        { name })
end

local function getMaxPrecendence()
    return MySQL.query.await('SELECT max(precedence) as max from statusTypes;', {})[1].max
end

-- local status relations
local function getStatusAmountInternal(identifier, name)
    return MySQL.prepare.await([[SELECT ifnull(B.amount, A.defaultAmount)
from statusTypes A
left join status B
on
    B.statusTypeName = A.name
    and B.identifier = ?
where
    A.name = ?;
]], { identifier, name })
end

-- local effect relations
local function checkEffectTableExistence(identifier, name, type)
    return 1 == MySQL.prepare.await('SELECT 1 from effect where identifier = ? and statusTypeName = ? and `type` = ?;',
        { identifier, name, type })
end

local function getEffectAmount(identifier, name, type)
    return MySQL.prepare.await('SELECT amount from effect where identifier = ? and statusTypeName = ? and `type` = ?;',
        { identifier, name, type })
end

local function bindValueInternal(field)
    local val = field

    if val < 0 then
        val = 0
    elseif val > 100000 then
        val = 100000
    end

    return val
end

-- global statusTypes interaction
function addType(name, defaultAmount, precedence, availableToClient, tickDecay, onTick)
    statusType[name] = onTick

    local boundDefaultAmount = bindValueInternal(defaultAmount)

    local maxPrecedence = getMaxPrecendence()

    if not maxPrecedence then
        maxPrecedence = 0
    end

    MySQL.prepare.await('UPDATE statusTypes A set precedence = ? where A.precedence = ? and name != ?;',
        { maxPrecedence + 1, precedence, name })

    if checkTypeExistence(name) then
        MySQL.prepare.await('UPDATE statusTypes A set defaultAmount = ?, precedence = ?, availableToClient = ?, tickDecay = ? where name = ?;',
            { boundDefaultAmount, precedence, availableToClient, tickDecay, name })
    else
        MySQL.prepare.await('INSERT into statusTypes values ( ?, ?, ?, ?, ? );',
            { name, boundDefaultAmount, precedence, availableToClient, tickDecay })
    end
end

exports('addType', addType)

function removeType(name)
    MySQL.prepare.await('DELETE A from effect A where statusTypeName = ?;', { name })
    MySQL.prepare.await('DELETE A from status A where statusTypeName = ?;', { name })
    MySQL.prepare.await('DELETE A from statusTypes A where name = ?;', { name })
    statusType[name] = nil
end

-- global status interaction
function getStatusAmount(identifier, name)
    return getStatusAmountInternal(identifier, name)
end

exports('getStatusAmount', getStatusAmount)

function alterStatus(identifier, name, amount)
    MySQL.prepare.await('INSERT into status select ?, ?, case when defaultAmount + ? > 100000 then 100000 when defaultAmount + ? < 0 then 0 else defaultAmount + ? end from statusTypes where name = ? on duplicate key update amount = case when amount + ? > 100000 then 100000 when amount + ? < 0 then 0 else amount + ? end;', { identifier, name, amount, amount, amount, name, amount, amount, amount })
end

exports('alterStatus', alterStatus)

function setStatus(identifier, name, amount)
    MySQL.prepare.await('INSERT into status select ?, ?, case when ? > 100000 then 100000 when ? < 0 then 0 else ? end from statusTypes where name = ? on duplicate key update amount = case when ? > 100000 then 100000 when ? < 0 then 0 else ? end', { identifier, name, amount, amount, amount, name, amount, amount, amount })
end

exports('setStatus', setStatus)

local statImpact = Config.StatMaxImpactOnStatusRoll
local statRollPoint = Config.StatusPointToRollAgainst

function statusRoll(identifier, name, mode)
    local amount = getStatusAmountInternal(identifier, name)
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
        return statRollPoint <= 0 + difficultyEffect
    end
end

exports('statusRoll', statusRoll)

function tickSingleStatus(identifier, name)
    local src = ESX.GetPlayerFromIdentifier(identifier)

    if src and statusType[name] then
        local value = getStatusAmountInternal(identifier, name)
        statusType[name](src, identifier, value)
    end
end

-- global effect interaction
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
    return bindValueInternal(field)
end

exports('bindValue', bindValue)

-- global tick control
function statusTick()
    for _,v in ipairs(getStatusTypes()) do
        local name = v.name
        local tickDecay = getStatusTypeTickDecay(name)

        for _,q in pairs(ESX.GetExtendedPlayers()) do
            local identifier = q.identifier
            local source = q.source

            if statusType[name] then
                statusType[name](source, identifier, getStatusAmountInternal(identifier, name))
            end

            if tickDecay ~= 0 then
                alterStatus(identifier, name, -tickDecay)
            end
        end
    end
end

function effectTick()
    for _,v in ipairs(MySQL.query.await('SELECT identifier, statusTypeName, type from effect where expires <= now();', {})) do
        removeEffect(v.identifier, v.statusTypeName, v.type)
    end
end
