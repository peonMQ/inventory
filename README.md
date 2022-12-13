# inventory
Inventory management GUI.

Library to help broadcast important information to all EQBC connected toons, or a single defined toon (driver).

Heavily inspired by Knightly's 'Write' lua script'

## Requirements

- MQ
- MQ2Lua
- MQ2EQBC

## Installation
Download the latest `inventory.zip` from the latest [release](https://github.com/peonMQ/inventory/releases) and unzip the contents to the `lua` folder of your MQ directory.

## Usage

Start the application by running the following command in-game.
```bash
/lua run inventory/ui
```
or

```bash
/lua run inventory
```

To be able to search in offline characters, an export for those characters must have been made.

### Export
Using the `Export`button will make all your current logged in characters export their inventory and bank inventory into a `lua` file. The file will save to the following directory:

`{MQConfigDir}\{ServerName}\Export\Inventory\{CharacterName}.lua`


### Tips
Courtesy of [@xackery](https://github.com/xackery)

Setting this alias:
`/alias /find /multiline ; /lua run inventory ; /lua run inventory/client/search ${Me.Name}`

You can do quick searches by:
`/find "Manastone"`
