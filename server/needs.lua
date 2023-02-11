-- Use status calls to make configured types
for k,v in pairs(Config.Status) do
    addType(k, v.defaultAmount, v.precedence, v.availableToClient, v.tickDecay, v.onTick)
end

-- Register commands
ESX.RegisterCommand('removeType', 'admin', function(xPlayer, args, showError)
    local name = args.name
    removeType(name)
end, true, {
    help = TranslateCap('command_removeType'),
    validate = true,
    arguments = {
        {
            name = 'name',
            help = TranslateCap('command_removeType_name'),
            type = 'string'
        },
    }
})

ESX.RegisterCommand('alterStatus', 'admin', function(xPlayer, args, showError)
    local name = args.name
    local amount = args.amount
    alterStatus(xPlayer.identifier, name, amount)
    tickSingleStatus(xPlayer, name)
end, true, {
    help = TranslateCap('command_alterStatus'),
    validate = true,
    arguments = {
        {
            name = 'name',
            help = TranslateCap('command_alterStatus_name'),
            type = 'string'
        },
        {
            name = 'amount',
            help = TranslateCap('command_alterStatus_amount'),
            type = 'number'
        },
    }
})

ESX.RegisterCommand('setStatus', 'admin', function(xPlayer, args, showError)
    local name = args.name
    local amount = args.amount
    setStatus(xPlayer.identifier, name, amount)
    tickSingleStatus(xPlayer, name)
end, true, {
    help = TranslateCap('command_setStatus'),
    validate = true,
    arguments = {
        {
            name = 'name',
            help = TranslateCap('command_setStatus_name'),
            type = 'string'
        },
        {
            name = 'amount',
            help = TranslateCap('command_setStatus_amount'),
            type = 'number'
        },
    }
})

ESX.RegisterCommand('addEffect', 'admin', function(xPlayer, args, showError)
    local name = args.name
    local type

    if args.type == 'b' then
        type = 'buff'
    elseif type == 'e' then
        type = 'enfe'
    else
        return
    end

    local amount = args.amount
    local duration = args.duration
    addEffect(xPlayer.identifier, name, type, amount, duration)
    tickSingleStatus(xPlayer, name)
end, true, {
    help = TranslateCap('command_addEffect'),
    validate = true,
    arguments = {
        {
            name = 'name',
            help = TranslateCap('command_addEffect_name'),
            type = 'string'
        },
        {
            name = 'type',
            help = TranslateCap('command_addEffect_type'),
            type = 'string'
        },
        {
            name = 'amount',
            help = TranslateCap('command_addEffect_amount'),
            type = 'number'
        },
        {
            name = 'duration',
            help = TranslateCap('command_addEffect_duration'),
            type = 'number'
        },
    }
})

ESX.RegisterCommand('removeEffect', 'admin', function(xPlayer, args, showError)
    local name = args.name
    local type

    if args.type == 'b' then
        type = 'buff'
    elseif type == 'e' then
        type = 'enfe'
    else
        return
    end

    removeEffect(xPlayer.identifier, name, type)
end, true, {
    help = TranslateCap('command_addEffect'),
    validate = true,
    arguments = {
        {
            name = 'name',
            help = TranslateCap('command_addEffect_name'),
            type = 'string'
        },
        {
            name = 'type',
            help = TranslateCap('command_addEffect_type'),
            type = 'string'
        },
    }
})

-- Tick thread
RegisterNetEvent('pc-needs:server:tick', function()
    statusTick()
    effectTick()
end)

CreateThread(function()
    local tickTime = Config.TickTime * 1000

    while true do
        TriggerEvent('pc-needs:server:tick')
        Wait(tickTime)
    end
end)
