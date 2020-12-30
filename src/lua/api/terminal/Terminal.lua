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
    ["offset"] = 2,
    ["padding"] = 1,
    ["color"] = {
        ["text"] = "0",
        ["background"] = "f"
    },
    ["visible"] = false,
    ["cursor-x"] = 1,
    ["cursor-y"] = 1
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

--- Creates a new Terminal table object.
--- @param terminal table the parent terminal or monitor.
--- @param width    nil|number the width of the terminal.
--- @param height   nil|number the height of the terminal.
--- @param title    nil|string the title of this terminal.
--- @return table the created terminal table.
function create(terminal, width, height, title)
    -- Check all parameter types before initializing window table:
    if type(terminal) ~= "table" then
        error("bad argument #1 (expected table, got " .. type(terminal) .. ")", 2)
    end

    if width ~= nil and type(width) ~= "number" then
        error("bad argument #2 (expected number, got " .. type(width) .. ")", 2)
    end

    if height ~= nil and type(height) ~= "number" then
        error("bad argument #3 (expected number, got " .. type(height) .. ")", 2)
    end

    if title ~= nil and type(title) ~= "string" then
        error("bad argument #4 (expected string, got " .. type(title) .. ")", 2)
    end

    local maxWidth, maxHeight = terminal.getSize()
    local tWidth = maxWidth
    local tHeight = maxHeight

    if width ~= nil or height ~= nil then
        -- Check if both width and height is given:
        if width ~= nil and height ~= nil then
            -- Check correctness of width and height:
            if width < 0 or width > maxWidth then
                error("bad argument #2 (expected width between 0 and " .. maxWidth .. ", got " .. width .. ")", 2)
            end

            if height < 0 or height > maxHeight then
                error("bad argument #3 (expected height between 0 and " .. maxHeight .. ", got " .. height .. ")", 2)
            end

            tWidth = width
            tHeight = height
        else
            error("bad arguments #2 #3 (expected number and number, got " .. type(width) .. " and " .. type(height) .. ")", 2)
        end
    end

    local tTitle = defaults["title"]
    local tOffset = defaults["offset"]
    local tPadding = defaults["padding"]

    if title ~= nil then
        -- Check correctness of title:
        if string.len(title) > tWidth - (tOffset * 2) - (tPadding * 2) then
            error("bad argument #4 (expected title length between 0 and " .. math.max(0, tWidth - (tOffset * 2) - (tPadding * 2)) .. ", got " .. string.len(title) .. ")", 2)
        end

        tTitle = title
    end

    local tTerm = terminal

    local tColor = defaults["color"]
    local tVisible = defaults["visible"]
    local tCursorX = defaults["cursor-x"]
    local tCursorY = defaults["cursor-y"]

    local tHeader = {}
    local tLines = {}

    local tConfig

    --- Generates the header lines and writes it in the headers line cache.
    local function generate()
        -- Only generate header lines when title length is greater than zero:
        if string.len(tTitle) > 0 then
            local wide = tWidth - (tPadding * 2)

            -- Only generate when the full header line not exist or the wide not equals the header length:
            if tHeader["full"] == nil or string.len(tHeader["full"].text) ~= wide then
                tHeader["full"] = {
                    ["text"] = string.rep("=", wide),
                    ["color"] = string.rep(tColor["text"], wide),
                    ["background"] = string.rep(tColor["background"], wide)
                }
            end

            -- Only generate when the empty header line not exist or the wide not equals the header length:
            if tHeader["empty"] == nil or string.len(tHeader["empty"].text) ~= wide then
                tHeader["empty"] = {
                    ["text"] = "=" .. string.rep(" ", wide - 2) .. "=",
                    ["color"] = string.rep(tColor["text"], wide),
                    ["background"] = string.rep(tColor["background"], wide)
                }
            end

            local empty = tHeader["empty"]["text"]
            local before = math.ceil((wide - string.len(tTitle)) / 2)
            local after = before + string.len(tTitle) + 1

            tHeader["title"] = {
                ["text"] = string.sub(empty, 0, before) .. tTitle .. string.sub(empty, after),
                ["color"] = string.rep(tColor["text"], wide),
                ["background"] = string.rep(tColor["background"], wide)
            }
        else
            tHeader = {}
        end
    end

    --- Clears lines of this terminal (with header, if exist) of the terminal.
    local function clear(line)
        -- Cache cleared lines before writing it to the terminal:
        local wide = tWidth - (tPadding * 2)
        local text = string.rep(" ", wide)
        local color = string.rep(hex[tTerm.getTextColor()], wide)
        local back = string.rep(hex[tTerm.getBackgroundColor()], wide)

        -- Cache old cursor position of terminal
        local oldX, oldY = tTerm.getCursorPos()

        if line == nil then
            for lines = 1, tHeight - (tPadding * 2) do
                tTerm.setCursorPos(tPadding + 1, tPadding + lines)
                tTerm.blit(text, color, back)
            end
        else
            tTerm.setCursorPos(tPadding + 1, tPadding + line)
            tTerm.blit(text, color, back)
        end

        tTerm.setCursorPos(oldX, oldY)
    end

    --- Draws lines of this terminal (with header, if exist) to the terminal.
    local function draw(line)
        -- Only draw window to the terminal when it is visible:
        if tVisible then
            -- Check if line is specified. If true draw specified line, otherwise draw all lines:
            if line ~= nil then
                local oldX, oldY = tTerm.getCursorPos()

                if string.len(tTitle) > 0 then
                    local length = (tOffset * 2) + 1

                    tTerm.setCursorPos(tPadding + 1, tPadding + line)

                    if line <= length then
                        if tHeader["full"] == nil or tHeader["empty"] == nil or tHeader["title"] == nil then
                            generate()
                        end

                        if line == 1 or line == length then
                            tTerm.blit(tHeader["full"].text, tHeader["full"].color, tHeader["full"].background)
                        elseif line == tOffset + 1 then
                            tTerm.blit(tHeader["title"].text, tHeader["title"].color, tHeader["title"].background)
                        else
                            tTerm.blit(tHeader["empty"].text, tHeader["empty"].color, tHeader["empty"].background)
                        end
                    else
                        local content = line - length

                        if tLines[content] ~= nil then
                            tTerm.blit(tLines[content].text, tLines[content].color, tLines[content].background)
                        end
                    end
                else
                    if tLines[line] ~= nil then
                        tTerm.setCursorPos(tPadding + 1, tPadding + line)
                        tTerm.blit(tLines[line].text, tLines[line].color, tLines[line].background)
                    end
                end

                tTerm.setCursorPos(oldX, oldY)
            else
                for lines = 1, tHeight - (tPadding * 2) do
                    draw(lines)
                end
            end
        end
    end

    --- Empties lines of this terminal (without header).
    local function empty(line)
        local wide = tWidth - (tPadding * 2)

        -- Cache cleared lines before writing it in the lines cache:
        local text = string.rep(" ", wide)
        local color = string.rep(tColor["text"], wide)
        local background = string.rep(tColor["background"], wide)

        if line == nil then
            local length = tHeight - (tPadding * 2)

            if string.len(tTitle) > 0 then
                length = length - (tOffset * 2) - 1
            end

            for lines = 1, length  do
                tLines[lines] = {
                    ["text"] = text,
                    ["color"] = color,
                    ["background"] = background
                }
            end
        else
            tLines[line] = {
                ["text"] = text,
                ["color"] = color,
                ["background"] = background
            }
        end
    end

    --- Writes text in this terminal (without header) at the current cursor position.
    local function blit(text, color, background)
        local start = tCursorX
        local stop = start + string.len(text) - 1

        local wide = tWidth - (tPadding * 2)
        local length = tHeight - (tPadding * 2)

        if string.len(tTitle) > 0 then
            length = length - (tOffset * 2) - 1
        end

        if tCursorY >= 1 and tCursorY <= length then
            if start <= wide and stop >= 1 and stop > start then
                if tLines[tCursorY] == nil then
                    empty(tCursorY)
                end

                local line = tLines[tCursorY]

                if start < 1 then
                    local begin = 1 - start + 1

                    text = string.sub(text, begin)
                    color = string.sub(color, begin)
                    background = string.sub(background, begin)
                    start = 1
                end

                if stop > wide then
                    local ending = wide - start + 1

                    text = string.sub(text, 1, ending)
                    color = string.sub(color, 1, ending)
                    background = string.sub(background, 1, ending)
                    stop = wide
                end

                if start > 1 then
                    text = string.sub(line.text, 1, start - 1) .. text
                    color = string.sub(line.color, 1, start - 1) .. color
                    background = string.sub(line.background, 1, start - 1) .. background
                end

                if stop < wide then
                    text = text .. string.sub(line.text, stop + 1)
                    color = color .. string.sub(line.color, stop + 1)
                    background = background .. string.sub(line.background, stop + 1)
                end

                tCursorX = stop + 1
                tLines[tCursorY] = {
                    ["text"] = text,
                    ["color"] = color,
                    ["background"] = background
                }

                if string.len(tTitle) > 0 then
                    draw(tCursorY + (tOffset * 2) + 1)
                else
                    draw(tCursorY)
                end
            end
        end
    end

    --- Recolors the content of this terminal.
    local function recolor(color, background)
        local length = tHeight - (tPadding * 2)

        if string.len(tTitle) > 0 then
            length = length - (tOffset * 2) - 1
        end

        -- Iterate for each line and replace the old colors with the new colors:
        for line = 1, length do
            local cache = tLines[line]

            -- Only replace colors if line exists:
            if cache ~= nil then
                if color ~= nil then
                    cache.color = string.gsub(cache.color, tColor["text"], hex[color])
                end

                if background ~= nil then
                    cache.background = string.gsub(cache.background, tColor["background"], hex[background])
                end

                tLines[line] = {
                    ["text"] = cache.text,
                    ["color"] = cache.color,
                    ["background"] = cache.background
                }
            end
        end
    end

    --- Resizes the content of this terminal.
    local function resize()
        local wide = tWidth - (tPadding * 2)
        local length = tHeight - (tPadding * 2)

        if string.len(tTitle) > 0 then
            length = length - (tOffset * 2) - 1
        end

        local lines = {}

        for line = 1, length do
            local old = tLines[line]

            if old ~= nil then
                local oldLength = string.len(old.text)

                if oldLength > wide then
                    lines[line] = {
                        ["text"] = string.sub(old.text, 1, wide),
                        ["color"] = string.sub(old.color, 1, wide),
                        ["background"] = string.sub(old.background, 1 , wide)
                    }
                elseif oldLength < wide then
                    lines[line] = {
                        ["text"] = old.text .. string.rep(" ", wide - oldLength),
                        ["color"] = old.color .. string.rep(tColor["text"], wide - oldLength),
                        ["background"] = old.background .. string.rep(tColor["background"], wide - oldLength)
                    }
                else
                    lines[line] = old
                end
            else
                lines[line] = {
                    ["text"] = string.rep(" ", wide),
                    ["color"] = string.rep(tColor["text"], wide),
                    ["background"] = string.rep(tColor["background"], wide)
                }
            end
        end

        tLines = lines
    end

    --- Updates the specified config option of this terminal.
    local function update(key, value)
        if tConfig ~= nil then
            local old = tConfig.get(key)

            if old == nil or not equal(old, value) then
                tConfig.set(key, value)
                tConfig.save()
            end
        end
    end

    -- Start of terminal table implementation:
    local Terminal = {}

    --- Gets the name of this terminal.
    --- @return string the name of this terminal or an empty string.
    function Terminal.getTitle()
        return tTitle
    end

    --- Sets the name of this terminal.
    --- @param new string the new name for this terminal.
    --- @return boolean true when the title was changed, false otherwise.
    function Terminal.setTitle(new)
        if type(new) ~= "string" then
            error("bad argument #1 (expected string, got " .. type(new) .. ")", 2)
        end

        local length = string.len(new)

        if length > 0 and length > tWidth - (tPadding * 2) - (tOffset * 2) then
            error("bad argument #1 (expected title length between 0 and " .. math.max(0, tWidth - (tPadding * 2) - (tOffset * 2)) .. ", got " .. length .. ")", 2)
        end

        if new ~= tTitle then
            clear()
            tTitle = new
            generate()
            draw()
            update("title", tTitle)

            return true
        end

        return false
    end

    --- Gets the title offset of this terminal.
    --- @return number the title offset of this terminal.
    function Terminal.getOffset()
        return tOffset
    end

    --- Sets the title offset of this terminal.
    --- @param offset number the new title offset for this terminal.
    --- @return boolean true when the title offset was changed, false otherwise.
    function Terminal.setOffset(offset)
        if type(offset) ~= "number" then
            error("bad argument #1 (expected number, got " .. type(offset) .. ")", 2)
        end

        if offset < 1 or offset * 2 > tHeight - (tPadding * 2) - 1 then
            error("bad argument #1 (expected offset between 1 and " .. math.max(1, math.floor((tHeight - (tPadding * 2) - 1) / 2)) .. ", got " .. offset .. ")", 2)
        end

        if offset ~= tOffset then
            clear()
            tOffset = offset
            resize()
            draw()
            update("offset", tOffset)

            return true
        end

        return false
    end

    --- Gets the size of this terminal (without header).
    --- @return number, number the width and the height of this terminal.
    function Terminal.getSize()
        local length = tHeight - (tPadding * 2)

        if string.len(tTitle) > 0 then
            length = length - (tOffset * 2) - 1
        end

        return tWidth - (tPadding * 2), length
    end

    --- Gets the width of this terminal.
    --- @return number the width of this terminal or zero.
    function Terminal.getWidth()
        return tWidth
    end

    --- Sets the width of this terminal.
    --- @param new number the new width for this terminal.
    --- @return boolean true when the width was changed, false otherwise.
    function Terminal.setWidth(new)
        if type(new) ~= "number" then
            error("bad argument #1 (expected number, got " .. type(new) .. ")", 2)
        end

        maxWidth, maxHeight = tTerm.getSize()

        if new < 0 or new > maxWidth then
            error("bad argument #1 (expected width between 0 and " .. maxWidth .. ", got " .. new .. ")", 2)
        end

        if new > 0 and string.len(tTitle) > 0 and new < (tPadding * 2) + (tOffset * 2) + string.len(tTitle) then
            error("bad argument #1 (expected width between " .. ((tPadding * 2) + (tOffset * 2) + string.len(tTitle)) .. " and " .. maxWidth .. ", got " .. new .. ")", 2)
        end

        if new ~= tWidth then
            clear()
            tWidth = new
            generate()
            resize()
            draw()
            update("width", tWidth)

            return true
        end

        return false
    end

    --- Gets the height of this terminal.
    --- @return number the height of this terminal or zero.
    function Terminal.getHeight()
        return tHeight
    end

    --- Sets the height of this terminal.
    --- @param new number the new height for this terminal.
    --- @return boolean true when the height was changed, false otherwise.
    function Terminal.setHeight(new)
        if type(new) ~= "number" then
            error("bad argument #1 (expected number, got " .. type(new) .. ")", 2)
        end

        maxWidth, maxHeight = tTerm.getSize()

        if new < 0 or new > maxHeight then
            error("bad argument #1 (expected height between 0 and " .. maxHeight .. ", got " .. new .. ")", 2)
        end

        if new > 0 and string.len(tTitle) > 0 and new < (tPadding * 2) + (tOffset * 2) + 1 then
            error("bad argument #1 (expected width between " .. ((tPadding * 2) + (tOffset * 2) + 1) .. " and " .. maxHeight .. ", got " .. new .. ")", 2)
        end

        if new ~= tHeight then
            clear()
            tHeight = new
            generate()
            resize()
            draw()
            update("height", tHeight)

            return true
        end

        return false
    end

    --- Gets the padding of this terminal.
    --- @return number the padding of this terminal.
    function Terminal.getPadding()
        return tPadding
    end

    --- Sets the padding of this terminal.
    --- @param padding number the new padding for this terminal.
    --- @return boolean true when the padding was changed, false otherwise.
    function Terminal.setPadding(padding)
        if type(padding) ~= "number" then
            error("bad argument #1 (expected number, got " .. type(padding) .. ")", 2)
        end

        if padding < 0 or padding * 2 > tWidth then
            error("bad argument #1 (expected padding between 0 and " .. math.floor(tWidth / 2) .. ", got " .. padding .. ")", 2)
        end

        if padding ~= tPadding then
            clear()
            tPadding = padding
            generate()
            resize()
            draw()
            update("padding", tPadding)

            return true
        end

        return false
    end

    --- Gets the text color of this terminal.
    --- @return number the color code of the text color.
    function Terminal.getTextColor()
        return 2 ^ tonumber(tColor["text"], 16)
    end

    --- Sets the text color of this terminal.
    --- @param color number|string the color code or hex value of the new text color.
    --- @return boolean true when the text color was changed, false otherwise.
    function Terminal.setTextColor(color)
        if type(color) ~= "number" and type(color) ~= "string" then
            error("bad argument #1 (expected number or string, got " .. type(color) .. ")", 2)
        end

        if type(color) == "string" then
            color = 2 ^ tonumber(color, 16)
        end

        if hex[color] == nil then
            error("bad argument #1 (expected color code, got " .. color .. ")", 2)
        end

        if hex[color] ~= tColor["text"] then
            recolor(color, nil)
            tColor["text"] = hex[color]
            generate()
            draw()
            update("color", tColor)

            return true
        end

        return false
    end

    --- Gets the background color of this terminal.
    --- @return number the color code of the background color.
    function Terminal.getBackgroundColor()
        return 2 ^ tonumber(tColor["background"], 16)
    end

    --- Sets the background color of this terminal.
    --- @param color number|string the color code or hex value of the new background color.
    --- @return boolean true when the background color was changed, false otherwise.
    function Terminal.setBackgroundColor(color)
        if type(color) ~= "number" and type(color) ~= "string" then
            error("bad argument #1 (expected number or string, got " .. type(color) .. ")", 2)
        end

        if type(color) == "string" then
            color = 2 ^ tonumber(color, 16)
        end

        if hex[color] == nil then
            error("bad argument #1 (expected color code, got " .. color .. ")", 2)
        end

        if hex[color] ~= tColor["background"] then
            recolor(nil, color)
            tColor["background"] = hex[color]
            generate()
            draw()
            update("color", tColor)

            return true
        end

        return false
    end

    --- Gets whether this terminal is visible.
    --- @return boolean true when this terminal is visible, false otherwise.
    function Terminal.getVisible()
        return tVisible
    end

    --- Sets whether this terminal is visible.
    --- @param visible boolean whether this terminal should be visible.
    --- @return boolean true when the visibility was changed, false otherwise.
    function Terminal.setVisible(visible)
        if type(visible) ~= "boolean" then
            error("bad argument #1 (expected boolean, got " .. type(visible) .. ")", 2)
        end

        if visible and not tVisible then
            tVisible = true
            draw()
        elseif not visible and tVisible then
            tVisible = false
            clear()
        else
            return false
        end

        update("visible", tVisible)
        return true
    end

    --- Gets the current cursor position of this terminal.
    --- @return number, number the current position of the cursor.
    function Terminal.getCursorPos()
        return tCursorX, tCursorY
    end

    --- Sets the cursor position of this terminal.
    --- @param newX number the new x position for the cursor.
    --- @param newY number the new y position for the cursor.
    function Terminal.setCursorPos(newX, newY)
        if newX ~= nil and type(newX) ~= "number" then
            error("bad argument #1 (expected number, got " .. type(newX) .. ")", 2)
        end

        if newY ~= nil and type(newY) ~= "number" then
            error("bad argument #2 (expected number, got " .. type(newY) .. ")", 2)
        end

        if newX ~= nil then
            newX = math.floor(newX)

            if newX ~= tCursorX then
                tCursorX = newX
            end
        end

        if newY ~= nil then
            newY = math.floor(newY)

            if newY ~= tCursorY then
                tCursorY = newY
            end
        end
    end

    --- Loads this terminal from the configuration file at the specified path.
    --- @param path string the path to the configuration file.
    --- @return boolean true when the configuration was loaded, false otherwise.
    function Terminal.load(path)
        if path ~= nil and type(path) ~= "string" then
            error("bad argument #1 (expected string, got " .. type(path) .. ")", 2)
        end

        if path == nil and tConfig == nil then
            error("bad argument #1 (expected path, got nil)", 2)
        end

        if path ~= nil and (tConfig == nil or tConfig.path() ~= path) then
            tConfig = Configuration.create(path)
        end

        if tConfig.load() then
            if tConfig.contains("width") then
                Terminal.setWidth(tConfig.get("width"))
            end

            if tConfig.contains("height") then
                Terminal.setHeight(tConfig.get("height"))
            end

            if tConfig.contains("padding") then
                Terminal.setPadding(tConfig.get("padding"))
            end

            if tConfig.contains("offset") then
                Terminal.setOffset(tConfig.get("offset"))
            end

            if tConfig.contains("title") then
                Terminal.setTitle(tConfig.get("title"))
            end

            if tConfig.contains("color") then
                local color = tConfig.get("color")

                if type(color) ~= "table" then
                    error("bad argument #1 (expected color table, got " .. type(color) .. ")", 2)
                end

                if color["text"] ~= nil then
                    Terminal.setTextColor(color["text"])
                end

                if color["background"] ~= nil then
                    Terminal.setBackgroundColor(color["background"])
                end
            end

            if tConfig.contains("visible") then
                Terminal.setVisible(tConfig.get("visible"))
            end

            if tConfig.contains("cursor-x") or tConfig.contains("cursor-y") then
                Terminal.setCursorPos(tConfig.get("cursor-x"), tConfig.get("cursor-y"))
            end

            if tConfig.contains("lines") then
                local lines = tConfig.get("lines")

                if type(lines) ~= "table" then
                    error("bad argument #1 (expected lines table, got " .. type(lines) .. ")", 2)
                end

                local oldX, oldY = Terminal.getCursorPos()

                for line, content in pairs(lines) do
                    if type(line) ~= "number" then
                        error("bad argument #1 (expected line number, got " .. type(line) .. ")", 2)
                    end

                    Terminal.setCursorPos(1, line)

                    if type(content) == "string" then
                        Terminal.write(content)
                    elseif type(content) == "table" then
                        Terminal.blit(content.text, content.color, content.background)
                    else
                        error("bad argument #1 (expected content string or table, got " .. type(content) .. ")", 2)
                    end
                end

                Terminal.setCursorPos(oldX, oldY)
            end

            return true
        end

        return false
    end

    --- Saves this terminal to the configuration file at the specified path.
    --- @param path string the path to the configuration file.
    --- @return boolean true when the configuration was saved, false otherwise.
    function Terminal.save(path)
        if path ~= nil and type(path) ~= "string" then
            error("bad argument #1 (expected string, got " .. type(path) .. ")", 2)
        end

        if path == nil and tConfig == nil then
            error("bad argument #1 (expected path, got nil)", 2)
        end

        if path ~= nil and (tConfig == nil or tConfig.path() ~= path) then
            tConfig = Configuration.create(path)

            if not equal(tTitle, defaults["title"]) then
                tConfig.set("title", tTitle)
            end

            if not equal(tWidth, defaults["width"]) then
                tConfig.set("width", tWidth)
            end

            if not equal(tHeight, defaults["height"]) then
                tConfig.set("height", tHeight)
            end

            if not equal(tPadding, defaults["padding-x"]) then
                tConfig.set("padding-x", tPadding)
            end

            if not equal(tOffset, defaults["offset"]) then
                tConfig.set("offset", tOffset)
            end

            if not equal(tColor, defaults["color"]) then
                tConfig.set("color", tColor)
            end

            if not equal(tVisible, defaults["visible"]) then
                tConfig.set("visible", tVisible)
            end

            if not equal(tCursorX, defaults["cursor-x"]) then
                tConfig.set("cursor-x", tCursorX)
            end

            if not equal(tCursorY, defaults["cursor-y"]) then
                tConfig.set("cursor-y", tCursorY)
            end
        end

        return tConfig.save()
    end

    --- Gets whether this terminal is colored.
    --- @return boolean always true.
    function Terminal.isColor()
        return tTerm.isColor()
    end

    --- Clears the content of this terminal.
    function Terminal.clear()
        empty()
        draw()
    end

    --- Clears a content line of this terminal.
    --- @param line nil|number the window line to clear.
    function Terminal.clearLine(line)
        if line ~= nil and type(line) ~= "number" then
            error("bad argument #1 (expected number, got " .. type(line) .. ")", 2)
        end

        if line == nil then
            line = tCursorY
        end

        if string.len(tTitle) > 0 then
            if line >= 1 and line <= tHeight - (tPadding * 2) - (tOffset * 2) - 1 then
                empty(line)
                draw(line + (tOffset * 2) + 1)
            end
        else
            if line >= 1 and line <= tHeight - (tPadding * 2) then
                empty(line)
                draw(line)
            end
        end
    end

    --- Draws this terminal to the terminal.
    function Terminal.redraw()
        draw()
    end

    --- Draws a content line of this terminal.
    --- @param line nil|number the terminal line to draw.
    function Terminal.redrawLine(line)
        if type(line) ~= "number" then
            error("bad argument #1 (expected number, got " .. type(line) .. ")", 2)
        end

        if line == nil then
            line = tCursorY
        end

        if string.len(tTitle) > 0 then
            if line >= 1 and line <= tHeight - (tPadding * 2) - (tOffset * 2) - 1 then
                draw(line + (tOffset * 2) + 1)
            end
        else
            if line >= 1 and line <= tHeight - (tPadding * 2) then
                draw(line)
            end
        end
    end

    --- Append text to this terminal using the specified text and background color.
    --- @param text string the text to write.
    --- @param color string the color string containing valid hexadecimal color values in length of the text.
    --- @param background string the background string containing valid hexadecimal color values in length of the text.
    function Terminal.blit(text, color, background)
        if type(text) ~= "string" then
            error("bad argument #1 (expected string, got " .. type(text) .. ")", 2)
        end

        if type(color) ~= "string" then
            error("bad argument #2 (expected string, got " .. type(color) .. ")", 2)
        end

        if type(background) ~= "string" then
            error("bad argument #3 (expected string, got " .. type(background) .. ")", 2)
        end

        if string.len(text) ~= string.len(color) or string.len(color) ~= string.len(background) then
            error("bad arguments #1 #2 #3 (expected same length, got " .. string.len(text) .. ", " .. string.len(color) .. " and " .. string.len(background) .. ")", 2)
        end

        blit(text, color, background)
    end

    --- Append text to this window using the terminals text and background color.
    --- @param text string the text to write.
    function Terminal.write(text)
        if type(text) ~= "string" then
            text = tostring(text)
        end

        blit(text, string.rep(tColor["text"], string.len(text)), string.rep(tColor["background"], string.len(text)))
    end

    return Terminal
end