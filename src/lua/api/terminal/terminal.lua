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

local hex = {
    [colors.white] = "0",
    [colors.orange] = "1",
    [colors.magenta] = "2",
    [colors.lightBlue] = "3",
    [colors.yellow] = "4",
    [colors.lime] = "5",
    [colors.pink] = "6",
    [colors.gray] = "7",
    [colors.lightGray] = "8",
    [colors.cyan] = "9",
    [colors.purple] = "a",
    [colors.blue] = "b",
    [colors.brown] = "c",
    [colors.green] = "d",
    [colors.red] = "e",
    [colors.black] = "f",
}

--- Creates a new terminal table object.
--- @param tTerm table the parent terminal.
--- @param tPosX nil|number the terminal's x position.
--- @param tPosY nil|number the terminal's y position.
--- @param tWidth nil|number the terminal's width.
--- @param tHeight nil|number the terminal's height.
--- @param tTitle nil|string the terminal's title.
--- @return table the created terminal table.
function create(tTerm, tPosX, tPosY, tWidth, tHeight, tTitle)
    if type(tTerm) ~= "table" then
        error("bad argument #1 (expected table, got " .. type(tTerm) .. ")", 2)
    end

    local tOffset, tPadding = 2, 1

    do
        local maxWidth, maxHeight = tTerm.getSize()

        if maxWidth < tOffset * 2 then
            error("bad argument #1 (expected width greater than or equal " .. tOffset * 2 .. ", got " .. maxWidth .. ")", 2)
        end

        -- Magic value '2': Corresponds to one title line and one additional content line
        if maxHeight < (tOffset * 2) + tPadding + 2 then
            error("bad argument #1 (expected height greater than or equal " .. (tOffset * 2) + tPadding + 2 .. ", got " .. maxHeight .. ")", 2)
        end

        if tPosX ~= nil then
            if type(tPosX) ~= "number" then
                error("bad argument #2 (expected number, got " .. type(tPosX) .. ")", 2)
            end

            if tPosX < 1 or tPosX > maxWidth - (tOffset * 2) + 1 then
                error("bad argument #2 (expected position between 1 and " .. maxWidth - (tOffset * 2) + 1 .. ", got " .. tPosX .. ")", 2)
            end
        else
            tPosX = 1
        end

        if tPosY ~= nil then
            if type(tPosY) ~= "number" then
                error("bad argument #3 (expected number, got " .. type(tPosY) .. ")", 2)
            end

            if tPosY < 1 or tPosY > maxHeight - (tOffset * 2) - tPadding - 1 then
                error("bad argument #3 (expected position between 1 and " .. maxHeight - (tOffset * 2) - tPadding - 1 .. ", got " .. tPosY .. ")", 2)
            end
        else
            tPosY = 1
        end

        if tWidth ~= nil then
            if type(tWidth) ~= "number" then
                error("bad argument #4 (expected number, got " .. type(tWidth) .. ")", 2)
            end

            if tWidth < tOffset * 2 or tWidth > maxWidth - (tPosX - 1) then
                error("bad argument #4 (expected width between " .. tOffset * 2 .. " and " .. maxWidth - (tPosX - 1) .. ", got " .. tWidth .. ")", 2)
            end
        else
            tWidth = maxWidth - (tPosX - 1)
        end

        if tHeight ~= nil then
            if type(tHeight) ~= "number" then
                error("bad argument #5 (expected number, got " .. type(tHeight) .. ")", 2)
            end

            -- Magic value '2': Corresponds to one title line and one additional content line
            if tHeight < (tOffset * 2) + tPadding + 2 or tHeight > maxHeight - (tPosY - 1) then
                error("bad argument #5 (expected height between " .. (tOffset * 2) + tPadding + 2 .. " and " .. maxHeight - (tPosY - 1) .. ", got " .. tHeight .. ")", 2)
            end
        else
            tHeight = maxHeight - (tPosY - 1)
        end

        if tTitle ~= nil then
            if type(tTitle) ~= "string" then
                error("bad argument #6 (expected string, got " .. type(tTitle) .. ")", 2)
            end

            if tTitle:len() > tWidth - (tOffset * 2) then
                error("bad argument #6 (expected length between 0 and " .. tWidth - (tOffset * 2) .. ", got " .. tTitle:len() .. ")", 2)
            end
        else
            tTitle = ""
        end
    end

    local cText, cBackground = hex[tTerm.getTextColor()], hex[tTerm.getBackgroundColor()]
    local tCursorX, tCursorY = 1, 1
    local tVisible = false
    local tHeader = {}
    local tLines = {}
    local tConfig

    local function generate()
        if tHeader["full"] == nil or tHeader["full"]:len() ~= tWidth then
            tHeader["full"] = string.rep("=", tWidth)
        end

        if tHeader["empty"] == nil or tHeader["empty"]:len() ~= tWidth then
            tHeader["empty"] = "=" .. string.rep(" ", tWidth - 2) .. "="
        end

        tHeader["color"] = cText:rep(tWidth)
        tHeader["background"] = cBackground:rep(tWidth)

        if tTitle:len() > 0 then
            local before = math.ceil((tWidth - tTitle:len()) / 2)
            local after = before + tTitle:len() + 1

            tHeader["title"] = tHeader["empty"]:sub(1, before) .. tTitle .. tHeader["empty"]:sub(after)
        else
            tHeader["title"] = tHeader["empty"]
        end
    end

    local function clear(line)
        local text, color, background = string.rep(" ", tWidth), hex[tTerm.getTextColor()]:rep(tWidth), hex[tTerm.getBackgroundColor()]:rep(tWidth)
        local oldX, oldY = tTerm.getCursorPos()

        if line == nil then
            for lines = 1, tHeight do
                tTerm.setCursorPos(tPosX, tPosY + (lines - 1))
                tTerm.blit(text, color, background)
            end
        else
            tTerm.setCursorPos(tPosX, tPosY + (line - 1))
            tTerm.blit(text, color, background)
        end

        tTerm.setCursorPos(oldX, oldY)
    end

    local function draw(line)
        if tVisible then
            if line ~= nil then
                local oldX, oldY = tTerm.getCursorPos()

                tTerm.setCursorPos(tPosX, tPosY + (line - 1))

                if tTitle:len() > 0 then
                    if line <= (tOffset * 2) + 1 then
                        if tHeader["full"] == nil or tHeader["empty"] == nil or tHeader["title"] == nil then
                            generate()
                        end

                        if line == 1 or line == (tOffset * 2) + 1 then
                            tTerm.blit(tHeader["full"], tHeader["color"], tHeader["background"])
                        elseif line == tOffset + 1 then
                            tTerm.blit(tHeader["title"], tHeader["color"], tHeader["background"])
                        else
                            tTerm.blit(tHeader["empty"], tHeader["color"], tHeader["background"])
                        end

                        tTerm.setCursorPos(oldX, oldY)
                        return
                    end

                    line = line - (tOffset * 2) - tPadding - 1
                end

                if tLines[line] ~= nil then
                    tTerm.blit(tLines[line].text, tLines[line].color, tLines[line].background)
                else
                    tTerm.blit(string.rep(" ", tWidth), cText:rep(tWidth), cBackground:rep(tWidth))
                end

                tTerm.setCursorPos(oldX, oldY)
            else
                for lines = 1, tHeight do
                    draw(lines)
                end
            end
        end
    end

    local function empty(line)
        local text, color, background = string.rep(" ", tWidth), cText:rep(tWidth), cBackground:rep(tWidth)

        if line == nil then
            for _, content in pairs(tLines) do
                content["text"] = text
                content["color"] = color
                content["background"] = background
            end
        else
            tLines[line] = {
                ["text"] = text,
                ["color"] = color,
                ["background"] = background
            }
        end
    end

    local function blit(text, color, background)
        local start = tCursorX
        local stop = start + text:len() - 1
        local width, height = tWidth, tHeight

        if tTitle:len() > 0 then
            height = height - (tOffset * 2) - tPadding - 1
        end

        if tCursorY >= 1 and tCursorY <= height then
            if start <= width and stop >= 1 and stop > start then
                if tLines[tCursorY] == nil then
                    empty(tCursorY)
                end

                local line = tLines[tCursorY]

                if start < 1 then
                    local begin = 1 - start + 1

                    text = text:sub(begin)
                    color = color:sub(begin)
                    background = background:sub(begin)
                    start = 1
                end

                if stop > width then
                    local ending = width - start + 1

                    text = text:sub(1, ending)
                    color = color:sub(1, ending)
                    background = background:sub(1, ending)
                    stop = width
                end

                if start > 1 then
                    text = line.text:sub(1, start - 1) .. text
                    color = line.color:sub(1, start - 1) .. color
                    background = line.background:sub(1, start - 1) .. background
                end

                if stop < width then
                    text = text .. line.text:sub(stop + 1)
                    color = color .. line.color:sub(stop + 1)
                    background = background .. line.background:sub(stop + 1)
                end

                tCursorX = stop + 1
                tLines[tCursorY] = {
                    ["text"] = text,
                    ["color"] = color,
                    ["background"] = background
                }

                if tTitle:len() > 0 then
                    draw(tCursorY + (tOffset * 2) + tPadding + 1)
                else
                    draw(tCursorY)
                end
            end
        end
    end

    local function recolor(color, background)
        for _, content in pairs(tLines) do
            if color ~= nil then
                content.color = content.color:gsub(cText, hex[color])
            end

            if background ~= nil then
                content.background = content.background:gsub(cBackground, hex[background])
            end
        end
    end

    local function resize()
        local width, height = tWidth, tHeight

        if tTitle:len() > 0 then
            height = height - (tOffset * 2) - tPadding - 1
        end

        local lines = {}

        for line, content in pairs(tLines) do
            if line <= height then
                if content.text:len() ~= width then
                    local length = content.text:len()

                    if length > width then
                        content.text = content.text:sub(1, width)
                        content.color = content.color:sub(1, width)
                        content.background = content.background:sub(1, width)
                    elseif length < width then
                        content.text = content.text .. string.rep(" ", width - length)
                        content.color = content.color .. cText:rep(width - length)
                        content.background = content.background .. cBackground:rep(width - length)
                    end
                end

                lines[line] = content
            end
        end

        tLines = lines
    end

    local function load(key, method)
        if tConfig ~= nil and tConfig.contains(key) then
            local success, message = pcall(method, tConfig.get(key))

            if not success then
                error("bad configuration #" .. key .. " (" .. message:gsub(".*%((.+)%)", "%1") .. ")", 3)
            end
        end
    end

    local function save(key, value)
        if tConfig ~= nil and tConfig.get(key) ~= value then
            tConfig.set(key, value)
            tConfig.save()
        end

        return value
    end

    --                             --
    --   Terminal Implementation   --
    --                             --

    local terminal = {}

    --- Gets the title of this terminal.
    --- @return string the title of this terminal or an empty string.
    function terminal.getTitle()
        return tTitle
    end

    --- Sets the title of this terminal.
    --- @param title string the new title for this terminal.
    --- @return boolean true when the title was changed, false otherwise.
    function terminal.setTitle(title)
        if type(title) ~= "string" then
            error("bad argument #1 (expected string, got " .. type(title) .. ")", 2)
        end

        if title:len() > tWidth - (tOffset * 2) then
            error("bad argument #1 (expected length between 0 and " .. tWidth - (tOffset * 2) .. ", got " .. title:len() .. ")", 2)
        end

        if title ~= tTitle then
            tTitle = save("title", title)
            generate()
            clear()
            draw()

            return true
        end

        return false
    end

    --- Gets the title offset of the terminal header.
    --- @return number the title offset.
    function terminal.getOffset()
        return tOffset
    end

    --- Sets the title offset for the terminal header.
    --- @param offset number the new title offset.
    --- @return boolean true when the offset was changed, false otherwise.
    function terminal.setOffset(offset)
        if type(offset) ~= "number" then
            error("bad argument #1 (expected number, got " .. type(offset) .. ")", 2)
        end

        if offset < 2 or offset * 2 > math.min(tHeight - 1, tWidth - tTitle:len()) then
            error("bad argument #1 (expected offset between 1 and " .. math.floor(math.min(tHeight - 1, tWidth - tTitle:len()) / 2) .. ", got " .. offset .. ")", 2)
        end

        if offset ~= tOffset then
            tOffset = save("offset", offset)
            resize()
            clear()
            draw()

            return true
        end

        return false
    end

    --- Gets the position, without header, of this terminal.
    --- @return number, number the terminal's x and y position without header.
    function terminal.getPosition()
        if tTitle:len() > 0 then
            return tPosX, tPosY + (tOffset * 2) + tPadding + 1
        else
            return tPosX, tPosY
        end
    end

    --- Gets the x position of this terminal.
    --- @return number the terminal's x position.
    function terminal.getPosX()
        return tPosX
    end

    --- Sets the x position of this terminal.
    --- @param posX number the new x position.
    --- @return boolean true when the x position was changed, false otherwise.
    function terminal.setPosX(posX)
        if type(posX) ~= "number" then
            error("bad argument #1 (expected number, got " .. type(posX) .. ")", 2)
        end

        local maxWidth, _ = tTerm.getSize()

        if maxWidth < tOffset * 2 then
            error("bad argument #1 (expected width greater than or equal " .. tOffset * 2 .. ", got " .. maxWidth .. ")", 2)
        end

        if posX < 1 or posX > maxWidth - (tOffset * 2) + 1 then
            error("bad argument #2 (expected position between 1 and " .. maxWidth - (tOffset * 2) + 1 .. ", got " .. posX .. ")", 2)
        end

        if posX ~= tPosX then
            clear()
            tPosX = save("pos-x", posX)
            draw()

            return true
        end

        return false
    end

    --- Gets the y position of this terminal.
    --- @return number the terminal's y position.
    function terminal.getPosY()
        return tPosY
    end

    --- Sets the y position of this terminal.
    --- @param posY number the new y position.
    --- @return boolean true when the y position was changed, false otherwise.
    function terminal.setPosY(posY)
        if type(posY) ~= "number" then
            error("bad argument #1 (expected number, got " .. type(posY) .. ")", 2)
        end

        local _, maxHeight = tTerm.getSize()

        -- Magic value '2': Corresponds to one title line and one additional content line
        if maxHeight < (tOffset * 2) + tPadding + 2 then
            error("bad argument #1 (expected height greater than or equal " .. (tOffset * 2) + tPadding + 2 .. ", got " .. maxHeight .. ")", 2)
        end

        if posY < 1 or posY > maxHeight - (tOffset * 2) - tPadding - 1 then
            error("bad argument #3 (expected position between 1 and " .. maxHeight - (tOffset * 2) - tPadding - 1 .. ", got " .. posY .. ")", 2)
        end

        if posY ~= tPosY then
            clear()
            tPosY = save("pos-y", posY)
            draw()

            return true
        end

        return false
    end

    --- Gets the size, without header, of this terminal.
    --- @return number, number the terminal's width and height without header.
    function terminal.getSize()
        if tTitle:len() > 0 then
            return tWidth, tHeight - (tOffset * 2) - tPadding - 1
        else
            return tWidth, tHeight
        end
    end

    --- Gets the width of this terminal.
    --- @return number the terminal's width.
    function terminal.getWidth()
        return tWidth
    end

    --- Sets the width of this terminal.
    --- @param width number the new width.
    --- @return boolean true when the width was changed, false otherwise.
    function terminal.setWidth(width)
        if type(width) ~= "number" then
            error("bad argument #1 (expected number, got " .. type(width) .. ")", 2)
        end

        local maxWidth, _ = tTerm.getSize()

        if maxWidth < tOffset * 2 then
            error("bad argument #1 (expected width greater than or equal " .. tOffset * 2 .. ", got " .. maxWidth .. ")", 2)
        end

        if width < tOffset * 2 or width > maxWidth - (tPosX - 1) then
            error("bad argument #4 (expected width between " .. tOffset * 2 .. " and " .. maxWidth - (tPosX - 1) .. ", got " .. width .. ")", 2)
        end

        if width ~= tWidth then
            clear()
            tWidth = save("width", width)
            generate()
            resize()
            draw()

            return true
        end

        return false
    end

    --- Gets the height of this terminal.
    --- @return number the terminal's height.
    function terminal.getHeight()
        return tHeight
    end

    --- Sets the height of this terminal.
    --- @param height number the new height.
    --- @return boolean true when the height was changed, false otherwise.
    function terminal.setHeight(height)
        if type(height) ~= "number" then
            error("bad argument #1 (expected number, got " .. type(height) .. ")", 2)
        end

        local _, maxHeight = tTerm.getSize()

        -- Magic value '2': Corresponds to one title line and one additional content line
        if maxHeight < (tOffset * 2) + tPadding + 2 then
            error("bad argument #1 (expected height greater than or equal " .. (tOffset * 2) + tPadding + 2 .. ", got " .. maxHeight .. ")", 2)
        end

        -- Magic value '2': Corresponds to one title line and one additional content line
        if height < (tOffset * 2) + tPadding + 2 or height > maxHeight - (tPosY - 1) then
            error("bad argument #5 (expected height between " .. (tOffset * 2) + tPadding + 2 .. " and " .. maxHeight - (tPosY - 1) .. ", got " .. height .. ")", 2)
        end

        if height ~= tHeight then
            clear()
            tHeight = save("height", height)
            generate()
            resize()
            draw()

            return true
        end

        return false
    end

    --- Gets the padding of this terminal.
    --- @return number the terminal's padding.
    function terminal.getPadding()
        return tPadding
    end

    --- Sets the padding of this terminal.
    --- @param padding number the new padding.
    --- @return boolean true when the padding was changed, false otherwise.
    function terminal.setPadding(padding)
        if type(padding) ~= "number" then
            error("bad argument #1 (expected number, got " .. type(padding) .. ")", 2)
        end

        -- Magic value '2': Corresponds to one title line and one additional content line
        if padding < 0 or padding > tWidth - (tOffset * 2) - 2 then
            error("bad argument #1 (expected padding between 0 and " .. tWidth - (tOffset * 2) - 2 .. ", got " .. padding .. ")", 2)
        end

        if padding ~= tPadding then
            clear()
            tPadding = save("padding", padding)
            generate()
            resize()
            draw()

            return true
        end

        return false
    end

    --- Gets the text color of this terminal.
    --- @return number the color code of the text color.
    function terminal.getTextColor()
        return 2 ^ tonumber(cText, 16)
    end

    --- Sets the text color of this terminal.
    --- @param color number|string the new color, represented by the color code or hex value.
    --- @return boolean true when the color was changed, false otherwise.
    function terminal.setTextColor(color)
        if type(color) ~= "number" and type(color) ~= "string" then
            error("bad argument #1 (expected number or string, got " .. type(color) .. ")", 2)
        end

        if type(color) == "string" then
            color = 2 ^ tonumber(color, 16)
        end

        if hex[color] == nil then
            error("bad argument #1 (expected color code, got " .. color .. ")", 2)
        end

        if hex[color] ~= cText then
            recolor(color, nil)
            cText = save("color.text", hex[color])
            generate()
            draw()

            return true
        end

        return false
    end

    --- Gets the background color of this terminal.
    --- @return number the color code of the background color.
    function terminal.getBackgroundColor()
        return 2 ^ tonumber(cBackground, 16)
    end

    --- Sets the background color of this terminal.
    --- @param color number|string the new color, represented by the color code or hex value.
    --- @return boolean true when the color was changed, false otherwise.
    function terminal.setBackgroundColor(color)
        if type(color) ~= "number" and type(color) ~= "string" then
            error("bad argument #1 (expected number or string, got " .. type(color) .. ")", 2)
        end

        if type(color) == "string" then
            color = 2 ^ tonumber(color, 16)
        end

        if hex[color] == nil then
            error("bad argument #1 (expected color code, got " .. color .. ")", 2)
        end

        if hex[color] ~= cBackground then
            recolor(nil, color)
            cBackground = save("color.background", hex[color])
            generate()
            draw()

            return true
        end

        return false
    end

    --- Gets whether this terminal is visible.
    --- @return boolean true when it is visible, false otherwise.
    function terminal.getVisible()
        return tVisible
    end

    --- Sets whether this terminal is visible.
    --- @param visible boolean whether it should be visible.
    --- @return boolean true when the visibility was changed, false otherwise.
    function terminal.setVisible(visible)
        if type(visible) ~= "boolean" then
            error("bad argument #1 (expected boolean, got " .. type(visible) .. ")", 2)
        end

        if visible ~= tVisible then
            tVisible = save("visible", visible)

            if visible then
                draw()
            else
                clear()
            end

            return true
        end

        return false
    end

    --- Gets the current cursor position, without header, of this terminal.
    --- @return number, number the current position of the cursor.
    function terminal.getCursorPos()
        return tCursorX, tCursorY
    end

    --- Sets the cursor position of this terminal.
    --- @param posX number|nil the new x position or nil.
    --- @param posY number|nil the new y position or nil.
    function terminal.setCursorPos(posX, posY)
        if posX ~= nil then
            if type(posX) ~= "number" then
                error("bad argument #1 (expected number, got " .. type(posX) .. ")", 2)
            end

            tCursorX = math.floor(posX)
        end

        if posY ~= nil then
            if type(posY) ~= "number" then
                error("bad argument #1 (expected number, got " .. type(posY) .. ")", 2)
            end

            tCursorY = math.floor(posY)
        end
    end

    --- Loads this terminal from the configuration file at the specified path.
    --- @param path string the path to the configuration file.
    --- @return boolean true when the configuration was loaded, false otherwise.
    function terminal.load(path)
        if path ~= nil and type(path) ~= "string" or path == nil and tConfig == nil then
            error("bad argument #1 (expected string, got " .. type(path) .. ")", 2)
        end

        if path ~= nil and (tConfig == nil or tConfig.path() ~= path) then
            tConfig = config.create(path)
        end

        if tConfig.load() then
            load("pos-x", terminal.setPosX)
            load("pos-y", terminal.setPosY)
            load("width", terminal.setWidth)
            load("height", terminal.setHeight)
            load("offset", terminal.setOffset)
            load("padding", terminal.setPadding)
            load("title", terminal.setTitle)
            load("color.text", terminal.setTextColor)
            load("color.background", terminal.setBackgroundColor)
            load("visible", terminal.setVisible)
            terminal.setCursorPos(tConfig.get("cursor-x"), tConfig.get("cursor-y"))

            return true
        end

        return false
    end

    --- Saves this terminal to the configuration file at the specified path.
    --- @param path string the path to the configuration file.
    --- @return boolean true when the configuration was saved, false otherwise.
    function terminal.save(path)
        if path ~= nil and type(path) ~= "string" or path == nil and tConfig == nil then
            error("bad argument #1 (expected string, got " .. type(path) .. ")", 2)
        end

        if path ~= nil and (tConfig == nil or tConfig.path() ~= path) then
            tConfig = config.create(path)

            save("title", tTitle)
            save("pos-x", tPosX)
            save("pos-y", tPosY)
            save("width", tWidth)
            save("height", tHeight)
            save("offset", tOffset)
            save("padding", tPadding)
            save("color.text", cText)
            save("color.background", cBackground)
            save("visible", tVisible)
            save("cursor-x", tCursorX)
            save("cursor-y", tCursorY)
        end

        return tConfig.save()
    end

    --- Gets whether this terminal is colored.
    --- @return boolean true when the parent terminal supports colors, false otherwise.
    function terminal.isColor()
        return tTerm.isColor()
    end

    --- Clears the lines of this terminal.
    function terminal.clear()
        tLines = {}
        clear()
        draw()
    end

    --- Clears a line of this terminal.
    --- @param line nil|number the line to clear.
    function terminal.clearLine(line)
        if line ~= nil then
            if type(line) ~= "number" then
                error("bad argument #1 (expected number, got " .. type(line) .. ")", 2)
            end
        else
            line = tCursorY
        end

        if tLines[line] ~= nil then
            tLines[line] = nil

            if tTitle:len() > 0 then
                line = line + (tOffset * 2) + tPadding + 1
            end

            clear(line)
        end
    end

    --- Draws the lines to the terminal.
    function terminal.redraw()
        clear()
        draw()
    end

    --- Draws a line to this terminal.
    --- @param line nil|number the line to draw.
    function terminal.redrawLine(line)
        if line ~= nil then
            if type(line) ~= "number" then
                error("bad argument #1 (expected number, got " .. type(line) .. ")", 2)
            end
        else
            line = tCursorY
        end

        if tLines[line] ~= nil then
            if tTitle:len() > 0 then
                line = line + (tOffset * 2) + tPadding + 1
            end

            clear(line)
            draw(line)
        end
    end

    --- Append text to this terminal using the specified text and background color.
    --- @param text string the text to write.
    --- @param color string the color string containing valid hexadecimal color values in length of the text.
    --- @param background string the background string containing valid hexadecimal color values in length of the text.
    function terminal.blit(text, color, background)
        if type(text) ~= "string" then
            error("bad argument #1 (expected string, got " .. type(text) .. ")", 2)
        end

        if type(color) ~= "string" then
            error("bad argument #2 (expected string, got " .. type(color) .. ")", 2)
        end

        if type(background) ~= "string" then
            error("bad argument #3 (expected string, got " .. type(background) .. ")", 2)
        end

        if text:len() ~= color:len() or color:len() ~= background:len() then
            error("bad arguments #1 #2 #3 (expected same length, got " .. text:len() .. ", " .. color:len() .. " and " .. background:len() .. ")", 2)
        end

        blit(text, color, background)
    end

    --- Append text to this terminal using the terminals text and background color.
    --- @param text string the text to write.
    function terminal.write(text)
        if type(text) ~= "string" then
            text = tostring(text)
        end

        blit(text, cText:rep(text:len()), cBackground:rep(text:len()))
    end

    return terminal
end