local list = {}

-- Create new list object
function list:create(parent, nX, nY, nWidth, nHeight, bStartVisible)
    local win = window.create(parent, nX, nY, nWidth, nHeight, bStartVisible)
    local lst = window.create(win, 1, 1, nWidth-1, 0, true)
    local o = {
        win = win,
        lst = lst,
        scr = 0,
        elements = {},
    }
    setmetatable(o, {__index = self})
    return o
end

-- Draw scroll bar
local function drawScrollBar(self)
    local w, h = self.win.getSize()
    local pos = math.min(math.floor((self.scr / (#self.elements-1)) * (h - 2)) + 2, h-1);
    if #self.elements == 0 then
        pos = 2
    end
    self.win.setCursorPos(w, 1)
    self.win.write(string.char(24))
    self.win.setCursorPos(w, h)
    self.win.write(string.char(25))
    for i = 2, h-1 do
        self.win.setCursorPos(w, i)
        if i == pos then
            self.win.write(string.char(8))
        else
            self.win.write(string.char(127))
        end
    end
end

-- Render list
function list:render()
    local w, h = self.lst.getSize()
    self.win.clear()
    self.lst.reposition(1, 1-self.scr, w, #self.elements)
    drawScrollBar(self)
    for i = 1, #self.elements do
        self.lst.setCursorPos(1, i)
        if i%2 == 0 then
            self.lst.setBackgroundColor(colors.lightGray)
        else
            self.lst.setBackgroundColor(colors.gray)
        end
        self.lst.clearLine()
        self.lst.write(self.elements[i])
    end
end

-- Draw list
function list:draw()
    local w, h = self.lst.getSize()
    self.win.clear()
    self.lst.reposition(1, 1-self.scr, w, #self.elements)
    drawScrollBar(self)
end

function list:edit(elements)
    self.elements = elements
    self:render()
end

function list:scroll(scroll)
    self.scr = self.scr + scroll
    if self.scr < 0 then
        self.scr = 0
    elseif self.scr >= #self.elements then
        self.scr = #self.elements - 1
    end
end

function list:click(nX, nY)
    local x, y = self.win.getPosition()
    local w, h = self.win.getSize()

    -- Check if window was clicked
    if nX < x or nX >= x + w or nY < y or nY >= y + h then
        return nil
    end

    -- Calculate offset
    x, y = nX - x + 1, nY - y + 1
    if x == w and y == 1 then
        self:scroll(-1)
    elseif x == w and y == h then
        self:scroll(1)
    elseif x < w and y + self.scr <= #self.elements then
        return y + self.scr
    end
end

return list
