Config = {}

-- Configuração do Webhook do Discord
Config.DiscordWebHook = 'XXXXXXXXXXXX'

-- Configuração de Armazenamento de Dados
Config.Storage = {
    method = 'json', -- Opções: 'json', 'kvp'
    vehicleTable = 'vehicles' -- Nome da tabela no banco de dados (deve ter a coluna 'model')
}

-- Configuração da Fonte de Dados dos Veículos
Config.VehicleSource = { 
    useQbox = true,
    useSQL = false, -- Usar MySQL async para buscar veículos
    fallbackTable = QBCore and QBCore.Shared and QBCore.Shared.Vehicles or {} -- Tabela de veículos alternativa (fallback)
}

Config.EnableExtraVehicles = true
Config.ExtraVehicles = {
    -- Exemplo: { model = 'nome_de_spawn', name = 'Nome', category = 'classe' },
    { model = 't20', name = 'Progen T20', category = 'super' },
    { model = 'adder', name = 'Adder', category = 'super' },
    { model = 'sultanrs', name = 'Sultan RS', category = 'sports' },
}

-- Configuração de Filtragem de Veículos
Config.Filtering = {
    category = 'none' -- defina como 'all' (todos) ou 'none' (nenhum) caso você queira usar apenas Config.ExtraVehicles
}

-- Configuração de Permissões
Config.Permissions = {
    owners = {
        ['license:XXXXXXXX'] = true,
        -- Adicione mais identificadores de licença aqui:
        -- ['license:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'] = true,
    }
}

-- Opcional: Configurações específicas por categoria (se não estiver usando 'all')
-- Config.Filtering.categories = {
--    'compacts',    -- compactos
--    'sedans',      -- sedãs
--    'suvs',        -- suvs
--    'coupes',      -- cupês
--    'muscle',      -- muscle / antigos potentes
--    'sports',      -- esportivos
--    'super',       -- super carros
--    'motorcycles', -- motocicletas
--    'offroad',     -- offroad / trilha
--    'industrial',  -- industriais
--    'utility',     -- utilitários
--    'vans',        -- vans
--    'cycles',      -- bicicletas
--    'boats',       -- barcos
--    'helicopters', -- helicópteros
--    'planes',      -- aviões
--    'service',     -- serviço
--    'emergency',   -- emergência
--    'military',    -- militar
--    'commercial',  -- comercial
--    'trains'       -- trens
-- }
