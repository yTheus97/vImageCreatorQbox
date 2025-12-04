local screenshot = false
local cam = nil
local inshell = false

-- Configuration
local ARENA_COORD = vector3(2800.5966796875, -3799.7370605469, 139.41514587402)
local CAM_COORD = vector3(2800.5966796875 - 4.0, -3799.7370605469 - 4.0, 140.9514587402)
local DEFAULT_IMAGE = 'https://i.imgur.com/NHB74QX.png'

-- Vehicle class to FOV mapping
local VEHICLE_CLASS_FOV = {
    ['0'] = 40.0, ['1'] = 40.0, ['2'] = 45.0, ['3'] = 40.0, ['4'] = 40.0,
    ['5'] = 40.0, ['6'] = 40.0, ['7'] = 41.0, ['8'] = 30.0, ['9'] = 45.0,
    ['10'] = 45.0, ['11'] = 45.0, ['12'] = 45.0, ['13'] = 30.0, ['14'] = 40.0,
    ['15'] = 48.0, ['16'] = 60.0, ['17'] = 45.0, ['18'] = 44.0, ['19'] = 44.0,
    ['20'] = 45.0, ['21'] = 70.0
}

-- Arena configuration
local ARENA_CONFIG = {
    scene = "scifi",
    map = 9,
    maps = {
        dystopian = {
            "Set_Dystopian_01", "Set_Dystopian_02", "Set_Dystopian_03", "Set_Dystopian_04", "Set_Dystopian_05",
            "Set_Dystopian_06", "Set_Dystopian_07", "Set_Dystopian_08", "Set_Dystopian_09", "Set_Dystopian_10",
            "Set_Dystopian_11", "Set_Dystopian_12", "Set_Dystopian_13", "Set_Dystopian_14", "Set_Dystopian_15",
            "Set_Dystopian_16", "Set_Dystopian_17"
        },
        scifi = {
            "Set_Scifi_01", "Set_Scifi_02", "Set_Scifi_03", "Set_Scifi_04", "Set_Scifi_05",
            "Set_Scifi_06", "Set_Scifi_07", "Set_Scifi_08", "Set_Scifi_09", "Set_Scifi_10"
        },
        wasteland = {
            "Set_Wasteland_01", "Set_Wasteland_02", "Set_Wasteland_03", "Set_Wasteland_04", "Set_Wasteland_05",
            "Set_Wasteland_06", "Set_Wasteland_07", "Set_Wasteland_08", "Set_Wasteland_09", "Set_Wasteland_10"
        }
    }
}

-- Exports (kept as original)
exports('GetModelImage', function(model)
    local modelHash = tonumber(model) or GetHashKey(model)
    if not GlobalState.VehicleImages then return DEFAULT_IMAGE end
    return GlobalState.VehicleImages[tostring(modelHash)] or DEFAULT_IMAGE
end)

-- Utility Functions
local function GetVehicleFov(vehicle)
    local class = tostring(GetVehicleClass(vehicle))
    return VEHICLE_CLASS_FOV[class] or 40.0
end

local function ReqAndDelete(entity)
    if not DoesEntityExist(entity) then return end

    NetworkRequestControlOfEntity(entity)

    local attempts = 0
    while not NetworkHasControlOfEntity(entity) and attempts < 100 and DoesEntityExist(entity) do
        NetworkRequestControlOfEntity(entity)
        Wait(11)
        attempts = attempts + 1
    end

    DetachEntity(entity, 0, false)
    SetEntityCollision(entity, false, false)
    SetEntityAlpha(entity, 0.0, true)
    SetEntityAsMissionEntity(entity, true, true)
    SetEntityAsNoLongerNeeded(entity)
    DeleteEntity(entity)
end

local function SetPlayerCoords(ped, coords, heading)
    local x, y, z = table.unpack(coords)
    RequestCollisionAtCoord(x, y, z)

    while not HasCollisionLoadedAroundEntity(ped) do
        RequestCollisionAtCoord(x, y, z)
        Wait(1)
    end

    DoScreenFadeOut(950)
    Wait(1000)
    SetEntityCoords(ped, x + 5.0, y - 5.0, z)
    SetEntityHeading(ped, heading)
    DoScreenFadeIn(3000)
end

-- Arena Functions
local function UnloadArena()
    RemoveIpl('xs_arena_interior')
end

local function LoadArena()
    RequestIpl("xs_arena_interior")
    RequestIpl("xs_arena_interior_vip")
    RequestIpl("xs_arena_banners_ipl")

    local interiorID = GetInteriorAtCoords(2800.000, -3800.000, 100.000)

    if not IsInteriorReady(interiorID) then
        Wait(1)
    end

    -- Enable crowd props
    local crowdProps = {"Set_Crowd_A", "Set_Crowd_B", "Set_Crowd_C", "Set_Crowd_D"}
    for _, prop in ipairs(crowdProps) do
        EnableInteriorProp(interiorID, prop)
    end

    -- Set scene and map
    local scene = ARENA_CONFIG.scene
    EnableInteriorProp(interiorID, "Set_" .. scene:gsub("^%l", string.upper) .. "_Scene")
    EnableInteriorProp(interiorID, ARENA_CONFIG.maps[scene][ARENA_CONFIG.map])
end

local function CreateLocation()
    LoadArena()
    SetPlayerCoords(PlayerPedId(), ARENA_COORD, 82.0)
end

-- Vehicle Functions
local LastVehicleFromGarage = nil
local loading = false

local function SpawnVehicleLocal(model)
    if loading or GetNumberOfStreamingRequests() > 0 then return end

    local ped = PlayerPedId()

    -- Clean up existing vehicles
    if LastVehicleFromGarage then
        ReqAndDelete(LastVehicleFromGarage)
    end

    for _ = 1, 2 do
        local nearbyVeh = GetClosestVehicle(GetEntityCoords(ped), 2.0, 0, 70)
        if DoesEntityExist(nearbyVeh) then
            ReqAndDelete(nearbyVeh)
        end
        while DoesEntityExist(nearbyVeh) do
            ReqAndDelete(nearbyVeh)
            Wait(100)
        end
    end

    local hash = GetHashKey(model)
    if not HasModelLoaded(hash) then
        RequestModel(hash)
        loading = true
        while not HasModelLoaded(hash) do
            Wait(0)
        end
        loading = false
    end

    LastVehicleFromGarage = CreateVehicle(hash, ARENA_COORD, 90.0, 0, 1)
    while not DoesEntityExist(LastVehicleFromGarage) do Wait(0) end

    -- Use VEHICLE_CLASS_FOV for camera FOV instead of size calculation
    local vehicleFov = GetVehicleFov(LastVehicleFromGarage)
    SetCamFov(cam, vehicleFov)

    SetEntityHeading(LastVehicleFromGarage, 80.117)
    FreezeEntityPosition(LastVehicleFromGarage, true)
    SetEntityCollision(LastVehicleFromGarage, false)
    SetVehicleDirtLevel(LastVehicleFromGarage, 0.0)
    SetVehicleEngineOn(LastVehicleFromGarage, true, true, false)

    SetModelAsNoLongerNeeded(hash)
    Wait(500)
end

-- Screenshot Functions
local function InShowRoom(bool)
    CreateThread(function()
        inshell = bool
        while inshell do
            Wait(0)
            NetworkOverrideClockTime(22, 0, 0)
        end
    end)
end

local function StartScreenShoting()
    InShowRoom(true)

    local returnCoord = GetEntityCoords(PlayerPedId())
    screenshot = true
    local ped = PlayerPedId()

    FreezeEntityPosition(ped, true)
    CreateLocation()

    while not IsIplActive("xs_arena_interior") do Wait(0) end

    RequestCollisionAtCoord(ARENA_COORD.x, ARENA_COORD.y, ARENA_COORD.z)

    -- Setup camera
    cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", CAM_COORD.x, CAM_COORD.y, CAM_COORD.z,
                             360.0, 0.0, 0.0, 60.0, false, 0)
    PointCamAtCoord(cam, ARENA_COORD.x, ARENA_COORD.y, ARENA_COORD.z + 0.1)
    SetCamActive(cam, true)
    SetCamFov(cam, 42.0)
    SetCamRot(cam, -15.0, 0.0, 252.063)
    RenderScriptCams(true, true, 1, true, true)

    SetFocusPosAndVel(ARENA_COORD.x, ARENA_COORD.y, ARENA_COORD.z, 0.0, 0.0, 0.0)
    DisplayHud(false)
    DisplayRadar(false)

    -- Lighting thread
    CreateThread(function()
        while screenshot do
            Wait(0)
            DrawLightWithRange(ARENA_COORD.x - 4.0, ARENA_COORD.y - 3.0, ARENA_COORD.z + 0.3,
                             255, 255, 255, 40.0, 15.0)
            DrawSpotLight(ARENA_COORD.x - 4.0, ARENA_COORD.y + 5.0, ARENA_COORD.z, ARENA_COORD,
                        255, 255, 255, 20.0, 1.0, 1.0, 20.0, 0.95)
        end
    end)

    Wait(2000)

    -- Process vehicles for screenshots
    local vehicles = GlobalState.VehiclesFromDB or {}
    print(#vehicles, 'total vehicles')

    for i = LocalPlayer.state.screenshotnum or 1, #vehicles do
        if not screenshot then break end

        LocalPlayer.state.screenshotnum = i + 1
        SetResourceKvpInt('screenshotnum', LocalPlayer.state.screenshotnum)

        local vehicle = vehicles[i]
        local modelHash = GetHashKey(vehicle.model)

        print(vehicle.model, 'model')

        if IsModelInCdimage(modelHash) then
            CreateMobilePhone(1)
            CellCamActivate(true, true)
            Wait(100)

            SpawnVehicleLocal(vehicle.model)

            local wait = promise.new()
            exports['screenshot-basic']:requestScreenshotUpload(Config.DiscordWebHook, 'files', function(data)
                local image = json.decode(data)
                DestroyMobilePhone()
                CellCamActivate(false, false)

                if not image or not image.attachments or not image.attachments[1] or not image.attachments[1].proxy_url then
                    print("HOST UPLOAD ERROR")
                    screenshot = false
                    wait:resolve(nil)
                    return
                end

                print(image.attachments[1].proxy_url)
                local imageData = {
                    model = vehicle.model,
                    img = image.attachments[1].proxy_url
                }

                print(image.attachments[1].proxy_url)

                TriggerServerEvent('renzu_vehthumb:save_local', vehicle.model, image.attachments[1].proxy_url)
                ---------------------------

                local imageData = {
                    model = vehicle.model,
                    img = image.attachments[1].proxy_url
                }

                TriggerServerEvent('renzu_vehthumb:save', imageData)
                print("Vehicle Image Processed")
                Wait(500)
                wait:resolve(image)
                print("Vehicle Image Saved")
                Wait(500)
                wait:resolve(image)
            end)

            Citizen.Await(wait)
        else
            print(vehicle.model, ' already exists or invalid model')
        end
    end

    while screenshot do
        Wait(111)
    end

    RenderScriptCams(false)
    DestroyAllCams(true)
    ClearFocus()
    SetCamActive(cam, false)
    CellCamActivate(false, false)
    InShowRoom(false)
    UnloadArena() -- Clean up the arena IPL
    SetEntityCoords(ped, returnCoord)
    Wait(200)
    FreezeEntityPosition(ped, false)
end

-- Command Registrations
RegisterCommand('resetscreenshot', function()
    LocalPlayer.state.screenshotnum = 1
    SetResourceKvpInt('screenshotnum', LocalPlayer.state.screenshotnum)
end)

RegisterCommand('getmodelimage', function(_, args)
    if args[1] then
        print(exports.renzu_vehthumb:GetModelImage(args[1]))
    end
end)

RegisterCommand('startscreenshot', function()
    if not screenshot then
        StartScreenShoting()
    end
    screenshot = not screenshot
end)

-- Main Thread
CreateThread(function()
    Wait(500)

    -- Wait for screenshot permissions with timeout
    local attempts = 0
    while not LocalPlayer.state.screenshotperms and attempts < 30 do
        attempts = attempts + 1
        Wait(1000)
    end

    if not LocalPlayer.state.screenshotperms then
        print("No screenshot permissions after 30 seconds")
        return
    end

    print("PERMS GRANTED")
    LocalPlayer.state.screenshotnum = GetResourceKvpInt('screenshotnum') or 1
end)
