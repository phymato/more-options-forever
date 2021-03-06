local mod = RegisterMod("More Options Forever", 1)
local verbose = true

local importantItemList = {
    CollectibleType.COLLECTIBLE_NEGATIVE, 
    CollectibleType.COLLECTIBLE_POLAROID,
    550, -- broken shovel pt 1
    551, -- broken shovel pt 2
    552, -- mom's shovel
    580, -- red key
    626, -- knife piece 1
    627, -- knife piece 2
    633, -- dogma
    668 -- dad's note
}

function out(...) if verbose then print(...) end end

function IsImportantItem(subtype)
    for _, id in pairs(importantItemList) do
        if subtype == id then --out("IsImportantItem: true")
            return true
        end
    end
    --out("IsImportantItem: false")
    return false
end

function SpawnChoiceTreasure(pos)
    -- prevent out-of-bounds
    pos = Game():GetRoom():GetClampedPosition(pos, 1)
    -- spawn collectible
    local drop = Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, 0, pos, Vector(0,0), nil)
    AssignOptionsPickup(drop:ToPickup())
end

-- Add property to entityPickup, cross compatible with AB+ and REP
function AssignOptionsPickup(entityPickup)
    if entityPickup.OptionsPickupIndex then
        entityPickup.OptionsPickupIndex = 1 -- repentance
    else
        entityPickup.TheresOptionsPickup = true -- afterbirth
    end
end

-- Override treasure room spawn: remove everything
-- UNLESS it's a special story-related treasure room
mod:AddCallback(ModCallbacks.MC_PRE_ROOM_ENTITY_SPAWN, function(_, entityType, variant, subtype, gridIndex, seed)
    if Game():GetLevel():GetCurrentRoomDesc().Data.Variant == 10000 then goto skip end -- don't override knife 1 spawn
    if Game():GetRoom():GetType() == RoomType.ROOM_TREASURE and not IsImportantItem(subtype) then
        return {EntityType.ENTITY_NULL, 0, 0}
    end
    ::skip::
end)

-- Treasure room: Spawn three collectibles (there should be nothing in it by default)
-- UNLESS it's a special story-related treasure room
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function(_)
    if Game():GetLevel():GetCurrentRoomDesc().Data.Variant == 10000 then goto skip end -- don't override knife 1 spawn
    local room = Game():GetRoom()
    if room:GetType() == RoomType.ROOM_TREASURE and room:IsFirstVisit() then
        local center = Game():GetRoom():GetCenterPos()
        for x = -80, 80, 80 do
            --out("Spawning...")
            SpawnChoiceTreasure(center + Vector(x, 0))
        end
        out("Spawned three choice collectibles")
    end
    ::skip::
end)

-- When a pickup collectible spawns, if it's not an important item, give it OptionsPickupIndex
-- Only fires in Treasure Rooms and Boss Rooms
mod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, function(_, entityPickup)
    local roomType = Game():GetRoom():GetType()
    if roomType == RoomType.ROOM_BOSS or roomType == RoomType.ROOM_TREASURE then
        if not IsImportantItem(entityPickup.SubType) and entityPickup.Variant == PickupVariant.PICKUP_COLLECTIBLE then
            AssignOptionsPickup(entityPickup)
            --out("Made drop a choice collectible")
        else
            out("Drop is NOT a choice collectible: "..entityPickup.SubType)
        end
    end
end)

-- Handles spawning more options when a boss is killed
mod:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, function(_, RNG, spawnPos)
    local clearedBossRoom = (Game():GetRoom():GetAliveEnemiesCount() < 1) and
        (Game():GetRoom():GetType() == RoomType.ROOM_BOSS)
    if clearedBossRoom == true then
        -- Spawn two collectibles that are "choices"
        local center = Game():GetRoom():GetCenterPos()
        for x = -80, 80, 160 do
            SpawnChoiceTreasure(center + Vector(x, 0))
        end
        out("Spawned two choice collectibles, alongside boss drop")
    end
end)