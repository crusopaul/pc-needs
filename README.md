# pc-needs
A SQL based need system for an ESX environment.

This resource was made to replace ESX’s native status resources (namely esx_basicneeds, esx_optionalneeds, esx_status, and esx_hud) with a configurable status system. Currently ESX’s provided system is predominantly client-sided whereas this status system operates predominantly on the server and syncs its state with the database.

This is intended to be used with pc-hud and pc-consumables, however, they can be easily be omitted / replaced with some scripting knowledge.

Moving the system to the server allows for:
- More security / forced server side validation
- Flexible durations (that either persist or do not persist across disconnects / reboots)
- Interactable stats that do not need to share their state with clients

# Features
## Traditional needs
This system supports basic needs that are subject to a time decay (like hunger and thirst) while a player is connected.

## Temporary effects
Exports can add temporary or permanent buffs / enfeeblements to players that expire in real time as opposed to tick timing while a player is connected.

## RPG / Reputation traits
With this system, you may create and modify relatively static status types that act like traditional RPG traits like strength, intelligence, etc. These kinds of traits also allow for a reputation-style status type.

## Skill checks
Exports can be used to make rolls against RPG / reputation-like status types with three levels of difficulty.

## Player augmentations
This resource comes with the following augmentations that can trigger based off of status type set up:
- Player speed (caffeine)
- Acid effect
- Drunk effect (plus 5% chance of random outbursts, see config.lua)
- High effect (thc)
- Death / overdose

## [Preview](https://streamable.com/86ygwm)
In this preview, I am using a separate script to remove the minimap health and armor bars based on this [thread](https://forum.cfx.re/t/minimap-without-health-armour-bar/937129) - this is not the doing of pc-hud. Chat is [cc-chat](https://forum.cfx.re/t/cc-chat-chat-theme/4840882). Minimap [here](https://forum.cfx.re/t/free-release-postal-code-map-minimap-fixed/4882127).

## Drawbacks
Effect ticks use SQL to correctly store and calculate expiration state. As such, having a large player base alongside a high latency connection to your db may cause server performance issues.

## Dependencies
This resource is intended to be used in tandem with pc-consumables / pc-hud in an ox_inventory environment, but you could easily omit pc-consumables or replace pc-hud.

Additionally, you will need ESX. There is also a dependency on rpemotes if you decide to utilize pc-consumables.

## Additional credit
pc-hud is my first TypeScript / React project. As such, I heavily referenced (and directly copied with proper licensing / attribution some of) the build and utility scripts used in the graphical components of ox_inventory. I give credit to Linden, Dunak, Luke, and the other contributors of ox_inventory for this.

If you feel that I have not properly credited, or honored the license of, the contributors of ox_inventory then let me know so that I can properly do so.

# Exports
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

Used to bind an amount between pc-need's max and min values (0 and 100,000.)

## Events
A single server event, `pc-needs:server:tick`, is exposed so that a resource may listen for tick timing from this resource.

All player augmentations are enforced via client events. See client.lua for more information.

## License
This resource is licensed under the MIT License - feel free to do as you desire with it so long as the terms of the [LICENSE](LICENSE) are met.
