LOG_INFO('[CruzerRP][Client] main.lua initialized.')

require("client.ui")
require("client.events")

function onResourceStart()
    LOG_INFO('[CruzerRP][Client] Resource started')
end

function onResourceStop()
    LOG_INFO('[CruzerRP][Client] Resource stopped')
end
