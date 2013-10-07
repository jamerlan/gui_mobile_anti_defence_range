--------------------------------------------------------------------------------
function widget:GetInfo()
    return {
        name      = "Mobile anti defence range v3",
        desc      = "Draws circle to show mobile anti defence range",
        author    = "[teh]decay",
        date      = "5 oct 2013",
        license   = "GNU GPL, v2 or later",
        version   = 3,
        layer     = 5,
        enabled   = true  --  loaded by default?
    }
end

-- project page on github: https://github.com/jamerlan/gui_mobile_anti_defence_range

--Changelog
-- v2 [teh]decay Add water antinukes
-- v3 [teh]decay fix spectator mode

--------------------------------------------------------------------------------
-- Speedups
--------------------------------------------------------------------------------
local arm_mobile_anti = UnitDefNames.armscab.id
local arm_mobile_anti_water = UnitDefNames.armcarry.id
local core_mobile_anti = UnitDefNames.cormabm.id
local core_mobile_anti_water = UnitDefNames.corcarry.id

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
local coverageRangeArmWater = WeaponDefs[UnitDefNames.armcarry.weapons[1].weaponDef].coverageRange
local coverageRangeCoreWater = WeaponDefs[UnitDefNames.corcarry.weapons[1].weaponDef].coverageRange

local spectatorMode = false

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
    if not spectatorMode then
        processVisibleUnit(unitID)
    end
end

function processVisibleUnit(unitID)
    local unitDefId = spGetUnitDefID(unitID);
    if unitDefId == arm_mobile_anti or unitDefId == core_mobile_anti or unitDefId == arm_mobile_anti_water or unitDefId == core_mobile_anti_water then
        local x, y, z = spGetUnitPosition(unitID)
        local pos = {}
        pos["x"] = x
        pos["y"] = y
        pos["z"] = z

        if unitDefId == arm_mobile_anti then
            pos.coverageRange = coverageRangeArm
        elseif unitDefId == arm_mobile_anti_water then
            pos.coverageRange = coverageRangeArmWater
        elseif unitDefId == core_mobile_anti then
            pos.coverageRange = coverageRangeCore
        else
            pos.coverageRange = coverageRangeCoreWater
        end

        mobileAntiInLos[unitID] = pos
        mobileAntiOutOfLos[unitID] = nil
    end
end

function widget:UnitLeftLos(unitID)
    if not spectatorMode then
        local unitDefId = spGetUnitDefID(unitID);
        if unitDefId == arm_mobile_anti or unitDefId == core_mobile_anti or unitDefId == arm_mobile_anti_water or unitDefId == core_mobile_anti_water then
            local x, y, z = spGetUnitPosition(unitID)
            local pos = {}
            pos["x"] = x or mobileAntiInLos[unitID].x
            pos["y"] = y or mobileAntiInLos[unitID].y
            pos["z"] = z or mobileAntiInLos[unitID].z

            if unitDefId == arm_mobile_anti then
                pos.coverageRange = coverageRangeArm
            elseif unitDefId == arm_mobile_anti_water then
                pos.coverageRange = coverageRangeArmWater
            elseif unitDefId == core_mobile_anti then
                pos.coverageRange = coverageRangeCore
            else
                pos.coverageRange = coverageRangeCoreWater
            end

            mobileAntiOutOfLos[unitID] = pos
            mobileAntiInLos[unitID] = nil
        end
    end
end

function widget:UnitCreated(unitID, unitDefID, teamID, builderID)
    processVisibleUnit(unitID)
end

function widget:UnitTaken(unitID, unitDefID, unitTeam, newTeam)
    processVisibleUnit(unitID)
end

function widget:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
    processVisibleUnit(unitID)
end

function widget:GameFrame(n)
    for uID, _ in pairs(mobileAntiInLos) do
        if not Spring.GetUnitDefID(uID) then
            mobileAntiInLos[uID] = nil -- has died
        end
    end
end

function widget:PlayerChanged(playerID)
    detectSpectatorView()
    return true
end

function widget:Initialize()
    detectSpectatorView()
    return true
end

function detectSpectatorView()
    local _, _, spec, teamId = Spring.GetPlayerInfo(Spring.GetMyPlayerID())

    if spec then
        spectatorMode = true

        local roster = Spring.GetPlayerRoster(1, true)
        for _, player in ipairs(roster) do
            local teamId = player[3]
            if teamId ~= nil then
                Spring.Echo("teamId" .. teamId)
                for _, unitID in ipairs(spGetTeamUnits(teamId)) do
                    processVisibleUnit(unitID)
                end
            end
        end
    else
        for _, unitID in ipairs(spGetTeamUnits(teamId)) do
            processVisibleUnit(unitID)
        end
    end
end

--------------------------------------------------------------------------------
