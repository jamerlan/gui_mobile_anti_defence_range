--------------------------------------------------------------------------------
function widget:GetInfo()
    return {
        name      = "Mobile anti defence range",
        desc      = "Draws circle to show mobile anti defence range",
        author    = "[teh]decay",
        date      = "5 oct 2013",
        license   = "GNU GPL, v2 or later",
        version   = 1,
        layer     = 5,
        enabled   = true  --  loaded by default?
    }
end

-- project page on github: https://github.com/jamerlan/gui_mobile_anti_defence_range

--Changelog
--


--------------------------------------------------------------------------------
-- Speedups
--------------------------------------------------------------------------------
local arm_mobile_anti = UnitDefNames.armscab.id
local core_mobile_anti = UnitDefNames.cormabm.id

local spGetActiveCommand = Spring.GetActiveCommand
local spGetMouseState = Spring.GetMouseState
local spTraceScreenRay = Spring.TraceScreenRay
local spPos2BuildPos = Spring.Pos2BuildPos

local glColor = gl.Color
local glDepthTest = gl.DepthTest
local glDrawGroundCircle = gl.DrawGroundCircle


local spGetMyPlayerID		= Spring.GetMyPlayerID
local spGetPlayerInfo		= Spring.GetPlayerInfo
local spGetMyAllyTeamID	= Spring.GetMyAllyTeamID
local spGetUnitDefID	= Spring.GetUnitDefID
local spGetUnitPosition = Spring.GetUnitPosition
local spGetUnitVelocity = Spring.GetUnitVelocity
local spMarkerAddPoint	= Spring.MarkerAddPoint
local spGetTeamUnits	= Spring.GetTeamUnits
local spGetPositionLosState = Spring.GetPositionLosState


local mobileAntiInLos = {}
local mobileAntiOutOfLos = {}


local coverageRangeArm = WeaponDefs[UnitDefNames.armscab.weapons[1].weaponDef].coverageRange
local coverageRangeCore = WeaponDefs[UnitDefNames.cormabm.weapons[1].weaponDef].coverageRange

--------------------------------------------------------------------------------
-- Callins
--------------------------------------------------------------------------------
function widget:DrawWorld()
    for uID, pos in pairs(mobileAntiInLos) do
        local x, y, z = spGetUnitPosition(uID)

        if x ~= nil and y ~= nil and z ~= nil then
            glColor(1, 1, 0, .6)
            glDepthTest(true)
            glDrawGroundCircle(x, y, z, pos.coverageRange, 256)
        end
    end

    for uID, pos in pairs(mobileAntiOutOfLos) do
        local a, b, c = spGetPositionLosState(pos.x, pos.y, pos.z)
        if b then
            mobileAntiOutOfLos[uID] = nil
        end
    end

    for uID, pos in pairs(mobileAntiOutOfLos) do
        if pos.x ~= nil and pos.y ~= nil and pos.z ~= nil then
            glColor(1, 1, 0, .6)
            glDepthTest(true)
            glDrawGroundCircle(pos.x, pos.y, pos.z, pos.coverageRange, 256)
        end
    end
end

function widget:UnitEnteredLos(unitID)
    local unitDefId = spGetUnitDefID(unitID);
    if unitDefId == arm_mobile_anti or unitDefId == core_mobile_anti then
        local x, y, z = spGetUnitPosition(unitID)
        local pos = {}
        pos["x"] = x
        pos["y"] = y
        pos["z"] = z
        pos.coverageRange = unitDefId == arm_mobile_anti and coverageRangeArm or coverageRangeCore
        mobileAntiInLos[unitID] = pos
        mobileAntiOutOfLos[unitID] = nil
    end
end

function widget:UnitLeftLos(unitID)
    local unitDefId = spGetUnitDefID(unitID);
    if unitDefId == arm_mobile_anti or unitDefId == core_mobile_anti then

        local x, y, z = spGetUnitPosition(unitID)
        local pos = {}
        pos["x"] = x or mobileAntiInLos[unitID].x
        pos["y"] = y or mobileAntiInLos[unitID].y
        pos["z"] = z or mobileAntiInLos[unitID].z
        pos.coverageRange = unitDefId == arm_mobile_anti and coverageRangeArm or coverageRangeCore
        mobileAntiOutOfLos[unitID] = pos

        mobileAntiInLos[unitID] = nil
    end
end

function widget:UnitCreated(unitID, unitDefID, teamID, builderID)
    local unitDefId = spGetUnitDefID(unitID);
    if unitDefId == arm_mobile_anti or unitDefId == core_mobile_anti then
        local x, y, z = spGetUnitPosition(unitID)
        local pos = {}
        pos["x"] = x
        pos["y"] = y
        pos["z"] = z
        pos.coverageRange = unitDefId == arm_mobile_anti and coverageRangeArm or coverageRangeCore
        mobileAntiInLos[unitID] = pos
    end
end

function widget:GameFrame(n)
    for uID, _ in pairs(mobileAntiInLos) do
        if not Spring.GetUnitDefID(uID) then
            mobileAntiInLos[uID] = nil -- has died
        end
    end
end

function widget:Initialize()
    local _, _, spec, teamId = Spring.GetPlayerInfo(Spring.GetMyPlayerID())

    for _, unitID in ipairs(spGetTeamUnits(teamId)) do
        local unitDefId = spGetUnitDefID(unitID);
        if unitDefId == arm_mobile_anti or unitDefId == core_mobile_anti then
            local x, y, z = spGetUnitPosition(unitID)
            local pos = {}
            pos["x"] = x
            pos["y"] = y
            pos["z"] = z
            pos.coverageRange = unitDefId == arm_mobile_anti and coverageRangeArm or coverageRangeCore
            mobileAntiInLos[unitID] = pos
        end
    end

    return true
end

--------------------------------------------------------------------------------
