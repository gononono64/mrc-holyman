# 📖 Heal with Holy Whacks

A free FiveM resource that lets you heal people the old-fashioned way: hitting them with a book.

The **Healing Book** can be used as a melee weapon to heal injured players. If they're already dead, things get a little more involved.

---

## 🧰 Features

* 🔨 Hit living players with the **Healing Book** to heal them
* 🕯️ Hitting a dead player starts a revival ritual
* ⚡ Supports **QB-Core** and **Ox Inventory**
* 📖 Includes the custom book weapon/model
* 🆓 Free

---

## 📦 Installation

1. Drag `mrc-holyman` and `mrc-holyman-book` into your `resources` folder
2. Download and install `community_bridge`
3. Make sure `community_bridge` starts before `mrc-holyman-book` and `mrc-holyman` in your `server.cfg`
4. Add `weapon_book.png` to your inventory's image folder
5. Add the weapon to your inventory using the appropriate example below

### Resource Order

```cfg
ensure community_bridge
ensure mrc-holyman-book
ensure mrc-holyman
```

---

## 📚 Item Config

### QB-Core

Add to `qb-core/shared/weapons.lua`:

```lua
[`WEAPON_BOOK`] = {
    name = 'weapon_book',
    label = 'Holy Book',
    weapontype = 'Melee',
    ammotype = nil,
    damagereason = 'Healed'
},
```

### Ox Inventory

Add to `ox_inventory/data/weapons.lua`:

```lua
['WEAPON_BOOK'] = {
    label = 'Holy Book',
    weight = 1000,
    durability = 0.1,
},
```

---

## 📸 Preview

Coming soon.

---

## ❓ Why?

I made a book you can beat people back to life with.

That's pretty much it.
