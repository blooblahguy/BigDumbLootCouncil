# BigDumbLootCouncil

BigDumbLootCouncil is a loot council addon that aims to be lightweight, bug free, and work out of the box for any guild. Libraries are only added when absolutely necessary, limiting the chance that patches break the addon. 

## Usage
BigDumbLootCouncil works out of the box for most guilds. Simply have your MasterLooter loot the boss and sessions will automatically be started for everyone in the raid with BDLC. 

### On Session Start:
* All players are presented with a roll window where they can add notes and indicate level of interested (Mainspec, Offspec, Minor Upgrade, Transmog, Reroll). 
* * Quick notes allow players to "toggle" on notes that indicate more specific information, such as "2pc, 4pc, BiS"
* Loot Council members are additionally given a window that shows a table of all player interest, item level, item comparison, guild rank, and average ilvl.
* Loot Council members are given 1 vote per item and can see the votes of all other Loot Council members.
* The Master Looter can then right-click the players' name in the Vote Window and select "Award to player" for ease. Item history is being tracked, and a way to see useful information about who got items most recently will be available in a future update.

### Configuration
* /bdlc config - Opens up the configuration window
* You can change minimum guild rank to be automaticall added to the Loot Council
* You can add/remove "Quick Notes" to suite your guild's needs better, such as "1pc", "3pc", etc
* You can add/remove people to your Custom Council. This can be used to add people to the Loot Council who don't have the minimum guild rank, or who are not in guild.

### Commands
* /bdlc start [ItemLink] - Will start a session for the item link provided. Useful for when BoEs drop and you want to give them to the raid if they are an upgrade.
* /bdlc addtolc PlayerName - Adds a player by name to the Custom Loot Council (does not affect players who on are council via guild rank)
* /bdlc removefromlc PlayerName - Removes a player from the Custom Loot Council (does not affect players who on are council via guild rank)
* /bdlc show - Shows Vote Window if you closed it with the "x" button
* /bdlc version - Does a version check on the raid
* /bdlc test - Will start 4 test sessions with variable item quantities. You can use this while solo, or while in a raid if you are on the Loot Council

## Localization
Addon currently at least partially supports the following languages. (Core = addon functions, UI = Labeling such as "mainspec" or "vote")
* English: Core - 100% | UI - 100%
* French: Core - 100% | UI - 90%
* German: Core - 100% | UI - 0%
* Italian: Core - 100% | UI - 0%
* Korean: Core - 100% | UI - 0%
* Russian: Core - 100% | UI - 0%
* Spanish: Core - 100% | UI - 0%
* Brazilian Portuguese: Core - 100% | UI - 0%

You can submit more localization as an "issue" on Github, and simply copy the table definitions in localization.lua with the necessary edits.

## Support
Opening issues on Github is the best way to get support for this addon or make feature requests. Frequent patches are made to the addon that help improve is functionality and consistency, it's recommended you always keep the addon up to date and have your guild mates do the same.
