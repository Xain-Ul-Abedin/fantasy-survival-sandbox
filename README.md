# FanIsle v1.0

> A top-down fantasy survival sandbox built with **Love2D** (Lua).  
> Survive the island, craft your weapons, tame goblins, and defeat the **Night Lich** before Day 7 ends.

---

## How to Run

1. Install [Love2D 11.x](https://love2d.org/)
2. Clone or download this repository
3. Run from the project folder:
   ```
   love .
   ```
   Or drag the `FanIsle` folder onto the Love2D executable.

### Quick Bundle (Windows)
```powershell
# Creates FanIsle.love (zip rename) ready to distribute
Compress-Archive -Path ".\*" -DestinationPath "FanIsle.zip"
Rename-Item "FanIsle.zip" "FanIsle.love"
```

---

## Controls

| Key | Action |
|-----|--------|
| `W A S D` | Move |
| `Shift` | Sprint (uses Stamina) |
| `Space` | Attack / Harvest / Hammer blueprint |
| `C` | Open/Close Crafting menu |
| `↑ ↓` | Navigate crafting recipes |
| `Space` (in menu) | Craft selected recipe |
| `B` | Place blueprint (uses first blueprint in inventory) |
| `F` | Interact (Campfire, Chest, Bed) |
| `T` | Talk to NPC / Tame or command Goblin |
| `G` | Trade with NPC (5 Wood → 2 Cooked Berries) |
| `E` | Eat (prefers Cooked Berries → Raw Berries) |
| `S` | Save game |
| `L` | Load game |
| `ESC` | Close NPC dialogue |
| `R` | Restart (from Game Over or Victory screen) |

---

## Gameplay Loop

```
Day Phase → Gather Resources → Craft → Build → Night Phase → Survive Enemies
                                                     ↓
                                          Day 7: Night Lich Rises
                                                     ↓
                                          Defeat Lich → Victory!
```

### Survival Stats
- **Health** — reaches 0 = Game Over
- **Hunger** — drains over time; eat berries to restore
- **Stamina** — used for sprinting; regenerates when not sprinting

---

## Crafting Recipes

| Item | Cost | Effect |
|------|------|--------|
| Wooden Axe | 3 Wood + 2 Flint | Harvest trees 3× faster |
| Wooden Spear | 3 Wood + 1 Flint | 25 damage, 72 reach |
| Campfire | 5 Wood + 5 Stone | Blueprint — cook 2 berries → 2 Cooked Berries |
| Storage Chest | 6 Wood + 2 Stone | Blueprint — store materials |
| Wooden Wall | 4 Wood | Blueprint — blocks movement |
| Stone Wall | 4 Stone | Blueprint — durable barrier |
| Torch | 2 Wood + 1 Flint | Blueprint — warm light during night |
| Bed | 4 Wood + 2 Berries | Blueprint — sleep to skip to dawn |

---

## World & Biomes

The world is a **2880 × 2160** pixel map (3×3 screen grid).

| Biome | Resources | Enemies |
|-------|-----------|---------|
| Forest | Trees, Berry Bushes, Stone | Skeletons, Bats |
| Cave | Stone, Flint Veins | Skeletons, Bats |
| Desert | Flint Clusters, Stone | Orc Scouts |

---

## Enemies

| Enemy | HP | Damage | Notes |
|-------|----|--------|-------|
| Skeleton | 30 | 8 | Basic melee |
| Bat | 15 | 5 | Fast, orbiting dive attack |
| Orc Scout | 70 | 18 | Slow, heavy brute |
| **Night Lich** | 300 | 25 | Spawns Day 7. Fires homing orbs, summons Skeletons every 10s |

---

## Goblin Companions

Tame wild goblins with a berry (`T` key). Press `T` again to cycle their command:
- **Follow** — walks beside the player
- **Mimic** — copies the last player action (harvest, build)
- **Standby** — stays in place

---

## NPC — Elder Mira

Found in the Forest center zone.  
- `T` — talk (cycles 5 lore lines)  
- `G` — trade: **5 Wood → 2 Cooked Berries**

---

## Persistence

- `S` — saves all game state to `savegame.lua` in the Love2D save directory
- `L` — loads from save (restores player, world, buildings, enemies, day cycle)

---

## Tech Stack

- **Engine**: [Love2D 11.x](https://love2d.org/) (Lua)
- **Audio**: Procedural synth via `love.sound.newSoundData` — no external files
- **Rendering**: Pure Love2D graphics primitives (no sprite sheets yet)
- **Save format**: Lua table serialization

---

## Project Structure

```
FanIsle/
├── main.lua              # Game loop orchestrator
└── src/
    ├── player.lua        # Player stats, movement, harvest, eat
    ├── world.lua         # Resource spawning, drops, biome rules
    ├── goblin.lua        # Goblin AI companions
    ├── enemy.lua         # Enemy archetypes, AI, Lich boss, projectiles
    ├── combat.lua        # Melee swing, weapon damage, floating numbers
    ├── crafting.lua      # Recipes, crafting menu navigation
    ├── building.lua      # Blueprint placement, structure types, torch glow
    ├── daycycle.lua      # Day/Night phases, night wave trigger
    ├── camera.lua        # Smooth-follow camera, world clamp
    ├── biome.lua         # 3×3 zone grid, ground tint, biome lookup
    ├── npc.lua           # NPC dialogue & trade
    ├── sound.lua         # Procedural sound FX manager
    ├── ui.lua            # HUD, menus, minimap, dialogue, victory screen
    └── save.lua          # Serialize/deserialize full game state
```

---

*Made with Love2D — FanIsle by Xain*
