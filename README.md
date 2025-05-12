# 📖 Heal with Holy Whacks

A free FiveM resource where the power of the book is... questionable, but effective.

Smack your friends to health or bring them back from beyond with the mysterious *Healing Book*. Whether they’re injured or flat-out dead, a swift bonk or a strange whispered "prayer" might just do the trick. Just... don’t ask too many questions about where the power comes from.

---

## 🧰 Features

- 🔨 Use the **Healing Book** as a melee weapon to heal living players  
- 🕯️ If a player is dead, hitting them starts a **ritual-like revival** sequence  
- ⚡ Works with both **QB-Core** and **Ox Inventory**  
- 🧙 A perfect blend of comedy, mystery, and unexpectedly dark energy  

---

## 📦 Installation

1. Drag and drop `mrc-holyman` and `mrc-holyman-book` into your `resources` folder
2. Add `ensure mrc-holyman-book` and `ensure mrc-holyman` to your server.cfg
3. Add the image (`weapon_book.png`) to your inventory's image folder  
4. Add the item data using the config for your inventory system below  

---

## 📚 Item Config Examples

### 🧱 QB-Core

```lua
['WEAPON_BOOK'] = {
    ['name'] = 'weapon_book',
    ['label'] = 'Holy Book',
    ['weight'] = 1000,
    ['type'] = 'weapon',
    ['ammotype'] = nil,
    ['image'] = 'weapon_book.png',
    ['unique'] = true,
    ['useable'] = true,
    ['description'] = 'Candy Cane'
},
```

### 🌀 Ox Inventory

```lua
['WEAPON_BOOK'] = {
    label = 'Holy Book',
    weight = 1000,
    durability = 0.1,
},
```

---

## 📸 Preview
COMING SOON!!!

---

## ❓ Why?

Because sometimes healing takes a little force — and maybe a light sprinkle of mysterious chanting.
