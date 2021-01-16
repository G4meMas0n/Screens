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

--- Creates a new button table object.
--- @param bTerm table the parent terminal, window or monitor.
--- @param bPosX nil|number the button's x position.
--- @param bPosY nil|number the button's y position.
--- @param bWidth nil|number the button's width.
--- @param bHeight nil|number the button's height.
--- @param bTitle nil|string the button's title.
--- @return table the created button table.
function create(bTerm, bPosX, bPosY, bWidth, bHeight, bTitle)
    if type(bTerm) ~= "table" then
        error("bad argument #1 (expected table, got " .. type(bTerm) .. ")", 2)
    end

    if not bTerm.isColor() then
        error("bad argument #1 (expected color supported terminal, got colorless terminal)", 2)
    end

    do
        local maxWidth, maxHeight = bTerm.getSize()

        if bPosX ~= nil then
            if type(bPosX) ~= "number" then
                error("bad argument #2 (expected number, got " .. type(bPosX) .. ")", 2)
            end

            if bPosX < 1 or bPosX > maxWidth then
                error("bad argument #2 (expected position between 1 and " .. maxWidth .. ", got " .. bPosX .. ")", 2)
            end
        else
            bPosX = 1
        end

        if bPosY ~= nil then
            if type(bPosY) ~= "number" then
                error("bad argument #3 (expected number, got " .. type(bPosY) .. ")", 2)
            end

            if bPosY < 1 or bPosY > maxHeight then
                error("bad argument #3 (expected position between 1 and " .. maxHeight .. ", got " .. bPosY .. ")", 2)
            end
        else
            bPosY = 1
        end

        if bWidth ~= nil then
            if type(bWidth) ~= "number" then
                error("bad argument #4 (expected number, got " .. type(bWidth) .. ")", 2)
            end

            if bWidth < 0 or bWidth > maxWidth - (bPosX - 1) then
                error("bad argument #4 (expected width between 0 and " .. maxWidth - (bPosX - 1) .. ", got " .. bWidth .. ")", 2)
            end
        else
            bWidth = 0
        end

        if bHeight ~= nil then
            if type(bHeight) ~= "number" then
                error("bad argument #5 (expected number, got " .. type(bHeight) .. ")", 2)
            end

            if bHeight < 0 or bHeight > maxHeight - (bPosY - 1) then
                error("bad argument #5 (expected height between 0 and " .. maxHeight - (bPosY - 1) .. ", got " .. bHeight .. ")", 2)
            end
        else
            bHeight = 0
        end

        if bTitle ~= nil then
            if type(bTitle) ~= "string" then
                error("bad argument #6 (expected string, got " .. type(bTitle) .. ")", 2)
            end

            if bTitle:len() > bWidth then
                error("bad argument #6 (expected title length between 0 and " .. bWidth .. ", got " .. bTitle:len() .. ")", 2)
            end
        else
            bTitle = ""
        end
    end

    local caText, caBackground = "0", "d"
    local ciText, ciBackground = "0", "e"
    local bActive, bVisible = false, false
    local bAction, bConfig

    local function clear(line)
        local text, color, background = string.rep(" ", bWidth), hex[bTerm.getTextColor()]:rep(bWidth), hex[bTerm.getBackgroundColor()]:rep(bWidth)
        local oldX, oldY = bTerm.getCursorPos()

        if line == nil then
            for lines = 1, bHeight do
                bTerm.setCursorPos(bPosX, bPosY + (lines - 1))
                bTerm.blit(text, color, background)
            end
        else
            bTerm.setCursorPos(bPosX, bPosY + (line - 1))
            bTerm.blit(text, color, background)
        end

        bTerm.setCursorPos(oldX, oldY)
    end

    local function draw(line)
        if bVisible then
            if line ~= nil then
                local oldX, oldY = bTerm.getCursorPos()
                local text = string.rep(" ", bWidth)

                if line == math.ceil(bHeight / 2) and bTitle:len() > 0 then
                    local gap = (bWidth - bTitle:len()) / 2

                    text = string.rep(" ", math.floor(gap)) .. bTitle .. string.rep(" ", math.ceil(gap))
                end

                bTerm.setCursorPos(bPosX, bPosY + (line - 1))

                if bActive then
                    bTerm.blit(text, caText:rep(bWidth), caBackground:rep(bWidth))
                else
                    bTerm.blit(text, ciText:rep(bWidth), ciBackground:rep(bWidth))
                end

                bTerm.setCursorPos(oldX, oldY)
            else
                for lines = 1, bHeight do
                    draw(lines)
                end
            end
        end
    end

    local function load(key, method)
        if bConfig ~= nil and bConfig.contains(key) then
            local success, message = pcall(method, bConfig.get(key))

            if not success then
                error("bad configuration #" .. key .. " (" .. message:gsub(".*%((.+)%)", "%1") .. ")", 3)
            end
        end
    end

    local function save(key, value)
        if bConfig ~= nil and bConfig.get(key) ~= value then
            bConfig.set(key, value)
            bConfig.save()
        end

        return value
    end

    --                           --
    --   Button Implementation   --
    --                           --

    local button = {}

    --- Gets the title of this button.
    --- @return string the name of this button or an empty string.
    function button.getTitle()
        return bTitle
    end

    --- Sets the name of this button.
    --- @param new string the new name for this button.
    --- @return boolean true when the title was changed, false otherwise.
    function button.setTitle(new)
        if type(new) ~= "string" then
            error("bad argument #1 (expected string, got " .. type(new) .. ")", 2)
        end

        if new:len() > bWidth then
            error("bad argument #1 (expected length between 0 and " .. bWidth .. ", got " .. new:len() .. ")", 2)
        end

        if new ~= bTitle then
            bTitle = save("title", new)
            draw(math.ceil(bHeight / 2))

            return true
        end

        return false
    end

    --- Gets the position of this button.
    --- @return number, number the button's x and y position.
    function button.getPosition()
        return bPosX, bPosY
    end

    --- Gets the x position of this button.
    --- @return number the button's x position.
    function button.getPosX()
        return bPosX
    end

    --- Sets the x position of this button.
    --- @param posX number the new x position.
    --- @return boolean true when the x position was changed, false otherwise.
    function button.setPosX(posX)
        if type(posX) ~= "number" then
            error("bad argument #1 (expected number, got " .. type(position) .. ")", 2)
        end

        local maxWidth, _ = bTerm.getSize()

        if posX < 1 or posX > maxWidth - bWidth then
            error("bad argument #2 (expected position between 1 and " .. maxWidth - bWidth .. ", got " .. posX .. ")", 2)
        end

        if posX ~= bPosX then
            clear()
            bPosX = save("pos-x", posX)
            draw()

            return true
        end

        return false
    end

    --- Gets the y position of this button.
    --- @return number the button's y position.
    function button.getPosY()
        return bPosY
    end

    --- Sets the y position of this terminal.
    --- @param posY number the new y position.
    --- @return boolean true when the y position was changed, false otherwise.
    function button.setPosY(posY)
        if type(posY) ~= "number" then
            error("bad argument #1 (expected number, got " .. type(posY) .. ")", 2)
        end

        local _, maxHeight = bTerm.getSize()

        if posY < 1 or posY > maxHeight - bHeight then
            error("bad argument #2 (expected position between 1 and " .. maxHeight - bHeight .. ", got " .. posY .. ")", 2)
        end

        if posY ~= bPosY then
            clear()
            bPosY = save("pos-y", posY)
            draw()

            return true
        end

        return false
    end

    --- Gets the size of this button.
    --- @return number, number the button's width and height.
    function button.getSize()
        return bWidth, bHeight
    end

    --- Gets the width of this button.
    --- @return number the button's width.
    function button.getWidth()
        return bWidth
    end

    --- Sets the width of this button.
    --- @param width number the new width.
    --- @return boolean true when the width was changed, false otherwise.
    function button.setWidth(width)
        if type(width) ~= "number" then
            error("bad argument #1 (expected number, got " .. type(width) .. ")", 2)
        end

        local maxWidth, _ = bTerm.getSize()

        if width < 0 or width > maxWidth - (bPosX - 1) then
            error("bad argument #1 (expected width between 0 and " .. (maxWidth - (bPosX - 1)) .. ", got " .. width .. ")", 2)
        end

        if bTitle:len() > 0 and width < bTitle:len() then
            error("bad argument #1 (expected width between " .. bTitle:len() .. " and " .. (maxWidth - (bPosX - 1)) .. ", got " .. width .. ")", 2)
        end

        if width ~= bWidth then
            clear()
            bWidth = save("width", width)
            draw()

            return true
        end

        return false
    end

    --- Gets the height of this button.
    --- @return number the button's height.
    function button.getHeight()
        return bHeight
    end

    --- Sets the height of this button.
    --- @param height number the new height.
    --- @return boolean true when the height was changed, false otherwise.
    function button.setHeight(height)
        if type(height) ~= "number" then
            error("bad argument #1 (expected number, got " .. type(height) .. ")", 2)
        end

        local _, maxHeight = bTerm.getSize()

        if height < 0 and height > maxHeight - (bPosY - 1) then
            error("bad argument #1 (expected height between 0 and " .. (maxHeight - (bPosX - 1)) .. ", got " .. height .. ")", 2)
        end

        if height ~= bHeight then
            clear()
            bHeight = save("height", height)
            draw()

            return true
        end

        return false
    end

    --- Gets the active text color of this button.
    --- @return number the color code of the active text color.
    function button.getActiveTextColor()
        return 2 ^ tonumber(caText, 16)
    end

    --- Sets the active text color of this button.
    --- @param color number|string the new color, represented by the color code or hex value.
    --- @return boolean true when the color was changed, false otherwise.
    function button.setActiveTextColor(color)
        if type(color) ~= "number" and type(color) ~= "string" then
            error("bad argument #1 (expected number or string, got " .. type(color) .. ")", 2)
        end

        if type(color) == "string" then
            color = 2 ^ tonumber(color, 16)
        end

        if hex[color] == nil then
            error("bad argument #1 (expected color code, got " .. color .. ")", 2)
        end

        if hex[color] ~= caText then
            caText = save("color-active-text", hex[color])
            draw()

            return true
        end

        return false
    end

    --- Gets the active background color of this button.
    --- @return number the color code of the active background color.
    function button.getActiveBackgroundColor()
        return 2 ^ tonumber(caBackground, 16)
    end

    --- Sets the active background color of this button.
    --- @param color number|string the new color, represented by the color code or hex value.
    --- @return boolean true when the color was changed, false otherwise.
    function button.setActiveBackgroundColor(color)
        if type(color) ~= "number" and type(color) ~= "string" then
            error("bad argument #1 (expected number or string, got " .. type(color) .. ")", 2)
        end

        if type(color) == "string" then
            color = 2 ^ tonumber(color, 16)
        end

        if hex[color] == nil then
            error("bad argument #1 (expected color code, got " .. color .. ")", 2)
        end

        if hex[color] ~= caBackground then
            caBackground = save("color-active-background", hex[color])
            draw()

            return true
        end

        return false
    end

    --- Gets the inactive text color of this button.
    --- @return number the color code of the inactive text color.
    function button.getInactiveTextColor()
        return 2 ^ tonumber(ciText, 16)
    end

    --- Sets the inactive text color of this button.
    --- @param color number|string the new color, represented by the color code or hex value.
    --- @return boolean true when the color was changed, false otherwise.
    function button.setInactiveTextColor(color)
        if type(color) ~= "number" and type(color) ~= "string" then
            error("bad argument #1 (expected number or string, got " .. type(color) .. ")", 2)
        end

        if type(color) == "string" then
            color = 2 ^ tonumber(color, 16)
        end

        if hex[color] == nil then
            error("bad argument #1 (expected color code, got " .. color .. ")", 2)
        end

        if hex[color] ~= ciText then
            ciText = save("color-inactive-text", hex[color])
            draw()

            return true
        end

        return false
    end

    --- Gets the inactive background color of this button.
    --- @return number the color code of the inactive background color.
    function button.getInactiveBackgroundColor()
        return 2 ^ tonumber(ciBackground, 16)
    end

    --- Sets the inactive background color of this button.
    --- @param color number|string the new color, represented by the color code or hex value.
    --- @return boolean true when the color was changed, false otherwise.
    function button.setInactiveBackgroundColor(color)
        if type(color) ~= "number" and type(color) ~= "string" then
            error("bad argument #1 (expected number or string, got " .. type(color) .. ")", 2)
        end

        if type(color) == "string" then
            color = 2 ^ tonumber(color, 16)
        end

        if hex[color] == nil then
            error("bad argument #1 (expected color code, got " .. color .. ")", 2)
        end

        if hex[color] ~= ciBackground then
            ciBackground = save("color-inactive-background", hex[color])
            draw()

            return true
        end

        return false
    end

    --- Gets whether this button is active.
    --- @return boolean true when it is active, false otherwise.
    function button.getActive()
        return bActive
    end

    --- Sets whether this button is active.
    --- @param active boolean whether it should be active.
    --- @return boolean true when the state was changed, false otherwise.
    function button.setActive(active)
        if type(active) ~= "boolean" then
            error("bad argument #1 (expected boolean, got " .. type(active) .. ")", 2)
        end

        if active ~= bActive then
            bActive = save("active", active)
            draw()

            return true
        end

        return false
    end

    --- Gets whether this button is visible.
    --- @return boolean true when it is visible, false otherwise.
    function button.getVisible()
        return bVisible
    end

    --- Sets whether this button is visible.
    --- @param visible boolean whether it should be visible.
    --- @return boolean true when the visibility was changed, false otherwise.
    function button.setVisible(visible)
        if type(visible) ~= "boolean" then
            error("bad argument #1 (expected boolean, got " .. type(visible) .. ")", 2)
        end

        if visible ~= bVisible then
            bVisible = save("visible", visible)

            if visible then
                draw()
            else
                clear()
            end

            return true
        end

        return false
    end

    --- Loads this button from the configuration file at the specified path.
    --- @param path string the path to the configuration file.
    --- @return boolean true when the configuration was loaded, false otherwise.
    function button.load(path)
        if path ~= nil and type(path) ~= "string" or path == nil and bConfig == nil then
            error("bad argument #1 (expected string, got " .. type(path) .. ")", 2)
        end

        if path ~= nil and (bConfig == nil or bConfig.path() ~= path) then
            bConfig = config.create(path)
        end

        if bConfig.load() then
            load("pos-x", button.setPosX)
            load("pos-y", button.setPosY)
            load("width", button.setWidth)
            load("height", button.setHeight)
            load("title", button.setTitle)
            load("color-active-text", button.setActiveTextColor)
            load("color-active-background", button.setActiveBackgroundColor)
            load("color-inactive-text", button.setInactiveTextColor)
            load("color-inactive-background", button.setInactiveBackgroundColor)
            load("active", button.setActive)
            load("visible", button.setVisible)

            return true
        end

        return false
    end

    --- Saves this button to the configuration file at the specified path.
    --- @param path string the path to the configuration file.
    --- @return boolean true when the configuration was saved, false otherwise.
    function button.save(path)
        if path ~= nil and type(path) ~= "string" or path == nil and bConfig == nil then
            error("bad argument #1 (expected string, got " .. type(path) .. ")", 2)
        end

        if path ~= nil and (bConfig == nil or bConfig.path() ~= path) then
            bConfig = config.create(path)

            save("title", bTitle)
            save("pos-x", bPosX)
            save("pos-y", bPosY)
            save("width", bWidth)
            save("height", bHeight)
            save("color-active-text", caText)
            save("color-active-background", caBackground)
            save("color-inactive-text", ciText)
            save("color-inactive-background", ciBackground)
            save("active", bActive)
            save("visible", bVisible)
        end

        return bConfig.save()
    end

    --- Checks whether the given position is in range of this button.
    --- @return boolean true, when the position is in range, false otherwise.
    function button.range(posX, posY)
        if type(posX) ~= "number" then
            error("bad argument #1 (expected number, got " .. type(posX) .. ")", 2)
        end

        if type(posY) ~= "number" then
            error("bad argument #2 (expected number, got " .. type(posY) .. ")", 2)
        end

        if bVisible then
            if posX >= bPosX and posX < bPosX + bWidth then
                if posY >= bPosY and posY < bPosY + bHeight then
                    return true
                end
            end
        end

        return false
    end

    --- Draws the button to the button.
    function button.redraw()
        clear()
        draw()
    end

    --- Performs the actions of this button.
    function button.press()
        if bActive then
            button.setActive(false)
        else
            button.setActive(true)
        end
    end
end