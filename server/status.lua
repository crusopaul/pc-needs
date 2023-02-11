-- local statusTypes relations
local statusType = {}

local function checkTypeExistence(name)
    return 1 == MySQL.prepare.await('SELECT 1 from statusTypes where name = ?;', { name })
end

local function getStatusTypes()
    return MySQL.query.await('SELECT name from statusTypes order by precedence;', {})
end

local function getStatusTypetickDecay(name)
    return MySQL.prepare.await('SELECT tickDecay from statusTypes where name = ?;',
        { name })
end

local function getStatusTypeDefaultAmount(name)
    return MySQL.prepare.await('SELECT defaultAmount from statusTypes where name = ?;',
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
local function checkStatusTableExistence(identifier, name)
    return 1 == MySQL.prepare.await('SELECT 1 from status where identifier = ? and statusTypeName = ?;',
        { identifier, name })
end

local function getStatusTableAmount(identifier, name)
    return MySQL.prepare.await('SELECT amount from status where identifier = ? and statusTypeName = ?;',
        { identifier, name })
end

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

    if val < Config.StatMinimum then
        val = Config.StatMinimum
    elseif val > Config.StatMaximum then
        val = Config.StatMaximum
    end

    return val
end

-- global statusTypes interaction
function addType(name, defaultAmount, precedence, availableToClient, tickDecay, onTick)
    statusType[name] = onTick

    local boundDefaultAmount = bindValueInternal(defaultAmount)

    CreateThread(function()
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
    end)
end

exports('addType', addType)

function removeType(name)
    CreateThread(function()
        MySQL.prepare.await('DELETE A from effect A where statusTypeName = ?;', { name })
        MySQL.prepare.await('DELETE A from status A where statusTypeName = ?;', { name })
        MySQL.prepare.await('DELETE A from statusTypes A where name = ?;', { name })
    end)

    statusType[name] = nil
end

-- global status interaction
function getStatusAmount(identifier, name)
    return getStatusAmountInternal(identifier, name)
end

exports('getStatusAmount', getStatusAmount)

function alterStatus(identifier, name, amount)
    if checkStatusTypeAvailable(name) then
        if checkStatusTableExistence(identifier, name) then
            local newAmount = bindValueInternal(getStatusTableAmount(identifier, name) + amount)

            if newAmount ~= getStatusTypeDefaultAmount(name) then
                MySQL.prepare.await('UPDATE status A set amount = ? where A.identifier = ? and A.statusTypeName = ?;',
                    { newAmount, identifier, name })
            else
                MySQL.prepare.await('DELETE A from status A where A.identifier = ? and A.statusTypeName = ?;',
                    { identifier, name })
            end
        else
            local newAmount = bindValueInternal(getStatusTypeDefaultAmount(name) + amount)

            if newAmount ~= getStatusTypeDefaultAmount(name) then
                MySQL.prepare.await('INSERT into status values ( ?, ?, ? );',
                    { identifier, name, newAmount })
            end
        end
    end
end

exports('alterStatus', alterStatus)

function setStatus(identifier, name, amount)
    local currentAmount = getStatusAmountInternal(identifier, name)
    local diff = amount - currentAmount

    if diff ~= 0 then
        alterStatus(identifier, name, diff)
    end
end

exports('setStatus', setStatus)

local statInterval = Config.StatMaximum - Config.StatMinimum
local statMidpoint = statInterval / 2
local statFifth = statInterval / 5

function statusRoll(identifier, name, mode)
    local amount = getStatusAmountInternal(identifier, name)
    local difficultyEffect

    if mode == 'easy' then
        difficultyEffect = -statFifth
    elseif mode == 'medium' then
        difficultyEffect = 0
    elseif mode == 'hard' then
        difficultyEffect = statFifth
    end

    local statBenefit = amount - statMidpoint

    return statMidpoint <= math.random(Config.StatMinimum, Config.StatMaximum) + statBenefit
end

exports('statusRoll', statusRoll)

function tickSingleStatus(xPlayer, name)
    local identifier = xPlayer.identifier
    local source = xPlayer.source
    local value = getStatusAmountInternal(identifier, name)
    statusType[name](source, identifier, value)
end

-- global effect interaction
function addEffect(identifier, name, type, amount, duration)
    if amount ~= 0 then
        CreateThread(function()
            if checkEffectTableExistence(identifier, name, type) then
                if duration == 0 then
                    MySQL.prepare.await('UPDATE effect A set expires = null, amount = least(A.amount, ?) where A.identifier = ? and A.statusTypeName = ? and A.`type` = ?;',
                        { amount, identifier, name, type })
                else
                    if type == 'buff' then
                        MySQL.prepare.await('UPDATE effect A set expires = date_add(A.expires, interval ? second), amount = least(A.amount, ?) where A.identifier = ? and A.statusTypeName = ? and A.`type` = ?;',
                            { duration * 0.5, amount, identifier, name, type })
                    else
                        MySQL.prepare.await('UPDATE effect A set expires = date_add(A.expires, interval ? second), amount = greatest(A.amount, ?) where A.identifier = ? and A.statusTypeName = ? and A.`type` = ?;',
                            { duration, amount, identifier, name, type })
                    end
                end
            else
                if (type == 'buff' or type == 'enfe') and checkTypeExistence(name) then
                    if duration == 0 then
                        MySQL.prepare.await('INSERT into effect values ( ?, ?, ?, ?, now(), null);',
                            { identifier, name, type, amount, duration })
                    else
                        MySQL.prepare.await('INSERT into effect values ( ?, ?, ?, ?, now(), date_add(now(), interval ? second));',
                            { identifier, name, type, amount, duration })
                    end
                end
            end

            alterStatus(identifier, name, amount)
        end)
    end
end

exports('addEffect', addEffect)

function removeEffect(identifier, name, type)
    CreateThread(function()
        local effectAmount = getEffectAmount(identifier, name, type)

        if effectAmount then
            alterStatus(identifier, name, -effectAmount)
            MySQL.prepare.await('DELETE A from effect A where A.identifier = ? and A.statusTypeName = ? and A.`type` = ?;',
                { identifier, name, type })
        end
    end)
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
        local tickDecay = getStatusTypetickDecay(name)

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
