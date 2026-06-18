# FanIsle — itch.io Store Page Pitch & Copy

## Pitch Details
- **Title**: FanIsle
- **Tagline**: Stranded on a shifting island. Command the goblins. Defeat the Night Lich.
- **Genre**: 2D Top-Down Survival Sandbox / Automation
- **Platform**: PC (Windows, macOS, Linux - runs via Love2D)

---

## Short Pitch

Wake up on a scrolling 3x3 biome map where survival is key. Gather logs, harvest stone, craft spears and campfire setups, and tame wild goblins with berries to copy your actions and automate your camp. As daylight fades, reinforce your defenses—hordes of skeletons, diving bats, desert orcs, lifestealing vampires, and massive slamming golems emerge from the shadows. Prepare your fortress before **Day 7**, when the ancient **Night Lich** rises to claim the island.

---

## Key Features

- 🤖 **Minion Automation**: Tame wild goblins and cycle their AI states. Command them to follow, stand by, or **mimic** your latest harvesting or building actions to auto-farm resources and construct walls.
- 🎵 **Generative Audio & Soundtracks**: Zero-allocation procedural music loops. Enjoy a peaceful, generative C-Major Pentatonic marimba soundtrack by day, which smoothly cross-fades into a driving, tense, dissonant chime pulse when night falls.
- 🎨 **Charming 2D Pixel Graphics**: Rich pixel-art sprites and walking cycles for players, tamed helper goblins, and all five enemy types—skeleton, bat, orc, vampire, and golem.
- ⚔️ **Tactical Action Combat**: Engage in fast-paced combat with dynamic invincibility frames, knockback mechanics, and floating damage indicators.
- 🌲 **Scrolling 3x3 Biome Map**: Navigate Forest, Cave, and Desert zones, each featuring native resources, biome ground tints, and unique hazards.
- 💾 **Seamless Save & Load**: Keep your base and progress safe with local state serialization.

---

## Controls Reference

| Key | Action |
|-----|--------|
| `W A S D` or `Arrow Keys` | Move |
| `Left Shift` | Sprint (consumes Stamina) |
| `Space` | Attack / Harvest / Hammer blueprints |
| `C` | Open / Close Crafting menu |
| `↑ ↓` (in Crafting) | Navigate recipes |
| `Space` (in Crafting) | Craft selected recipe |
| `B` | Place first available blueprint in inventory |
| `F` | Interact (Cook at Campfire, open/close Chest, sleep in Bed to skip night) |
| `T` | Talk to NPCs / Tame & Cycle Goblin commands |
| `G` | Trade with nearby NPC villagers |
| `E` | Eat (heals HP and restores Hunger) |
| `S` | Save game locally |
| `L` | Load game locally |
| `ESC` | Close active dialog |
| `R` | Restart (from Game Over or Victory screens) |
| `F3` | Toggle Diagnostic Debug Overlay |

---

## Crafting & Blueprints Guide

- **Wooden Axe**: 3 Wood + 2 Flint. Harvests trees 3x faster.
- **Wooden Spear**: 3 Wood + 1 Flint. Strikes with 25 damage and extended reach.
- **Campfire**: 5 Wood + 5 Stone. Cook 2 raw berries into Cooked Berries (+50 Hunger, +25 HP).
- **Storage Chest**: 6 Wood + 2 Stone. Safely store excess wood, stone, and flint.
- **Wooden Wall / Stone Wall**: Durable blocks to steer pathfinding and shield your camp.
- **Torch**: 2 Wood + 1 Flint. Provides a warm, animated light halo to keep the night dark at bay.
- **Bed**: 4 Wood + 2 Berries. Allows you to sleep through the dangerous dusk and night phases.

---

## Credits

- **Game Design & Coordination**: Sia (PM)
- **Audio Synthesizers**: Sound & Music procedural design by Winry
- **Rendering & Animation Systems**: Spritesheets slicing and camera coordinate interpolation by Kurisu
- **Security & Quality Auditing**: Riza (Hawkeye) and Yoruichi
- **Game Engine**: Powered by Love2D (Lua)
