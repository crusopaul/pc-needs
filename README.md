# pc-needs
A SQL based need system for an ESX environment.

## Motivation
This resource was made to replace ESX's native status resources (namely esx_basicneeds, esx_optionalneeds, esx_status, and esx_hud) with an alternate and configurable status system. Currently ESX's provided system is predominantly client-sided whereas this status system operates predominantly on the server and syncs its state with the database.

Moving the system to the server allows for:
- More security / forced server side validation
- Flexible durations (that either persist or do not persist across disconnects / reboots)
- Interactable stats that do not need to share their state with clients

This need system will not work out of the box with esx_hud for displaying status information.

## Drawbacks
This is a work in progress so you may run into performance issues using this resource - I would not recommend using it in a production environment before you can evaluate how your setup is going to impact performance.

This resource currently syncs its state to the database which inherently involves overhead. I am not sure if this is going to scale all that well and the only benefits of doing so are that there is a minimal risk of data loss on a server crash and that a large data buffer / copy of the database is not required.

If the integrity of data is not worth the performance of this approach, then I intend to rewrite significant parts of this to utilize a large, internal state buffer that syncs periodically or on player connect / disconnect.

## Dependencies
This resource is intended to be used in tandem with pc-consumables / pc-hud in an ox_inventory environment, but you could easily omit pc-consumables or replace pc-hud.

Additionally, you will need ESX.

## Installation
To install pc-needs:
- Place the latest release into the resources folder
- Run the provided SQL script if this is the first installation
- Review config.lua for your needs
- Ensure pc-needs

## Known issues
For some reason, altering status types in the config.lua after already running pc-needs can occasionally cause SQL errors. If this occurs you may need to reset all status / effect data by doing the following:
```
delete from status;
delete from effect;
delete from statusTypes;
```

Alternatively you may use the removeType command in game to remove every existing statusType.

There is also an issue you can create by changing the max and min amounts in the config without changing the table definition's constraints. If you run into this, you should drop and recreate the relevant tables with adjusted constraint values that match the new max and min values in the config.

## Player augmentations
This resource comes with the following augmentations:
- Player speed (caffeine)
- Acid effect
- Drunk effect (plus 5% chance of random outbursts, see config.lua)
- High effect (thc)
- Death / overdose

Having more than status impose the same augmentation (except death or other similar one-offs) is not advised as they tend to overlap in an unintentional way. For example, caffeine and cocaine status types cannot both augment player speed otherwise the walk speed of the status type with the higher precedence overwrites that of the lower precedence.

If there is an augmentation you want, you can easily add it to client/main.lua. Refer to current file for examples on how to accomplish this.

## Exports
Resources that intend to use this need system will need to utilize the following exports.

```
addType(name, defaultAmount, precedence, availableToClient, tickDecay, onTick)
```
- name (string): The name of the status type you are creating
- defaultAmount (int): The default value of the status type
- precedence (int): The calculation precedence of the status type (higher precedence calculates later)
- availableToClient (boolean): An indication that the status type should not be sent to client
- tickDecay (int): The decay applied per tick (0 implies no decay)
- onTick (callback): The function that needs to run every tick

Would ideally only be used in this resource's config file, but in the case that you want to separate concerns you may use this. Status amounts are affected by their onTick callbacks and then are adjusted by the `-tickDecay` every tick. The tickDecay and onTick are only relevant for online players.

```
getStatusAmount(identifier, name)
```
- identifier (string): The users.identifier for the player
- name (string): The name of the status type you are trying to query

Used for getting the current value of a status.

```
alterStatus(identifier, name, amount)
```
- identifier (string): The users.identifier for the player
- name (string): The name of the status type you are trying to alter
- amount (int): The amount to alter the status by

Used for changing the status.

```
setStatus(identifier, name, amount)
```
- identifier (string): The users.identifier for the player
- name (string): The name of the status type you are trying to set
- amount (int): The amount to set the status to

Used for changing the status.

```
statusRoll(identifier, name, mode)
```
- identifier (string): The users.identifier for the player
- name (string): The name of the status type you are trying to roll against
- mode ("easy", "medium", "hard"): The difficulty of the roll

Used for a classic RPG stat roll. For example, a "strength" status can be created with no tickDecay that is used to track a player's strength. If the player wants to flip their car, they may roll for it and allow their stat's strength or weakness influence the probabilty of success by using `statusRoll`.

Currently untested.

```
addEffect(identifier, name, type, amount, duration)
```
- identifier (string): The users.identifier for the player
- name (string): The name of the status type you are trying to create an effect for
- type ("buff","enfe"): Indicates that the effect is a buff or enfeeblement (impacts how effects stack)
- amount (int): The amount to augment the status
- duration (int, seconds): The duration of the effect

Used for proccing temporary item effects etc. Effect durations persist across 

```
removeEffect(identifier, name, type)
```
- identifier (string): The users.identifier for the player
- name (string): The name of the status type you are trying to remove an effect from
- type ("buff","enfe"): Indicates that the effect is a buff or enfeeblement (impacts how effects stack)

Used to remove an active effect.

```
bindValue(field)
```
- field (int): The field to bind

Used to bind an amount between pc-need's max and min values as configured.

## Events
A single server event, `pc-needs:server:tick`, is exposed so that a resource may listen for tick timing from this resource.

All player augmentations are enforced via client events. See client.lua for more information.

## License
This resource is licensed under the MIT License - feel free to do as you desire with it so long as the terms of the [LICENSE](LICENSE) are met.
