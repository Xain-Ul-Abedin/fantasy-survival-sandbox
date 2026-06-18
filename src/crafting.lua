-- FanIsle: Crafting Module
local Crafting = {}

Crafting.isOpen = false
Crafting.selectedIndex = 1

Crafting.recipes = {
    {
        id = "wood_axe",
        name = "Wooden Axe",
        cost = { wood = 3, flint = 2 },
        type = "tool",
        desc = "Harvests trees 3x faster"
    },
    {
        id = "campfire",
        name = "Campfire",
        cost = { wood = 5, stone = 5 },
        type = "blueprint",
        desc = "Allows cooking sweet berries"
    },
    {
        id = "chest",
        name = "Storage Chest",
        cost = { wood = 6, stone = 2 },
        type = "blueprint",
        desc = "Stores raw materials"
    },
    {
        id = "wall",
        name = "Wooden Wall",
        cost = { wood = 4 },
        type = "blueprint",
        desc = "Blocks path navigation"
    },
    {
        id = "torch",
        name = "Torch",
        cost = { wood = 2, flint = 1 },
        type = "blueprint",
        desc = "Emits warm light during night"
    },
    {
        id = "spear",
        name = "Wooden Spear",
        cost = { wood = 3, flint = 1 },
        type = "tool",
        desc = "25 dmg, longer reach than axe"
    },
    {
        id = "stone_wall",
        name = "Stone Wall",
        cost = { stone = 4 },
        type = "blueprint",
        desc = "Durable stone barrier"
    },
    {
        id = "bed",
        name = "Bed",
        cost = { wood = 4, berries = 2 },
        type = "blueprint",
        desc = "Sleep to skip the night"
    }
}

-- Toggle menu state
function Crafting.toggle()
    Crafting.isOpen = not Crafting.isOpen
end

-- Navigate recipes up/down
function Crafting.navigate(direction)
    if not Crafting.isOpen then return end
    if direction == "up" then
        Crafting.selectedIndex = Crafting.selectedIndex - 1
        if Crafting.selectedIndex < 1 then
            Crafting.selectedIndex = #Crafting.recipes
        end
    elseif direction == "down" then
        Crafting.selectedIndex = Crafting.selectedIndex + 1
        if Crafting.selectedIndex > #Crafting.recipes then
            Crafting.selectedIndex = 1
        end
    end
end

-- Attempt to craft selected item
function Crafting.craft(player)
    if not Crafting.isOpen then return nil, "menu_closed" end
    
    local recipe = Crafting.recipes[Crafting.selectedIndex]
    
    -- Check costs
    for material, count in pairs(recipe.cost) do
        local invCount = player.inventory[material] or 0
        if invCount < count then
            return nil, "insufficient_" .. material
        end
    end
    
    -- Deduct costs
    for material, count in pairs(recipe.cost) do
        player.inventory[material] = player.inventory[material] - count
    end
    
    -- Grant item
    local invKey = recipe.id
    if recipe.type == "blueprint" then
        invKey = recipe.id .. "_blueprint"
    end
    
    player.inventory[invKey] = (player.inventory[invKey] or 0) + 1
    return recipe, "success"
end

return Crafting
