local resultVehicles = {}
local thumbs = {}

local hasQbox = GetResourceState('qbx_core') == 'started'

local CONFIG = {
    save = (Config.Storage and Config.Storage.method) or 'kvp',
    useQbox = (Config.VehicleSource and Config.VehicleSource.useQbox) or hasQbox,
    useSQLvehicle = (Config.VehicleSource and Config.VehicleSource.useSQL) or false,
    vehicle_table = (Config.Storage and Config.Storage.vehicleTable) or 'vehicles',
    Category = (Config.Filtering and Config.Filtering.category) or 'all',
    SqlVehicleTable = (Config.VehicleSource and Config.VehicleSource.fallbackTable) or {},
    owners = (Config.Permissions and Config.Permissions.owners) or {}
}

local function HasPermission(source)
    for i = 0, GetNumPlayerIdentifiers(source) do
        local identifier = GetPlayerIdentifier(source, i)
        if identifier and CONFIG.owners[identifier] then
            return true
        end
    end
    return false
end

local function LoadThumbnails()
    if CONFIG.save == 'kvp' then
        return json.decode(GetResourceKvpString('thumbnails') or '[]') or {}
    else
        return json.decode(LoadResourceFile('vImageCreator', 'thumbnails.json') or '[]') or {}
    end
end

local function SaveThumbnails(thumbnails)
    if CONFIG.save == 'kvp' then
        SetResourceKvp('thumbnails', json.encode(thumbnails))
    else
        SaveResourceFile("vImageCreator", "thumbnails.json", json.encode(thumbnails), -1)
    end
end

local function LoadQboxVehicles()
    local qboxVehicles = {}

    local success, result = pcall(function()
        return exports.qbx_core:GetVehiclesByName()
    end)

    if not success or not result then
        print("^1[ERRO] Falha ao carregar exports.qbx_core:GetVehiclesByName(). Tentando GetVehiclesByCategory...^0")
        local success2, result2 = pcall(function() return exports.qbx_core:GetVehiclesByCategory() end)
        if success2 and result2 then
            result = {}
            for cat, list in pairs(result2) do
                for _, v in pairs(list) do
                    result[v.model] = v
                end
            end
        else
            print("^1[ERRO CRÍTICO] Não foi possível carregar veículos do Qbox via exports.^0")
            return {}
        end
    end

    for modelName, data in pairs(result) do
        table.insert(qboxVehicles, {
            model = modelName,
            name = data.name or data.brand .. ' ' .. modelName,
            category = data.category or 'unknown'
        })
    end

    print(("^2[SUCESSO] Carregados %d veículos do Qbox.^0"):format(#qboxVehicles))
    return qboxVehicles
end

local function LoadVehicles()
    local vehicles = {}

    if CONFIG.Category ~= 'none' then
        if CONFIG.useQbox then
            vehicles = LoadQboxVehicles()
        elseif CONFIG.useSQLvehicle then
            vehicles = MySQL.Sync.fetchAll('SELECT * FROM ' .. CONFIG.vehicle_table) or {}
        else
            vehicles = CONFIG.SqlVehicleTable or {}
        end
    else
        print("^3[Config] Modo 'none' detectado: Veículos do banco de dados desativados.^0")
    end

    if Config.EnableExtraVehicles and Config.ExtraVehicles and #Config.ExtraVehicles > 0 then
        print("^3[Config] Injetando " .. #Config.ExtraVehicles .. " veículos extras na lista...^0")

        for _, extra in ipairs(Config.ExtraVehicles) do
            table.insert(vehicles, {
                model = extra.model,
                name = extra.name or extra.model,
                category = extra.category or 'custom'
            })
        end
    elseif not Config.EnableExtraVehicles then
        print("^3[Config] Lista de veículos extras está DESATIVADA no config.^0")
    end

    return vehicles
end

local function FilterVehiclesByCategory(vehicles)
    if CONFIG.Category == 'all' or CONFIG.Category == 'none' then
        return vehicles
    end

    local filtered = {}
    for _, vehicle in ipairs(vehicles) do
        if vehicle.category == CONFIG.Category then
            filtered[#filtered + 1] = vehicle
        end
    end
    return filtered
end

local function NormalizeThumbnails(thumbnails)
    local normalized = {}
    local count = 0

    for modelHash, imageUrl in pairs(thumbnails) do
        normalized[tostring(modelHash)] = imageUrl
        count = count + 1
    end

    return normalized, count
end

-- Command Handlers
RegisterCommand('getperms', function(source)
    if not source or source == 0 then return end

    if HasPermission(source) then
        local playerState = Player(source).state
        playerState.screenshotperms = true

        print(("Player ID: %d Granted Permission to use Screenshot Vehicle\nCommands:\nStart Screen Shot Vehicle /startscreenshot\nReset screenshot index (last vehicle number for continuation purpose) /resetscreenshot"):format(source))
    end
end)

-- Event Handlers
RegisterNetEvent("renzu_vehthumb:save", function(data)
    if not data or not data.model then return end

    local modelHash = tostring(GetHashKey(data.model))
    thumbs[modelHash] = data.img

    SaveThumbnails(thumbs)
    GlobalState.VehicleImages = thumbs

    print(("Vehicle thumbnail saved for model: %s"):format(data.model))
end)

-- Initialization
CreateThread(function()
    Wait(1000)

    thumbs = LoadThumbnails()
    resultVehicles = LoadVehicles()

    local filteredVehicles = FilterVehiclesByCategory(resultVehicles)
    GlobalState.VehiclesFromDB = filteredVehicles

    local normalizedThumbs, thumbCount = NormalizeThumbnails(thumbs)
    GlobalState.VehicleImages = normalizedThumbs

    print(("Initialization complete - %d vehicles loaded, %d thumbnails cached"):format(#filteredVehicles, thumbCount))
end)

RegisterNetEvent('renzu_vehthumb:save_local', function(model, url)
    if not model or not url then return end

    TriggerEvent('renzu_vehthumb:download_js', model, url)
end)
