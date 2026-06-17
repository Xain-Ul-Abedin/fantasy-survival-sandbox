# Architecture Specification: Fantasy Survival Sandbox

## 1. Engine & Environment
* **Runtime:** Love2D (Lua 5.1 / Luajit framework).
* **Target Resolution:** Dynamic window, default 960x720 (4:3 aspect ratio).
* **Physics Frame Rate:** Independent free-axis vector movement decoupled from frame rendering using standard delta-time scaling (`dt`).

---

## 2. Entity Component System (ECS) Model
A simplified ECS-like architecture is used to represent game entities to keep the system modular and extensible.

### 2.1 Entity Base Structure
All entities (Player, Resources, Goblins, Enemies) share a base properties pattern:
```lua
entity = {
    id = "string_uuid",
    type = "player|goblin|tree|stone|enemy",
    x = 0.0,
    y = 0.0,
    width = 32,
    height = 32,
    components = {}
}
```

### 2.2 Core Components
* **TransformComponent:** X/Y positions, direction, velocity vector (dx, dy).
* **RenderComponent:** Sprite index, sheet reference, animations.
* **PhysicsComponent:** Mass, collision radius, static/dynamic indicator.
* **HealthComponent:** HP, Max HP, temporary invincibility frames.
* **BrainComponent (NPCs):** State machine logic (e.g. idle, mimic, harvest, follow).
* **InventoryComponent:** Holds item IDs and stack counts.

---

## 3. Collision Mathematics (Vector Boundary Overlaps)
Calculations are handled by Raph for physics boundary collision checks.

### 3.1 Axis-Aligned Bounding Box (AABB) Collision
For simple grid-based collision overlaps (e.g., static tile blockers):
$$\text{Collision} = (A.x < B.x + B.\text{width}) \land (A.x + A.\text{width} > B.x) \land (A.y < B.y + B.\text{height}) \land (A.y + A.\text{height} > B.y)$$

### 3.2 Radial (Circle) Collision
For player harvesting ranges, combat hits, and circular obstacles:
$$\text{Distance}^2 = (A.x - B.x)^2 + (A.y - B.y)^2$$
$$\text{Collision} = \text{Distance}^2 < (A.\text{radius} + B.\text{radius})^2$$

### 3.3 Collision Resolution Vector
When a dynamic entity collides with a static obstacle, we calculate the overlap vector and push the dynamic entity back:
```lua
local function resolveCollision(player, obstacle)
    local overlapX = 0
    local overlapY = 0
    -- Compute bounding boxes overlaps and apply minimum translation vector (MTV)
    -- to player.x and player.y
end
```

---

## 4. Save State Serialization
All game progress is persisted locally to ensure a fully open and FOSS-compliant local file save structure.

### 4.1 Save File Format
Saves are written to Love2D's default application data storage (`love.filesystem.getSaveDirectory()`) in **JSON format** or **Lua Table serialization script**.
* File Name: `savegame.json`

### 4.2 Data Schema
```json
{
  "version": 1,
  "difficulty": "easy",
  "player": {
    "x": 480.0,
    "y": 360.0,
    "health": 100.0,
    "hunger": 100.0,
    "stamina": 100.0,
    "inventory": [
      { "item_id": "stone_axe", "qty": 1 },
      { "item_id": "berries", "qty": 12 }
    ]
  },
  "world": {
    "seed": 12345678,
    "day_count": 3,
    "resources": [
      { "id": "res_1", "type": "tree", "x": 120.0, "y": 450.0, "hits": 3 },
      { "id": "res_2", "type": "stone", "x": 540.0, "y": 210.0, "hits": 3 }
    ],
    "goblins": [
      {
        "id": "gob_1",
        "name": "Sparky",
        "x": 490.0,
        "y": 370.0,
        "state": "follow",
        "inventory": []
      }
    ]
  }
}
```
