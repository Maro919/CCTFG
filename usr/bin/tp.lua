local list = require("/usr/lib/list")
local display = {}
local destinations = {}
local idMap = {}
local nameMap = {}
local names = {}

local name
local port
local interface

local scale = 1

function display:init(parent)
    local w, h = parent.getSize()
    parent.setCursorPos(1, 1)
    parent.setTextColor(colors.yellow)
    parent.setBackgroundColor(colors.blue)
    parent.clearLine()
    parent.write(name)
    parent.setCursorPos(w - 7, 1)
    parent.setBackgroundColor(colors.red)
    parent.write(" RELOAD ")
    parent.setTextColor(colors.white)
    parent.setBackgroundColor(colors.black)
    self.displayList = list:create(parent, 1, 2, w, h - 1)
    self.displayList:render()
end

function display:draw()
    self.displayList:draw()
end

function display:update(names)
    self.displayList:edit(names)
    self.displayList:render()
end

local function pulseRedstone()
    rs.setOutput("bottom", true)
    os.sleep(0)
    rs.setOutput("bottom", false)
    os.sleep(0)
end

local function convertDestinations()
    idMap = {}
    nameMap = {}
    names = {}
    for k, v in pairs(destinations) do
        table.insert(idMap, k)
        table.insert(nameMap, v)
        table.insert(names, k .. " - " .. v)
    end
end

local function handleInput()
    --[[ Trigger for refresh timer ]]--
    local timer = os.startTimer(0)
    while true do
        local event, p1, p2, p3 = os.pullEvent()
        if event == "mouse_click" then
            local index = display.displayList:click(p2, p3)
            if index and rednet.lookup("tp", nameMap[index]) then
                --[[ To be improved ]]--
                pulseRedstone()
                pulseRedstone()
                rednet.send(idMap[index], nil, "tp")
                if interface and port then
                    port.pushItems(peripheral.getName(interface), 2)
                end
            elseif p3 == 1 then
                destinations = {}
                convertDestinations()
                display:update(names)
                timer = os.startTimer(0)
            end
        elseif event == "monitor_touch" then
            os.queueEvent("mouse_click", 1, p2, p3)
        elseif event == "mouse_scroll" then
            display.displayList:scroll(p1)
        elseif event == "rednet_message" then
            local sid, msg, prot = p1, p2, p3
            if prot == "tp" then
                --[[ Future hook for better tp ]]--
                sleep(2)
                pulseRedstone()
                pulseRedstone()
                if interface and port then
                    port.pushItems(peripheral.getName(interface), 2)
                end
            elseif prot == "dns" then
                if type(msg) == "table" and msg.sType == "lookup response" and msg.sProtocol == "tp" and type(msg.sHostname) == "string" then
                    destinations[sid] = msg.sHostname
                    convertDestinations()
                    display:update(names)
                end
            end
        elseif event == "timer" then
            if p1 == timer then
                --[[ Periodically check available teleporters ]]--
                rednet.broadcast({
                    sType = "lookup",
                    sProtocol = "tp",
                }, "dns")
                --timer = os.startTimer(120)
                timer = nil
            end
        end
        display:draw()
    end
end

local function main()
    local modem = peripheral.find("modem", function(name, modem)
        rednet.open(name)
        return modem
    end)
    if not modem then
        error("Modem not found.", 3)
    end

    port = peripheral.find("ae2:spatial_io_port")
    interface = peripheral.find("ae2:interface")

    if port then
        --[[ Return cell to system at startup ]]--
        if next(port.list()) == 1 then
            pulseRedstone()
        end
        if interface then
            port.pushItems(peripheral.getName(interface), 2)
        end

        --[[ Setup teleport name ]]--
        name = settings.get("tp.name")
        if not name or type(name) ~= "string" then
            error("Teleport name not configured.", 3)
        end
        rednet.host("tp", name)

        --[[ Announce presence ]]--
        rednet.broadcast({
            sType = "lookup response",
            sProtocol = "tp",
            sHostname = name,
        }, "dns")
    else
        name = "Teleport Remote"
    end

    local monitor = peripheral.find("monitor")
    if monitor then
        monitor.setTextScale(scale)
        display:init(monitor)
    else
        display:init(term.current())
    end

    --destinations[os.getComputerID()] = name
    convertDestinations()
    display:update(names)

    --[[ Future hook for secure connection daemon ]]--
    parallel.waitForAny(handleInput)
end

main()
