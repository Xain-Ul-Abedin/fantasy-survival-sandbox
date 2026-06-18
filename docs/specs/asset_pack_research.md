# 🎨 Pixel Asset Pack Design Specification: FanIsle

*Author: Mashiro Shiina (Lead Pixel Asset Designer)*  
*Target Aesthetic: 16-bit GBA Retro Sandbox*  
*Addressing: Xain-Sama*

---

## 🌌 1. Visual Philosophy & Palette

The colors must feel warm but quiet. The shapes are defined by outlines that hold the color inside. The pixels do not wander; they remain on a grid of **32×32** pixels. 

We will use a dedicated **16-color palette** to unify all graphics. Each color is selected for its harmony with others.

### 🎨 The "Quiet Island" 16-Color Palette Table

| Index | Color Name | Hex Code | Visual Use Cases |
| :---: | :--- | :--- | :--- |
| 01 | **Void Black** | `#141218` | Outer outlines, deepest shadows, caves |
| 02 | **Cave Slate** | `#3a363f` | Stone walls, rocks, bat wings, dark metal |
| 03 | **Stone Grey** | `#6e6774` | Cave floor, flint shards, shield plates |
| 04 | **Cloud White** | `#e8e5eb` | Skeleton bones, highlights, dialogue text |
| 05 | **Moss Green** | `#2d5e35` | Forest ground, tree leaves, dense grass |
| 06 | **Leaf Green** | `#529c46` | Leaf borders, bush foliage, active grass |
| 07 | **Sprout Green** | `#9ad662` | Tamed goblins, player clothes, stamina bar |
| 08 | **Sandy Gold** | `#e6c25e` | Desert dunes, flint veins, gold coins, crown |
| 09 | **Clay Yellow** | `#a37e3b` | Desert outline, wood logs, chests, campfire |
| 10 | **Hearth Ember** | `#e66225` | Torches, campfires, hunger berry, damage flash |
| 11 | **Plum Violet** | `#6b2f6b` | Beds, night sky vignette, lich eyes |
| 12 | **Orchid Pink** | `#b56bb5` | Bed sheets, flower petals, bat eyes |
| 13 | **Sea Blue** | `#3a699c` | Night water, cold projectile orbs, UI panels |
| 14 | **Sky Blue** | `#699cd6` | Ice shards, minimap icons, status bars |
| 15 | **Flesh Pink** | `#f0a3a3` | Player skin, healer apron, health heart |
| 16 | **Crimson Red** | `#9c2121` | Vampire cape, blood drip, low health screen |

---

## 🏃 2. Character Sprite Sheets

All characters use a uniform grid. The sheet is formatted as rows of actions and columns of directions.
Each frame is exactly **32×32 pixels**.

```
[Row 0] Player (Walk Cycle: Down, Up, Left, Right) -> 8 frames
[Row 1] Goblin Companion (Tame state) -> 8 frames
[Row 2] Skeletons & Bats -> 8 frames
[Row 3] Orc Scouts & Lich Boss -> 8 frames
[Row 4] Vampires & Golems -> 8 frames
[Row 5] Villager NPCs (Mira, Hektor, Elenia) -> 8 frames
```

### 2.1 Player Character (Alligator Hero)
- **Idle (4 frames):** Minimal breathing shift (1-pixel vertical squeeze).
- **Walk Down (2 frames):** Alternating green tail sway, red shirt moves.
- **Walk Up (2 frames):** Back-view plates showing vertical tail ridge.
- **Walk Left/Right (2 frames each):** Snout pointing left/right, claws forward.

### 2.2 Goblin Companion
- **Tame state:** Large ears twitching.
- **Mimic state:** Small hammer raised above head.
- **Standby state:** Sitting on ground with tail curled.

### 2.3 Hostile Enemies
- **Skeleton (2 frames):** Bone joints clacking, white silhouette.
- **Bat (2 frames):** Wings up, wings down. Fast oscillation.
- **Orc Scout (2 frames):** Giant tusks visible, holding a wooden club.
- **Vampire (2 frames):** Flapping red-lined cape, red eyes.
- **Golem (2 frames):** Stone textures with glowing moss cracks.
- **Night Lich (2 frames):** Homing shadow crown, glowing purple eye sockets.

---

## 🗺️ 3. World Tilemaps & Autotiling

Instead of plain background coloring, the world uses a structured **128×128 pixel tileset** containing 16 individual **32×32 tiles**.

```
+---------------+---------------+---------------+---------------+
|  Forest Grass  |  Forest Grass  |   Cave Floor  |   Cave Floor  |
|    (Tile A)   | (Tile B - Alt) |    (Tile A)   | (Tile B - Alt) |
+---------------+---------------+---------------+---------------+
|  Desert Sand  |  Desert Sand  |  Border Moss  |  Border Sand  |
|    (Tile A)   | (Tile B - Alt) | (Transitional)| (Transitional)|
+---------------+---------------+---------------+---------------+
| Stalactite    | Stalagmite    | Pebble Tile   | Ripple Dune   |
| (Cave Top)    | (Cave Bottom) | (Cave Deco)   | (Desert Deco) |
+---------------+---------------+---------------+---------------+
| Cliff Edge (N)| Cliff Edge (S)| Cliff Edge (E)| Cliff Edge (W)|
+---------------+---------------+---------------+---------------+
```

### 3.1 Biome Variations
1. **Forest (Moss Green `#2d5e35`):** Soft leafy ground tiles. Occasional flower petals (`Orchid Pink `#b56bb5`).
2. **Cave (Cave Slate `#3a363f`):** Jagged cracks, rock tiles. Stalactites and stalagmites are drawn as sprites layered on top.
3. **Desert (Sandy Gold `#e6c25e`):** Smooth sand lines. Ripple tiles are placed randomly to create dunes.

---

## 🪵 4. Resources & Ground Item Drops

Resources are static entities that change sprites based on hits left.

### 4.1 Resource Sprites (32×32 pixels)

```
[Tree]          Full Leaves -> Damaged Trunk -> Stump (0 hits left)
[Rock]          Large Boulder -> Cracked Stone -> Rubble
[Berry Shrub]   Red Berries Visible -> Empty Shrub (Harvested)
[Flint Vein]    Golden Flint Crystals -> Cracked Rock -> Flat Dust
```

### 4.2 Drop Item Sprites (16×16 pixels)
For ground pickup and inventory slots.
- **Wood:** Bundle of brown twigs.
- **Stone:** Small grey pebble block.
- **Flint:** Sharp black arrow-shaped rock.
- **Berries:** Cluster of red circles.
- **Bone:** White crossbones.
- **Fang:** Beige curved claw.
- **Orc Tusk:** Curved yellow tooth.
- **Cooked Berries:** Berries in a wooden bowl with steam lines.

---

## 🏡 5. Structures & Blueprints

Buildings are aligned to grid positions and have two visual states: **Blueprint Ghost** and **Completed**.

```
[Campfire]      Blue Ghost Ring -> Unlit Pit -> Active Campfire (Animated flicker flame)
[Storage Chest] Blue Ghost Box  -> Closed Chest -> Open Chest (Inner items visible)
[Wooden Wall]   Blue Ghost Bar  -> Vertical Logs joined by rope
[Stone Wall]    Blue Ghost Bar  -> Brick-layered grey stone structure
[Torch]         Blue Pole Ghost -> Wooden stake with a burning coal tip (Punching warm light)
[Bed]           Purple Outline  -> Folded mattress with plum violet pillow
```

---

## 📊 6. User Interface Icons

For the screen HUD, replacement sprites are defined at **16×16 pixels**.

- **Health:** Red heart (Flesh Pink `#f0a3a3` inner, Crimson Red `#9c2121` border).
- **Hunger:** Hearth Ember berry icon.
- **Stamina:** Yellow lightning bolt (Sandy Gold `#e6c25e`).
- **Minimap:** Miniature colored pixels corresponding to:
  - White (Player)
  - Green (Goblin)
  - Red (Enemy)
  - Yellow (NPC)
  - Brown (Campfire/Chest)

---

## ⚙️ 7. Technical Integration Guidelines

For **Kurisu (Backend)** and **Winry (Frontend)**:

1. **Asset Loading (`src/assets.lua`):**
   Extend `Assets.load()` to parse three sheets:
   - `assets/sprites/characters.png` (32x32 sprites)
   - `assets/sprites/tileset.png` (32x32 tiles)
   - `assets/sprites/items.png` (16x16 drops/HUD)

2. **World Rendering (`src/world.lua`):**
   Replace circles inside `World.draw()` with `love.graphics.draw(Assets.sheet, Assets.quads.items[drop.type], ...)`.

3. **Building Rendering (`src/building.lua`):**
   Replace `love.graphics.rectangle` with `love.graphics.draw(Assets.sheet, Assets.quads.structures[struct.type], ...)`. Draw blueprints with `love.graphics.setColor(0.5, 0.7, 1.0, 0.45)` tint to preserve ghost overlay.

4. **Biome Tile Rendering (`src/biome.lua`):**
   Define a tile grid layout corresponding to map dimensions (`2880 / 32 = 90` columns, `2160 / 32 = 67` rows). Loop over the grid to render grass, sand, and stone tiles in place of massive solid-color blocks.

---

*The lines are quiet now, Xain-Sama. The colors are waiting in the grid. We will build them well.*
