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

--- Creates a new window table object.
--- @param wTerm table the parent terminal.
--- @param wPosX nil|number the window's x position.
--- @param wPosY nil|number the window's y position.
--- @param wWidth nil|number the window's width.
--- @param wHeight nil|number the window's height.
--- @param wTitle nil|string the window's title.
--- @return table the created window table.
function create(wTerm, wPosX, wPosY, wWidth, wHeight, wTitle)
    if type(wTerm) ~= "table" then
        error("bad argument #1 (expected table, got " .. type(wTerm) .. ")", 2)
    end

    if not wTerm.isColor() then
        error("bad argument #1 (expected color supported terminal, got colorless terminal)", 2)
    end

    local wOffset, wPadding = 3, 1

    do
        local maxWidth, maxHeight = wTerm.getSize()

        if maxWidth < wOffset * 2 then
            error("bad argument #1 (expected width greater than or equal " .. wOffset * 2 .. ", got " .. maxWidth .. ")", 2)
        end

        -- Magic value '3': Corresponds to two required border lines and one additional content line
        if maxHeight < (wPadding * 2) + 3 then
            error("bad argument #1 (expected height greater than or equal " .. (wPadding * 2) + 3 .. ", got " .. maxHeight .. ")", 2)
        end

        if wPosX ~= nil then
            if type(wPosX) ~= "number" then
                error("bad argument #2 (expected number, got " .. type(wPosX) .. ")", 2)
            end

            if wPosX < 1 or wPosX > maxWidth - (wOffset * 2) + 1 then
                error("bad argument #2 (expected position between 1 and " .. maxWidth - (wOffset * 2) + 1 .. ", got " .. wPosX .. ")", 2)
            end
        else
            wPosX = 1
        end

        if wPosY ~= nil then
            if type(wPosY) ~= "number" then
                error("bad argument #3 (expected number, got " .. type(wPosY) .. ")", 2)
            end

            if wPosY < 1 or wPosY > maxHeight - (wPadding * 2) - 2 then
                error("bad argument #3 (expected position between 1 and " .. maxHeight - (wPadding * 2) - 2 .. ", got " .. wPosY .. ")", 2)
            end
        else
            wPosY = 1
        end

        if wWidth ~= nil then
            if type(wWidth) ~= "number" then
                error("bad argument #4 (expected number, got " .. type(wWidth) .. ")", 2)
            end

            if wWidth < wOffset * 2 or wWidth > maxWidth - (wPosX - 1) then
                error("bad argument #4 (expected width between " .. wOffset * 2 .. " and " .. maxWidth - (wPosX - 1) .. ", got " .. wWidth .. ")", 2)
            end
        else
            wWidth = maxWidth - (wPosX - 1)
        end

        if wHeight ~= nil then
            if type(wHeight) ~= "number" then
                error("bad argument #5 (expected number, got " .. type(wHeight) .. ")", 2)
            end

            -- Magic value '3': Corresponds to two required border lines and one additional content line
            if wHeight < (wPadding * 2) + 3 or wHeight > maxHeight - (wPosY - 1) then
                error("bad argument #5 (expected height between " .. (wPadding * 2) + 3 .. " and " .. maxHeight - (wPosY - 1) .. ", got " .. wHeight .. ")", 2)
            end
        else
            wHeight = maxHeight - (wPosY - 1)
        end

        if wTitle ~= nil then
            if type(wTitle) ~= "string" then
                error("bad argument #6 (expected string, got " .. type(wTitle) .. ")", 2)
            end

            if wTitle:len() > wWidth - (wOffset * 2) then
                error("bad argument #6 (expected length between 0 and " .. wWidth - (wOffset * 2) .. ", got " .. wTitle:len() .. ")", 2)
            end
        else
            wTitle = ""
        end
    end

    local cText, cBackground, cBorder = hex[wTerm.getTextColor()], hex[wTerm.getBackgroundColor()], "7"
    local wCursorX, wCursorY = 1, 1
    local wVisible = false
    local wBorder = {}
    local wLines = {}
    local wConfig

    local function generate()
        wBorder["full"] = {
            ["text"] = string.rep(" ", wWidth),
            ["color"] = cText:rep(wWidth),
            ["background"] = cBorder:rep(wWidth)
        }

        wBorder["empty"] = {
            ["text"] = string.rep(" ", wWidth),
            ["color"] = cText:rep(wWidth),
            ["background"] = cBorder .. cBackground:rep(wWidth - 2) .. cBorder
        }

        if wTitle:len() > 0 then
            local before = math.ceil(wOffset / 2)
            local after = wWidth - wTitle:len() - before - (math.floor(wOffset / 2) * 2)

            wBorder["title"] = {
                ["text"] = string.rep(" ", wOffset) .. wTitle .. string.rep(" ", wWidth - wTitle:len() - wOffset),
                ["color"] = cText:rep(wWidth),
                ["background"] = cBorder:rep(before) .. cBackground:rep(wWidth - before - after) .. cBorder:rep(after)
            }
        else
            wBorder["title"] = wBorder["full"]
        end
    end

    local function clear(line)
        local text, color, background = string.rep(" ", wWidth), hex[wTerm.getTextColor()]:rep(wWidth), hex[wTerm.getBackgroundColor()]:rep(wWidth)
        local oldX, oldY = wTerm.getCursorPos()

        if line == nil then
            for lines = 1, wHeight do
                wTerm.setCursorPos(wPosX, wPosY + (lines - 1))
                wTerm.blit(text, color, background)
            end
        else
            wTerm.setCursorPos(wPosX, wPosY + (line - 1))
            wTerm.blit(text, color, background)
        end

        wTerm.setCursorPos(oldX, oldY)
    end

    local function draw(line)
        if wVisible then
            if line ~= nil then
                local oldX, oldY = wTerm.getCursorPos()

                if wBorder["full"] == nil or wBorder["empty"] == nil or wBorder["title"] == nil then
                    generate()
                end

                wTerm.setCursorPos(wPosX, wPosY + (line - 1))

                if line == 1 then
                    wTerm.blit(wBorder["title"].text, wBorder["title"].color, wBorder["title"].background)
                elseif line == wHeight then
                    wTerm.blit(wBorder["full"].text, wBorder["full"].color, wBorder["full"].background)
                else
                    wTerm.blit(wBorder["empty"].text, wBorder["empty"].color, wBorder["empty"].background)

                    if line > 1 + wPadding and line < wHeight - wPadding then
                        local content = line - 1 - wPadding

                        if wLines[content] ~= nil then
                            wTerm.setCursorPos(wPosX + 1 + wPadding, wPosY + (line - 1))
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

    local function empty(line)
        local width = wWidth - 2 - (wPadding * 2)
        local text, color, background = string.rep(" ", width), cText:rep(width), cBackground:rep(width)

        if line == nil then
            for _, content in pairs(wLines) do
                content["text"] = text
                content["color"] = color
                content["background"] = background
            end
        else
            wLines[line] = {
                ["text"] = text,
                ["color"] = color,
                ["background"] = background
            }
        end
    end

    local function blit(text, color, background)
        local start = wCursorX
        local stop = start + text:len() - 1
        local width = wWidth - 2 - (wPadding * 2)

        if wCursorY >= 1 and wCursorY <= (wHeight - 2) - (wPadding * 2) then
            if start <= width and stop >= 1 and stop > start then
                if wLines[wCursorY] == nil then
                    empty(wCursorY)
                end

                local line = wLines[wCursorY]

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

                wCursorX = stop + 1
                wLines[wCursorY] = {
                    ["text"] = text,
                    ["color"] = color,
                    ["background"] = background
                }

                draw(wCursorY + 1 + wPadding)
            end
        end
    end

    local function recolor(color, background)
        for _, content in pairs(wLines) do
            if color ~= nil then
                content.color = content.color:gsub(cText, hex[color])
            end

            if background ~= nil then
                content.background = content.background:gsub(cBackground, hex[background])
            end
        end
    end

    local function resize()
        local width, height = wWidth - 2 - (wPadding * 2), wHeight - 2 - (wPadding * 2)
        local lines = {}

        for line, content in pairs(wLines) do
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

        wLines = lines
    end

    local function load(key, method)
        if wConfig ~= nil and wConfig.contains(key) then
            local success, message = pcall(method, wConfig.get(key))

            if not success then
                error("bad configuration #" .. key .. " (" .. message:gsub(".*%((.+)%)", "%1") .. ")", 3)
            end
        end
    end

    local function save(key, value)
        if wConfig ~= nil and wConfig.get(key) ~= value then
            wConfig.set(key, value)
            wConfig.save()
        end

        return value
    end

    --                           --
    --   Window Implementation   --
    --                           --

    local window = {}

    --- Gets the title of this window.
    --- @return string the title of this window or an empty string.
    function window.getTitle()
        return wTitle
    end

    --- Sets the title of this window.
    --- @param title string the new title for this window.
    --- @return boolean true when the title was changed, false otherwise.
    function window.setTitle(title)
        if type(title) ~= "string" then
            error("bad argument #1 (expected string, got " .. type(title) .. ")", 2)
        end

        if title:len() > wWidth - (wOffset * 2) then
            error("bad argument #6 (expected length between 0 and " .. wWidth - (wOffset * 2) .. ", got " .. wTitle:len() .. ")", 2)
        end

        if title ~= wTitle then
            wTitle = save("title", title)
            generate()
            draw(1)

            return true
        end

        return false
    end

    --- Gets the title offset of this window.
    --- @return number the title offset.
    function window.getOffset()
        return wOffset
    end

    --- Sets the title offset for this window.
    --- @param offset number the new title offset.
    --- @return boolean true when the offset was changed, false otherwise.
    function window.setOffset(offset)
        if type(offset) ~= "number" then
            error("bad argument #1 (expected number, got " .. type(offset) .. ")", 2)
        end

        if offset < 2 or offset * 2 > wWidth - wTitle:len() then
            error("bad argument #1 (expected offset between 2 and " .. math.floor((wWidth - wTitle:len()) / 2) .. ", got " .. offset .. ")", 2)
        end

        if offset ~= wOffset then
            wOffset = save("offset", offset)
            generate()
            draw(1)

            return true
        end

        return false
    end

    --- Gets the position, without border, of this window.
    --- @return number, number the windows's x and y position without border.
    function window.getPosition()
        return wPosX + 1 + wPadding, wPosY + 1 + wPadding
    end

    --- Gets the x position of this window.
    --- @return number the window's x position.
    function window.getPosX()
        return wPosX
    end

    --- Sets the x position of this window.
    --- @param posX number the new x position.
    --- @return boolean true when the x position was changed, false otherwise.
    function window.setPosX(posX)
        if type(posX) ~= "number" then
            error("bad argument #1 (expected number, got " .. type(posX) .. ")", 2)
        end

        local maxWidth, _ = wTerm.getSize()

        if maxWidth < wOffset * 2 then
            error("bad terminal (expected width greater than or equal " .. wOffset * 2 .. ", got " .. maxWidth .. ")", 0)
        end

        if posX < 1 or posX > maxWidth - (wOffset * 2) + 1 then
            error("bad argument #2 (expected position between 1 and " .. maxWidth - (wOffset * 2) + 1 .. ", got " .. posX .. ")", 2)
        end

        if posX ~= wPosX then
            clear()
            wPosX = save("pos-x", posX)
            draw()

            return true
        end

        return false
    end

    --- Gets the y position of this window.
    --- @return number the window's y position.
    function window.getPosY()
        return wPosY
    end

    --- Sets the y position of this window.
    --- @param posY number the new y position.
    --- @return boolean true when the y position was changed, false otherwise.
    function window.setPosY(posY)
        if type(posY) ~= "number" then
            error("bad argument #1 (expected number, got " .. type(posY) .. ")", 2)
        end

        local _, maxHeight = wTerm.getSize()

        -- Magic value '3': Corresponds to two required border lines and one additional content line
        if maxHeight < (wPadding * 2) + 3 then
            error("bad terminal (expected height greater than or equal " .. (wPadding * 2) + 3 .. ", got " .. maxHeight .. ")", 2)
        end

        -- Magic value '2': Corresponds to two required border lines
        if posY < 1 or posY > maxHeight - (wPadding * 2) - 2 then
            error("bad argument #3 (expected position between 1 and " .. maxHeight - (wPadding * 2) - 2 .. ", got " .. posY .. ")", 2)
        end

        if posY ~= wPosY then
            clear()
            wPosY = save("pos-y", posY)
            draw()

            return true
        end

        return false
    end

    --- Gets the size, without border, of this window.
    --- @return number, number the window's width and height without border.
    function window.getSize()
        return wWidth - 2 - (wPadding * 2), wHeight - 2 - (wPadding * 2)
    end

    --- Gets the width of this window.
    --- @return number the window's width.
    function window.getWidth()
        return wWidth
    end

    --- Sets the width of this window.
    --- @param width number the new width.
    --- @return boolean true when the width was changed, false otherwise.
    function window.setWidth(width)
        if type(width) ~= "number" then
            error("bad argument #1 (expected number, got " .. type(width) .. ")", 2)
        end

        local maxWidth, _ = wTerm.getSize()

        if maxWidth < wOffset * 2 then
            error("bad terminal (expected width greater than or equal " .. wOffset * 2 .. ", got " .. maxWidth .. ")", 0)
        end

        if width < wOffset * 2 or width > maxWidth - (wPosX - 1) then
            error("bad argument #4 (expected width between " .. wOffset * 2 .. " and " .. maxWidth - (wPosX - 1) .. ", got " .. width .. ")", 2)
        end

        if width ~= wWidth then
            clear()
            wWidth = save("width", width)
            generate()
            resize()
            draw()

            return true
        end

        return false
    end

    --- Gets the height of this window.
    --- @return number the window's height.
    function window.getHeight()
        return wHeight
    end

    --- Sets the height of this window.
    --- @param height number the new height.
    --- @return boolean true when the height was changed, false otherwise.
    function window.setHeight(height)
        if type(height) ~= "number" then
            error("bad argument #1 (expected number, got " .. type(height) .. ")", 2)
        end

        local _, maxHeight = wTerm.getSize()

        -- Magic value '3': Corresponds to two required border lines and one additional content line
        if maxHeight < (wPadding * 2) + 3 then
            error("bad terminal (expected height greater than or equal " .. (wPadding * 2) + 3 .. ", got " .. maxHeight .. ")", 2)
        end

        -- Magic value '3': Corresponds to two required border lines and one additional content line
        if height < (wPadding * 2) + 3 or height > maxHeight - (wPosY - 1) then
            error("bad argument #5 (expected height between " .. (wPadding * 2) + 3 .. " and " .. maxHeight - (wPosY - 1) .. ", got " .. height .. ")", 2)
        end

        if height ~= wHeight then
            clear()
            wHeight = save("height", height)
            generate()
            resize()
            draw()

            return true
        end

        return false
    end

    --- Gets the padding of this window.
    --- @return number the window's padding.
    function window.getPadding()
        return wPadding
    end

    --- Sets the padding of this window.
    --- @param padding number the new padding.
    --- @return boolean true when the padding was changed, false otherwise.
    function window.setPadding(padding)
        if type(padding) ~= "number" then
            error("bad argument #1 (expected number, got " .. type(padding) .. ")", 2)
        end

        if padding < 0 or padding * 2 > math.min(wWidth - 2, wHeight - 2) then
            error("bad argument #1 (expected padding between 0 and " .. math.floor(math.min(wWidth - 2, wHeight - 2) / 2) .. ", got " .. padding .. ")", 2)
        end

        if padding ~= wPadding then
            clear()
            wPadding = save("padding", padding)
            resize()
            draw()

            return true
        end

        return false
    end

    --- Gets the text color of this window.
    --- @return number the color code of the text color.
    function window.getTextColor()
        return 2 ^ tonumber(cText, 16)
    end

    --- Sets the text color of this window.
    --- @param color number|string the new color, represented by the color code or hex value.
    --- @return boolean true when the color was changed, false otherwise.
    function window.setTextColor(color)
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

    --- Gets the background color of this window.
    --- @return number the color code of the background color.
    function window.getBackgroundColor()
        return 2 ^ tonumber(cBackground, 16)
    end

    --- Sets the background color of this window.
    --- @param color number|string the new color, represented by the color code or hex value.
    --- @return boolean true when the color was changed, false otherwise.
    function window.setBackgroundColor(color)
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

    --- Gets the border color of this window.
    --- @return number the color code of the border color.
    function window.getBorderColor()
        return 2 ^ tonumber(cBorder, 16)
    end

    --- Sets the border color of this window.
    --- @param color number|string the new color, represented by the color code or hex value.
    --- @return boolean true when the color was changed, false otherwise.
    function window.setBorderColor(color)
        if type(color) ~= "number" and type(color) ~= "string" then
            error("bad argument #1 (expected number or string, got " .. type(color) .. ")", 2)
        end

        if type(color) == "string" then
            color = 2 ^ tonumber(color, 16)
        end

        if hex[color] == nil then
            error("bad argument #1 (expected color code, got " .. color .. ")", 2)
        end

        if hex[color] ~= cBorder then
            cBorder = save("color.border", hex[color])
            generate()
            draw()

            return true
        end

        return false
    end

    --- Gets whether this window is visible.
    --- @return boolean true when it is visible, false otherwise.
    function window.getVisible()
        return wVisible
    end

    --- Sets whether this window is visible.
    --- @param visible boolean whether it should be visible.
    --- @return boolean true when the visibility was changed, false otherwise.
    function window.setVisible(visible)
        if type(visible) ~= "boolean" then
            error("bad argument #1 (expected boolean, got " .. type(visible) .. ")", 2)
        end

        if visible ~= wVisible then
            wVisible = save("visible", visible)

            if visible then
                draw()
            else
                clear()
            end

            return true
        end

        return false
    end

    --- Gets the current cursor position, without border, of this window.
    --- @return number, number the current position of the cursor.
    function window.getCursorPos()
        return wCursorX, wCursorY
    end

    --- Sets the cursor position of this window.
    --- @param posX number|nil the new x position or nil.
    --- @param posY number|nil the new y position or nil.
    function window.setCursorPos(posX, posY)
        if posX ~= nil then
            if type(posX) ~= "number" then
                error("bad argument #1 (expected number, got " .. type(posX) .. ")", 2)
            end

            wCursorX = math.floor(posX)
        end

        if posY ~= nil then
            if type(posY) ~= "number" then
                error("bad argument #1 (expected number, got " .. type(posY) .. ")", 2)
            end

            wCursorY = math.floor(posY)
        end
    end

    --- Loads this window from the configuration file at the specified path.
    --- @param path string the path to the configuration file.
    --- @return boolean true when the configuration was loaded, false otherwise.
    function window.load(path)
        if path ~= nil and type(path) ~= "string" or path == nil and wConfig == nil then
            error("bad argument #1 (expected string, got " .. type(path) .. ")", 2)
        end

        if path ~= nil and (wConfig == nil or wConfig.path() ~= path) then
            wConfig = config.create(path)
        end

        if wConfig.load() then
            load("pos-x", window.setPosX)
            load("pos-y", window.setPosY)
            load("width", window.setWidth)
            load("height", window.setHeight)
            load("offset", window.setOffset)
            load("padding", window.setPadding)
            load("title", window.setTitle)
            load("color.text", window.setTextColor)
            load("color.background", window.setBackgroundColor)
            load("color.border", window.setBorderColor)
            load("visible", window.setVisible)
            window.setCursorPos(wConfig.get("cursor-x"), wConfig.get("cursor-y"))

            return true
        end

        return false
    end

    --- Saves this window to the configuration file at the specified path.
    --- @param path string the path to the configuration file.
    --- @return boolean true when the configuration was saved, false otherwise.
    function window.save(path)
        if path ~= nil and type(path) ~= "string" or path == nil and wConfig == nil then
            error("bad argument #1 (expected string, got " .. type(path) .. ")", 2)
        end

        if path ~= nil and (wConfig == nil or wConfig.path() ~= path) then
            wConfig = config.create(path)

            save("title", wTitle)
            save("pos-x", wPosX)
            save("pos-y", wPosY)
            save("width", wWidth)
            save("height", wHeight)
            save("offset", wOffset)
            save("padding", wPadding)
            save("color.text", cText)
            save("color.background", cBackground)
            save("color.border", cBorder)
            save("visible", wVisible)
            save("cursor-x", wCursorX)
            save("cursor-y", wCursorY)
        end

        return wConfig.save()
    end

    --- Gets whether this window is colored.
    --- @return boolean always true.
    function window.isColor()
        return true
    end

    --- Clears the lines of this window.
    function window.clear()
        wLines = {}
        clear()
        draw()
    end

    --- Clears a line of this window.
    --- @param line nil|number the line to clear.
    function window.clearLine(line)
        if line ~= nil then
            if type(line) ~= "number" then
                error("bad argument #1 (expected number, got " .. type(line) .. ")", 2)
            end
        else
            line = wCursorY
        end

        if wLines[line] ~= nil then
            wLines[line] = nil

            clear(line + 1 + wPadding)
            draw(line + 1 + wPadding)
        end
    end

    --- Draws the lines to the window.
    function window.redraw()
        clear()
        draw()
    end

    --- Draws a line to this window.
    --- @param line nil|number the line to draw.
    function window.redrawLine(line)
        if line ~= nil then
            if type(line) ~= "number" then
                error("bad argument #1 (expected number, got " .. type(line) .. ")", 2)
            end
        else
            line = wCursorY
        end

        if wLines[line] ~= nil then
            clear(line + 1 + wPadding)
            draw(line + 1 + wPadding)
        end
    end

    --- Append text to this window using the specified text and background color.
    --- @param text string the text to write.
    --- @param color string the color string containing valid hexadecimal color values in length of the text.
    --- @param background string the background string containing valid hexadecimal color values in length of the text.
    function window.blit(text, color, background)
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

    --- Append text to this window using the terminals text and background color.
    --- @param text string the text to write.
    function window.write(text)
        if type(text) ~= "string" then
            text = tostring(text)
        end

        blit(text, cText:rep(text:len()), cBackground:rep(text:len()))
    end

    return window
end
