--
-- Copyright (C) 2020 G4meMas0n
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program. If not, see <https://www.gnu.org/licenses/>.
--

--- Colors decimal to hexadecimal code conversion table.
local hex = {
    [ colors.white ] = "0",
    [ colors.orange ] = "1",
    [ colors.magenta ] = "2",
    [ colors.lightBlue ] = "3",
    [ colors.yellow ] = "4",
    [ colors.lime ] = "5",
    [ colors.pink ] = "6",
    [ colors.gray ] = "7",
    [ colors.lightGray ] = "8",
    [ colors.cyan ] = "9",
    [ colors.purple ] = "a",
    [ colors.blue ] = "b",
    [ colors.brown ] = "c",
    [ colors.green ] = "d",
    [ colors.red ] = "e",
    [ colors.black ] = "f",
}

--- Default settings for this window table object.
local defaults = {
    ["title"] = "",
    ["pos-x"] = 1,
    ["pos-y"] = 1,
    ["width"] = 0,
    ["height"] = 0,
    ["offset"] = 3,
    ["padding-x"] = 0,
    ["padding-y"] = 0,
    ["color"] = {
        ["text"] = "0",
        ["background"] = "f",
        ["border"] = "7"
    },
    ["visible"] = false
}

--- Checks for two objects if there are equal.
--- @param first boolean|number|string|table the first object for the comparison.
--- @param second boolean|number|string|table the second object for the comparison.
--- @return boolean true if both objects are equal, false otherwise.
local function equal(first, second)
    if type(first) == type(second) then
        if type(first) == "table" and type(second) == "table" then
            for key, value in pairs(first) do
                if second[key] == nil or not equal(value, second[key]) then
                    return false
                end
            end

            for key, value in pairs(second) do
                if first[key] == nil or not equal(value, first[key]) then
                    return false
                end
            end

            return true
        end

        return first == second
    end

    return false
end

--- Creates a new Window table object.
--- @param terminal table the parent terminal or monitor.
--- @param x        nil|number the x position of the window.
--- @param y        nil|number the y position of the window.
--- @param width    nil|number the width of the window.
--- @param height   nil|number the height of the window.
--- @param title    nil|string the title of this window.
--- @return table the created window table.
function create(terminal, x, y, width, height, title)
    -- Check all parameter types before initializing window table:
    if type(terminal) ~= "table" then
        error("bad argument #1 (expected table, got " .. type(terminal) .. ")", 2)
    end

    if x ~= nil and type(x) ~= "number" then
        error("bad argument #2 (expected number, got " .. type(x) .. ")", 2)
    end

    if y ~= nil and type(y) ~= "number" then
        error("bad argument #3 (expected number, got " .. type(y) .. ")", 2)
    end

    if width ~= nil and type(width) ~= "number" then
        error("bad argument #4 (expected number, got " .. type(width) .. ")", 2)
    end

    if height ~= nil and type(height) ~= "number" then
        error("bad argument #5 (expected number, got " .. type(height) .. ")", 2)
    end

    if title ~= nil and type(title) ~= "string" then
        error("bad argument #6 (expected string, got " .. type(title) .. ")", 2)
    end

    -- Check all parameter conditions before initializing window table:
    if not terminal.isColor() then
        error("bad argument #1 (expected color supported terminal)", 2)
    end

    local maxWidth, maxHeight = terminal.getSize()
    local wPosX = defaults["pos-x"]
    local wPosY = defaults["pos-y"]

    if x ~= nil or y ~= nil then
        -- Check if both x and y position is given:
        if x ~= nil and y ~= nil then
            -- Check correctness of positions:
            if x < 1 or x > maxWidth then
                error("bad argument #2 (expected position between 1 and " .. maxWidth .. ", got " .. x .. ")", 2)
            end

            if y < 1 or y > maxHeight then
                error("bad argument #3 (expected position between 1 and " .. maxHeight .. ", got " .. y .. ")", 2)
            end

            wPosX = x
            wPosY = y
        else
            error("bad arguments #2 #3 (expected number and number, got " .. type(x) .. " and " .. type(y) .. ")", 2)
        end
    end

    local wWidth = defaults["width"]
    local wHeight = defaults["height"]

    if width ~= nil or height ~= nil then
        -- Check if both width and height is given:
        if width ~= nil and height ~= nil then
            -- Check correctness of width and height:
            if width < 0 or width > maxWidth - (wPosX - 1) then
                error("bad argument #4 (expected width between 0 and " .. (maxWidth - (wPosX - 1)) .. ", got " .. width .. ")", 2)
            end

            if height < 0 or height > maxHeight - (wPosY - 1) then
                error("bad argument #5 (expected height between 0 and " .. (maxHeight - (wPosY - 1)) .. ", got " .. height .. ")", 2)
            end

            wWidth = width
            wHeight = height
        else
            error("bad arguments #4 #5 (expected number and number, got " .. type(width) .. " and " .. type(height) .. ")", 2)
        end
    end

    local wOffset = defaults["offset"]
    local wTitle = defaults["title"]

    if title ~= nil then
        -- Check correctness of title:
        if string.len(title) + wOffset * 2 > wWidth then
            error("bad argument #6 (expected title length between 0 and " .. math.max(0, wWidth - wOffset * 2) .. ", got " .. string.len(title) .. ")", 2)
        end

        wTitle = title
    end

    local wTerm = terminal

    local wColor = defaults["color"]

    local wPaddingX = defaults["padding-x"]
    local wPaddingY = defaults["padding-y"]

    local wVisible = defaults["visible"]

    local wCursorX = 1
    local wCursorY = 1

    local wLines = {}
    local wBorder = {}

    local wConfig

    --- Generates the border lines and writes it in the borders line cache.
    local function generate()
        -- Only generate when the full border not exist or the width not equals the window width:
        if wBorder["full"] == nil or string.len(wBorder["full"].text) ~= wWidth then
            wBorder["full"] = {
                ["text"] = string.rep(" ", wWidth),
                ["color"] = string.rep(wColor["text"], wWidth),
                ["background"] = string.rep(wColor["border"], wWidth)
            }
        end

        -- Only generate when the empty border not exist or the width not equals the window width:
        if wBorder["empty"] == nil or string.len(wBorder["empty"].text) ~= wWidth then
            -- Only generate empty border line when the window width is greater than two:
            if wWidth > 2 then
                wBorder["empty"] = {
                    ["text"] = string.rep(" ", wWidth),
                    ["color"] = string.rep(wColor["text"], wWidth),
                    ["background"] = wColor["border"] .. string.rep(wColor["background"], wWidth - 2) .. wColor["border"]
                }
            else
                wBorder["empty"] = wBorder["full"]
            end
        end

        -- Only generate title border line when the title length is greater than zero:
        if string.len(wTitle) > 0 then
            local length = string.len(wTitle)
            local ceil = math.ceil(wOffset / 2)
            local floor = math.floor(wOffset / 2) * 2

            wBorder["title"] = {
                ["text"] = string.rep(" ", wOffset) .. wTitle .. string.rep(" ", wWidth - length - wOffset),
                ["color"] = string.rep(wColor["text"], wWidth),
                ["background"] = string.rep(wColor["border"], ceil) .. string.rep(wColor["background"], length + floor) .. string.rep(wColor["border"], wWidth - ceil - length - floor)
            }
        else
            wBorder["title"] = wBorder["full"]
        end
    end

    --- Clears lines of this window screen (with border) of the terminal.
    local function clear(line)
        -- Cache cleared lines before writing it to the terminal:
        local text = string.rep(" ", wWidth)
        local color = string.rep(hex[wTerm.getTextColor()], wWidth)
        local back = string.rep(hex[wTerm.getBackgroundColor()], wWidth)

        -- Cache old cursor position of terminal
        local oldX, oldY = wTerm.getCursorPos()

        if line == nil then
            for lines = 1, wHeight do
                wTerm.setCursorPos(wPosX, wPosY + (lines - 1))
                wTerm.blit(text, color, back)
            end
        else
            wTerm.setCursorPos(wPosX, wPosY + (line - 1))
            wTerm.blit(text, color, back)
        end

        wTerm.setCursorPos(oldX, oldY)
    end

    --- Draws lines of this window screen (with border) to the terminal.
    local function draw(line)
        -- Only draw window to the terminal when it is visible:
        if wVisible then
            -- Check if line is specified. If true draw specified line, otherwise draw all lines:
            if line ~= nil then
                if wBorder["full"] == nil or wBorder["empty"] == nil or wBorder["title"] == nil then
                    generate()
                end

                local oldX, oldY = wTerm.getCursorPos()

                wTerm.setCursorPos(wPosX, wPosY + (line - 1))

                if line == 1 then
                    wTerm.blit(wBorder["title"].text, wBorder["title"].color, wBorder["title"].background)
                elseif line == wHeight then
                    wTerm.blit(wBorder["full"].text, wBorder["full"].color, wBorder["full"].background)
                else
                    wTerm.blit(wBorder["empty"].text, wBorder["empty"].color, wBorder["empty"].background)

                    if line > wPaddingY + 1 and line < wHeight - wPaddingY then
                        local content = line - 1 - wPaddingY

                        if wLines[content] ~= nil then
                            wTerm.setCursorPos(wPosX + 1 + wPaddingX, wPosY + (line - 1))
                            wTerm.blit(wLines[content].text, wLines[content].color, wLines[content].background)
                        end
                    end
                end

                wTerm.setCursorPos(oldX, oldY)
            else
                for lines = 1, wHeight do
                    draw(lines)
                end
            end
        end
    end

    --- Empties lines of this window screen (without border).
    local function empty(line)
        local length = (wHeight - 2) - (wPaddingY * 2)

        -- Cache cleared lines before writing it in the lines cache:
        local text = string.rep(" ", length)
        local color = string.rep(wColor["text"], length)
        local background = string.rep(wColor["background"], length)

        if line == nil then
            for lines = 1, length do
                wLines[lines] = {
                    ["text"] = text,
                    ["color"] = color,
                    ["background"] = background
                }
            end
        else
            wLines[line] = {
                ["text"] = text,
                ["color"] = color,
                ["background"] = background
            }
        end
    end

    --- Writes text in this window (without border) at the current cursor position.
    local function blit(text, color, background)
        local start = wCursorX
        local stop = start + string.len(text) - 1
        local range = (wWidth - 2) - (wPaddingX * 2)

        if wCursorY >= 1 and wCursorY <= (wHeight - 2) - (wPaddingY * 2) then
            if start <= range and stop >= 1 and stop > start then
                if wLines[wCursorY] == nil then
                    empty(wCursorY)
                end

                local line = wLines[wCursorY]

                if start < 1 then
                    local begin = 1 - start + 1

                    text = string.sub(text, begin)
                    color = string.sub(color, begin)
                    background = string.sub(background, begin)
                    start = 1
                end

                if stop > range then
                    local ending = range - start + 1

                    text = string.sub(text, 1, ending)
                    color = string.sub(color, 1, ending)
                    background = string.sub(background, 1, ending)
                    stop = range
                end

                if start > 1 then
                    text = string.sub(line.text, 1, start - 1) .. text
                    color = string.sub(line.color, 1, start - 1) .. color
                    background = string.sub(line.background, 1, start - 1) .. background
                end

                if stop < range then
                    text = text .. string.sub(line.text, stop + 1)
                    color = color .. string.sub(line.color, stop + 1)
                    background = background .. string.sub(line.background, stop + 1)
                end

                wCursorX = stop + 1
                wLines[wCursorY] = {
                    ["text"] = text,
                    ["color"] = color,
                    ["background"] = background
                }

                draw(wCursorY + 1 + wPaddingY)
            end
        end
    end

    --- Recolors the content of this window.
    local function recolor(color, background)
        -- Iterate for each line and replace the old colors with the new colors:
        for line = 1, (wHeight - 2) - (wPaddingY * 2) do
            local cache = wLines[line]

            -- Only replace colors if line exists:
            if cache ~= nil then
                if color ~= nil then
                    cache.color = string.gsub(cache.color, wColor["text"], hex[color])
                end

                if background ~= nil then
                    cache.background = string.gsub(cache.background, wColor["background"], hex[background])
                end

                wLines[line] = {
                    ["text"] = cache.text,
                    ["color"] = cache.color,
                    ["background"] = cache.background
                }
            end
        end
    end

    --- Resizes the content of this window.
    local function resize()
        local length = (wWidth - 2) - (wPaddingX * 2)
        local lines = {}

        for line = 1, (wHeight - 2) - (wPaddingY * 2) do
            local old = wLines[line]

            if old ~= nil then
                local oldLength = string.len(old.text)

                if oldLength > length then
                    lines[line] = {
                        ["text"] = string.sub(old.text, 1, length),
                        ["color"] = string.sub(old.color, 1, length),
                        ["background"] = string.sub(old.background, 1 , length)
                    }
                elseif oldLength < length then
                    lines[line] = {
                        ["text"] = old.text .. string.rep(" ", length - oldLength),
                        ["color"] = old.color .. string.rep(wColor["text"], length - oldLength),
                        ["background"] = old.background .. string.rep(wColor["background"], length - oldLength)
                    }
                else
                    lines[line] = old
                end
            else
                lines[line] = {
                    ["text"] = string.rep(" ", length),
                    ["color"] = string.rep(wColor["text"], length),
                    ["background"] = string.rep(wColor["background"], length)
                }
            end
        end

        wLines = lines
    end

    --- Updates the specified config option of this Window.
    local function update(key, value)
        if wConfig ~= nil then
            local old = wConfig.get(key)

            if old == nil or not equal(old, value) then
                wConfig.set(key, value)
                wConfig.save()
            end
        end
    end

    -- Start of window table implementation:
    local Window = {}

    --- Gets the name of this window.
    --- @return string the name of this window or an empty string.
    function Window.getTitle()
        return wTitle
    end

    --- Sets the name of this window.
    --- @param new string the new name for this window.
    --- @return boolean true when the title was changed, false otherwise.
    function Window.setTitle(new)
        if type(new) ~= "string" then
            error("bad argument #1 (expected string, got " .. type(new) .. ")", 2)
        end

        local length = string.len(new)

        if length > 0 and length + (wOffset * 2) > wWidth then
            error("bad argument #1 (expected title length between 0 and " .. math.max(0, wWidth - wOffset * 2) .. ", got " .. length .. ")", 2)
        end

        if new ~= wTitle then
            wTitle = new
            generate()
            draw(1)
            update("title", wTitle)

            return true
        end

        return false
    end

    --- Gets the title offset of this window.
    --- @return number the title offset of this window.
    function Window.getOffset()
        return wOffset
    end

    --- Sets the title offset of this window.
    --- @param offset number the new title offset for this window.
    --- @return boolean true when the title offset was changed, false otherwise.
    function Window.setOffset(offset)
        if type(offset) ~= "number" then
            error("bad argument #1 (expected number, got " .. type(offset) .. ")", 2)
        end

        if offset < 0 or offset * 2 > wWidth then
            error("bad argument #1 (expected offset between 0 and " .. math.floor(wWidth / 2) .. ", got " .. offset .. ")", 2)
        end

        if string.len(wTitle) > 0 and (offset < 2 or offset * 2 > wWidth - string.len(wTitle)) then
            error("bad argument #1 (expected offset between 2 and " .. math.max(2, math.floor(wWidth - string.len(wTitle) / 2)) .. ", got " .. offset .. ")", 2)
        end

        if offset ~= wOffset then
            wOffset = offset
            generate()
            draw()
            update("offset", wOffset)

            return true
        end

        return false
    end

    --- Gets the position of this window (in the terminal).
    --- @return number, number the x and y position of this window.
    function Window.getPosition()
        return wPosX, wPosY
    end

    --- Gets the x position of this window.
    --- @return number the x position of this window.
    function Window.getPosX()
        return wPosX
    end

    --- Sets the x position of this window.
    --- @param position number the new x position for this window.
    --- @return boolean true when the x position was changed, false otherwise.
    function Window.setPosX(position)
        if type(position) ~= "number" then
            error("bad argument #1 (expected number, got " .. type(position) .. ")", 2)
        end

        maxWidth, maxHeight = wTerm.getSize()

        if position < 1 or position > maxWidth - wWidth then
            error("bad argument #2 (expected position between 1 and " .. maxWidth - wWidth .. ", got " .. position .. ")", 2)
        end

        if position ~= wPosX then
            clear()
            wPosX = position
            draw()
            update("pos-x", wPosX)

            return true
        end

        return false
    end

    --- Gets the y position of this window.
    --- @return number the y position of this window.
    function Window.getPosY()
        return wPosY
    end

    --- Sets the y position of this window.
    --- @param position number the new y position for this window.
    --- @return boolean true when the y position was changed, false otherwise.
    function Window.setPosY(position)
        if type(position) ~= "number" then
            error("bad argument #1 (expected number, got " .. type(position) .. ")", 2)
        end

        maxWidth, maxHeight = wTerm.getSize()

        if position < 1 or position > maxHeight - wHeight then
            error("bad argument #2 (expected position between 1 and " .. maxHeight - wHeight .. ", got " .. position .. ")", 2)
        end

        if position ~= wPosY then
            clear()
            wPosY = position
            draw()
            update("pos-y", wPosY)

            return true
        end

        return false
    end

    --- Gets the size of this window (without border).
    --- @return number, number the width and the height of this window.
    function Window.getSize()
        return (wWidth - 2) - (wPaddingX * 2), (wHeight - 2) - (wPaddingY * 2)
    end

    --- Gets the width of this window.
    --- @return number the width of this window or zero.
    function Window.getWidth()
        return wWidth
    end

    --- Sets the width of this window.
    --- @param new number the new width for this window.
    --- @return boolean true when the width was changed, false otherwise.
    function Window.setWidth(new)
        if type(new) ~= "number" then
            error("bad argument #1 (expected number, got " .. type(new) .. ")", 2)
        end

        maxWidth, maxHeight = wTerm.getSize()

        if new > 0 and new > maxWidth - (wPosX - 1) then
            error("bad argument #1 (expected width between 0 and " .. (maxWidth - (wPosX - 1)) .. ", got " .. new .. ")", 2)
        end

        if new > 0 and string.len(wTitle) > 0 and new < string.len(wTitle) + (wOffset * 2) then
            error("bad argument #1 (expected width between " .. (string.len(wTitle) + (wOffset * 2)) .. " and " .. (maxWidth - (wPosX - 1)) .. ", got " .. new .. ")", 2)
        end

        if new < 0 then
            new = 0
        end

        if new ~= wWidth then
            clear()
            wWidth = new
            generate()
            resize()
            draw()
            update("width", wWidth)

            return true
        end

        return false
    end

    --- Gets the height of this window.
    --- @return number the height of this window or zero.
    function Window.getHeight()
        return wHeight
    end

    --- Sets the height of this window.
    --- @param new number the new height for this window.
    --- @return boolean true when the height was changed, false otherwise.
    function Window.setHeight(new)
        if type(new) ~= "number" then
            error("bad argument #1 (expected number, got " .. type(new) .. ")", 2)
        end

        maxWidth, maxHeight = wTerm.getSize()

        if new > 0 and new > maxHeight - (wPosY - 1) then
            error("bad argument #1 (expected height between 0 and " .. (maxHeight - (wPosX - 1)) .. ", got " .. new .. ")", 2)
        end

        if new < 0 then
            new = 0
        end

        if new ~= wHeight then
            clear()
            wHeight = new
            generate()
            resize()
            draw()
            update("height", wHeight)

            return true
        end

        return false
    end

    --- Gets the x padding of this window.
    --- @return number the x padding of this window.
    function Window.getPaddingX()
        return wPaddingX
    end

    --- Sets the x padding of this window.
    --- @param padding number the new x padding for this window.
    --- @return boolean true when the x padding was changed, false otherwise.
    function Window.setPaddingX(padding)
        if type(padding) ~= "number" then
            error("bad argument #1 (expected number, got " .. type(padding) .. ")", 2)
        end

        if padding < 0 or padding * 2 > math.max(0, wWidth - 2) then
            error("bad argument #1 (expected padding between 0 and " .. math.max(0, math.floor((wWidth - 2) / 2)) .. ", got " .. padding .. ")", 2)
        end

        if padding ~= wPaddingX then
            clear()
            wPaddingX = padding
            resize()
            draw()
            update("padding-x", wPaddingX)

            return true
        end

        return false
    end

    --- Gets the y padding of this window.
    --- @return number the y padding of this window.
    function Window.getPaddingY()
        return wPaddingY
    end

    --- Sets the y padding of this window.
    --- @param padding number the new y padding for this window.
    --- @return boolean true when the y padding was changed, false otherwise.
    function Window.setPaddingY(padding)
        if type(padding) ~= "number" then
            error("bad argument #1 (expected number, got " .. type(padding) .. ")", 2)
        end

        if padding < 0 or padding * 2 > math.max(0, wHeight - 2) then
            error("bad argument #1 (expected padding between 0 and " .. math.max(0, math.floor((wHeight - 2) / 2)) .. ", got " .. padding .. ")", 2)
        end

        if padding ~= wPaddingY then
            clear()
            wPaddingY = padding
            resize()
            draw()
            update("padding-y", wPaddingY)

            return true
        end

        return false
    end

    --- Gets the text color of this window.
    --- @return number the color code of the text color.
    function Window.getTextColor()
        return 2 ^ tonumber(wColor["text"], 16)
    end

    --- Sets the text color of this window.
    --- @param color number|string the color code or hex value of the new text color.
    --- @return boolean true when the text color was changed, false otherwise.
    function Window.setTextColor(color)
        if type(color) ~= "number" and type(color) ~= "string" then
            error("bad argument #1 (expected number or string, got " .. type(color) .. ")", 2)
        end

        if type(color) == "string" then
            color = 2 ^ tonumber(color, 16)
        end

        if hex[color] == nil then
            error("bad argument #1 (expected color code, got " .. color .. ")", 2)
        end

        if hex[color] ~= wColor["text"] then
            recolor(color, nil)
            wColor["text"] = hex[color]
            generate()
            draw()
            update("color", wColor)

            return true
        end

        return false
    end

    --- Gets the background color of this window.
    --- @return number the color code of the background color.
    function Window.getBackgroundColor()
        return 2 ^ tonumber(wColor["background"], 16)
    end

    --- Sets the background color of this window.
    --- @param color number|string the color code or hex value of the new background color.
    --- @return boolean true when the background color was changed, false otherwise.
    function Window.setBackgroundColor(color)
        if type(color) ~= "number" and type(color) ~= "string" then
            error("bad argument #1 (expected number or string, got " .. type(color) .. ")", 2)
        end

        if type(color) == "string" then
            color = 2 ^ tonumber(color, 16)
        end

        if hex[color] == nil then
            error("bad argument #1 (expected color code, got " .. color .. ")", 2)
        end

        if hex[color] ~= wColor["background"] then
            recolor(nil, color)
            wColor["background"] = hex[color]
            generate()
            draw()
            update("color", wColor)

            return true
        end

        return false
    end

    --- Gets the border color of this window.
    --- @return number the color code of the border color.
    function Window.getBorderColor()
        return 2 ^ tonumber(wColor["border"], 16)
    end

    --- Sets the border color of this window.
    --- @param color number|string the color code or hex value of the new border color.
    --- @return boolean true when the border color was changed, false otherwise.
    function Window.setBorderColor(color)
        if type(color) ~= "number" and type(color) ~= "string" then
            error("bad argument #1 (expected number or string, got " .. type(color) .. ")", 2)
        end

        if type(color) == "string" then
            color = 2 ^ tonumber(color, 16)
        end

        if hex[color] == nil then
            error("bad argument #1 (expected color code, got " .. color .. ")", 2)
        end

        if hex[color] ~= wColor["border"] then
            wColor["border"] = hex[color]
            generate()
            draw()
            update("color", wColor)

            return true
        end

        return false
    end

    --- Gets whether this window is visible.
    --- @return boolean true when this window is visible, false otherwise.
    function Window.getVisible()
        return wVisible
    end

    --- Sets whether this window is visible.
    --- @param visible boolean whether this window should be visible.
    --- @return boolean true when the visibility was changed, false otherwise.
    function Window.setVisible(visible)
        if type(visible) ~= "boolean" then
            error("bad argument #1 (expected boolean, got " .. type(visible) .. ")", 2)
        end

        if visible and not wVisible then
            wVisible = true
            draw()
        elseif not visible and wVisible then
            wVisible = false
            clear()
        else
            return false
        end

        update("visible", wVisible)
        return true
    end

    --- Loads this window from the configuration file at the specified path.
    --- @param path string the path to the configuration file.
    --- @return boolean true when the configuration was loaded, false otherwise.
    function Window.load(path)
        if path ~= nil and type(path) ~= "string" then
            error("bad argument #1 (expected string, got " .. type(path) .. ")", 2)
        end

        if path == nil and wConfig == nil then
            error("bad argument #1 (expected path, got nil)", 2)
        end

        if path ~= nil and (wConfig == nil or wConfig.path() ~= path) then
            wConfig = Configuration.create(path)
        end

        if wConfig.load() then
            if wConfig.contains("pos-x") then
                Window.setPosX(wConfig.get("pos-x"))
            end

            if wConfig.contains("pos-y") then
                Window.setPosY(wConfig.get("pos-y"))
            end

            if wConfig.contains("width") then
                Window.setWidth(wConfig.get("width"))
            end

            if wConfig.contains("height") then
                Window.setHeight(wConfig.get("height"))
            end

            if wConfig.contains("offset") then
                Window.setOffset(wConfig.get("offset"))
            end

            if wConfig.contains("title") then
                Window.setTitle(wConfig.get("title"))
            end

            if wConfig.contains("padding-x") then
                Window.setPaddingX(wConfig.get("padding-x"))
            end

            if wConfig.contains("padding-y") then
                Window.setPaddingY(wConfig.get("padding-y"))
            end

            if wConfig.contains("color") then
                local color = wConfig.get("color")

                if type(color) ~= "table" then
                    error("bad argument #1 (expected color table, got " .. type(color) .. ")", 2)
                end

                if color["text"] ~= nil then
                    Window.setTextColor(color["text"])
                end

                if color["background"] ~= nil then
                    Window.setBackgroundColor(color["background"])
                end

                if color["border"] ~= nil then
                    Window.setBorderColor(color["border"])
                end
            end

            if wConfig.contains("visible") then
                Window.setVisible(wConfig.get("visible"))
            end

            return true
        end

        return false
    end

    --- Saves this window to the configuration file at the specified path.
    --- @param path string the path to the configuration file.
    --- @return boolean true when the configuration was saved, false otherwise.
    function Window.save(path)
        if path ~= nil and type(path) ~= "string" then
            error("bad argument #1 (expected string, got " .. type(path) .. ")", 2)
        end

        if path == nil and wConfig == nil then
            error("bad argument #1 (expected path, got nil)", 2)
        end

        if path ~= nil and (wConfig == nil or wConfig.path() ~= path) then
            wConfig = Configuration.create(path)

            if not equal(wTitle, defaults["title"]) then
                wConfig.set("title", wTitle)
            end

            if not equal(wPosX, defaults["pos-x"]) then
                wConfig.set("pos-x", wPosX)
            end

            if not equal(wPosY, defaults["pos-y"]) then
                wConfig.set("pos-y", wPosY)
            end

            if not equal(wWidth, defaults["width"]) then
                wConfig.set("width", wWidth)
            end

            if not equal(wHeight, defaults["height"]) then
                wConfig.set("height", wHeight)
            end

            if not equal(wOffset, defaults["offset"]) then
                wConfig.set("offset", wOffset)
            end

            if not equal(wPaddingX, defaults["padding-x"]) then
                wConfig.set("padding-x", wPaddingX)
            end

            if not equal(wPaddingY, defaults["padding-y"]) then
                wConfig.set("padding-y", wPaddingY)
            end

            if not equal(wColor, defaults["color"]) then
                wConfig.set("color", wColor)
            end

            if not equal(wVisible, defaults["visible"]) then
                wConfig.set("visible", wVisible)
            end
        end

        return wConfig.save()
    end

    --- Gets the current cursor position of this window.
    --- @return number, number the current position of the cursor.
    function Window.getCursorPos()
        return wCursorX, wCursorY
    end

    --- Sets the cursor position of this window.
    --- @param newX number the new x position for the cursor.
    --- @param newY number the new y position for the cursor.
    function Window.setCursorPos(newX, newY)
        if type(newX) ~= "number" then
            error("bad argument #1 (expected number, got " .. type(newX) .. ")", 2)
        end

        if type(newY) ~= "number" then
            error("bad argument #2 (expected number, got " .. type(newY) .. ")", 2)
        end

        newX = math.floor(newX)
        newY = math.floor(newY)

        if newX ~= wCursorX then
            wCursorX = newX
        end

        if newY ~= wCursorY then
            wCursorY = newY
        end
    end

    --- Gets whether this window is colored.
    --- @return boolean always true.
    function Window.isColor()
        return true
    end

    --- Clears the content of this window.
    function Window.clear()
        empty()
        draw()
    end

    --- Clears a content line of this window.
    --- @param line nil|number the window line to clear.
    function Window.clearLine(line)
        if line ~= nil and type(line) ~= "number" then
            error("bad argument #1 (expected number, got " .. type(line) .. ")", 2)
        end

        if line == nil then
            line = wCursorY
        end

        if line >= 1 and line <= (wHeight - 2) - (wPaddingY * 2) then
            empty(line)
            draw(line + 1 + wPaddingY)
        end
    end

    --- Draws this windows to the terminal.
    function Window.redraw()
        draw()
    end

    --- Draws a content line of this window.
    --- @param line nil|number the window line to draw.
    function Window.redrawLine(line)
        if type(line) ~= "number" then
            error("bad argument #1 (expected number, got " .. type(line) .. ")", 2)
        end

        if line == nil then
            line = wCursorY
        end

        if line >= 1 and line <= (wHeight - 2) - (wPaddingY * 2) then
            draw(line + 1 + wPaddingY)
        end
    end

    --- Append text to this window using the specified text and background color.
    --- @param text string the text to write.
    --- @param color string the color string containing valid hexadecimal color values in length of the text.
    --- @param background string the background string containing valid hexadecimal color values in length of the text.
    function Window.blit(text, color, background)
        if type(text) ~= "string" then
            error("bad argument #1 (expected string, got " .. type(text) .. ")", 2)
        end

        if type(color) ~= "string" then
            error("bad argument #1 (expected string, got " .. type(color) .. ")", 2)
        end

        if type(background) ~= "string" then
            error("bad argument #1 (expected string, got " .. type(background) .. ")", 2)
        end

        if string.len(text) ~= string.len(color) or string.len(color) ~= string.len(background) then
            error("bad arguments #1 #2 #3 (expected same length, got " .. string.len(text) .. ", " .. string.len(color) .. " and " .. string.len(background) .. ")", 2)
        end

        blit(text, color, background)
    end

    --- Append text to this window using the windows text and background color.
    --- @param text string the text to write.
    function Window.write(text)
        if type(text) ~= "string" then
            text = tostring(text)
        end

        blit(text, string.rep(wColor["text"], string.len(text)), string.rep(wColor["background"], string.len(text)))
    end

    return Window
end
