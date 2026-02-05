LOG_INFO('[ColonyRP][Client] main.lua initialized.')

require("shared.config")
require("client.ui")
require("client.events")
require("client.visuals")

function onResourceStart()
    LOG_INFO('[ColonyRP][Client] Resource started')
end

function onResourceStop()
    LOG_INFO('[ColonyRP][Client] Resource stopped')
end