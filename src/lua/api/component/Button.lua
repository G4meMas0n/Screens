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

--- Default settings for this button table object.
local defaults = {
    ["title"] = "",
    ["pos-x"] = 1,
    ["pos-y"] = 1,
    ["width"] = 0,
    ["height"] = 0,
    ["color"] = {
        ["active"] = {
            ["text"] = "0",
            ["background"] = "d"
        },
        ["inactive"] = {
            ["text"] = "0",
            ["background"] = "e"
        }
    },
    ["action"] = {},
    ["active"] = false,
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

--- Creates a new Button table object.
--- @param terminal table the parent terminal, window or monitor.
--- @param x        nil|number the x position of the button.
--- @param y        nil|number the y position of the button.
--- @param width    nil|number the width of the button.
--- @param height   nil|number the height of the button.
--- @param title    nil|string the title of this button.
--- @return table the created button table.
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
    local bPosX = defaults["pos-x"]
    local bPosY = defaults["pos-y"]

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

            bPosX = x
            bPosY = y
        else
            error("bad arguments #2 #3 (expected number and number, got " .. type(x) .. " and " .. type(y) .. ")", 2)
        end
    end

    local bWidth = defaults["width"]
    local bHeight = defaults["height"]

    if width ~= nil or height ~= nil then
        -- Check if both width and height is given:
        if width ~= nil and height ~= nil then
            -- Check correctness of width and height:
            if width < 0 or width > maxWidth - (bPosX - 1) then
                error("bad argument #4 (expected width between 0 and " .. (maxWidth - (bPosX - 1)) .. ", got " .. width .. ")", 2)
            end

            if height < 0 or height > maxHeight - (bPosY - 1) then
                error("bad argument #5 (expected height between 0 and " .. (maxHeight - (bPosY - 1)) .. ", got " .. height .. ")", 2)
            end

            bWidth = width
            bHeight = height
        else
            error("bad arguments #4 #5 (expected number and number, got " .. type(width) .. " and " .. type(height) .. ")", 2)
        end
    end

    local bTitle = defaults["title"]

    if title ~= nil then
        -- Check correctness of title:
        if string.len(title) > bWidth then
            error("bad argument #6 (expected title length between 0 and " .. bWidth .. ", got " .. string.len(title) .. ")", 2)
        end

        bTitle = title
    end

    local bTerm = terminal

    local bColor = defaults["color"]
    local bAction = defaults["action"]

    local bActive = defaults["active"]
    local bVisible = defaults["visible"]

    local bConfig

    --- Clears lines of this button of the terminal.
    local function clear(line)
        -- Cache cleared lines before writing it to the terminal:
        local color = hex[bTerm.getTextColor()]
        local background = hex[bTerm.getBackgroundColor()]

        -- Cache old cursor position of terminal
        local oldX, oldY = bTerm.getCursorPos()

        if line == nil then
            for lines = 1, bHeight do
                bTerm.setCursorPos(bPosX, bPosY + (lines - 1))
                bTerm.blit(string.rep(" ", bWidth), string.rep(color, bWidth), string.len(background, bWidth))
            end
        else
            bTerm.setCursorPos(bPosX, bPosY + (line - 1))
            bTerm.blit(string.rep(" ", bWidth), string.rep(color, bWidth), string.len(background, bWidth))
        end

        bTerm.setCursorPos(oldX, oldY)
    end

    --- Draws lines of this button to the terminal.
    local function draw(line)
        if bVisible then
            if line ~= nil then
                local oldX, oldY = bTerm.getCursorPos()
                local text = string.rep(" ", bWidth)

                if line == math.ceil(bHeight / 2) and string.len(bTitle) > 0 then
                    local gap = (bWidth - string.len(bTitle)) / 2

                    text = string.rep(" ", math.floor(gap)) .. bTitle .. string.rep(" ", math.ceil(gap))
                end

                bTerm.setCursorPos(bPosX, bPosY + (line - 1))

                if bActive then
                    bTerm.blit(text, string.rep(bColor["active"]["text"], bWidth), string.rep(bColor["active"]["background"], bWidth))
                else
                    bTerm.blit(text, string.rep(bColor["inactive"]["text"], bWidth), string.rep(bColor["inactive"]["background"], bWidth))
                end

                bTerm.setCursorPos(oldX, oldY)
            else
                for lines = 1, bHeight do
                    draw(lines)
                end
            end
        end
    end

    --- Updates the specified config option of this Button.
    local function update(key, value)
        if bConfig ~= nil then
            local old = bConfig.get(key)

            if old == nil or not equal(old, value) then
                bConfig.set(key, value)
                bConfig.save()
            end
        end
    end

    -- Start of button table implementation:
    local Button = {}

    --- Gets the name of this button.
    --- @return string the name of this button or an empty string.
    function Button.getTitle()
        return bTitle
    end

    --- Sets the name of this button.
    --- @param new string the new name for this button.
    --- @return boolean true when the title was changed, false otherwise.
    function Button.setTitle(new)
        if type(new) ~= "string" then
            error("bad argument #1 (expected title string, got " .. type(new) .. ")", 2)
        end

        if string.len(new) > bWidth then
            error("bad argument #1 (expected title length between 0 and " .. bWidth .. ", got " .. string.len(new) .. ")", 2)
        end

        if new ~= bTitle then
            bTitle = new
            draw(math.ceil(bHeight / 2))
            update("title", bTitle)

            return true
        end

        return false
    end

    --- Gets the position of this button (in the terminal).
    --- @return number, number the x and y position of this button.
    function Button.getPosition()
        return bPosX, bPosY
    end

    --- Gets the x position of this button.
    --- @return number the x position of this button.
    function Button.getPosX()
        return bPosX
    end

    --- Sets the x position of this button.
    --- @param position number the new x position for this button.
    --- @return boolean true when the x position was changed, false otherwise.
    function Button.setPosX(position)
        if type(position) ~= "number" then
            error("bad argument #1 (expected position number, got " .. type(position) .. ")", 2)
        end

        if position < 1 or position > maxWidth - bWidth then
            error("bad argument #2 (expected position between 1 and " .. maxWidth - bWidth .. ", got " .. position .. ")", 2)
        end

        if position ~= bPosX then
            clear()
            bPosX = position
            draw()
            update("pos-x", bPosX)

            return true
        end

        return false
    end

    --- Gets the y position of this button.
    --- @return number the y position of this button.
    function Button.getPosY()
        return bPosY
    end

    --- Sets the y position of this button.
    --- @param position number the new y position for this button.
    --- @return boolean true when the y position was changed, false otherwise.
    function Button.setPosY(position)
        if type(position) ~= "number" then
            error("bad argument #1 (expected position number, got " .. type(position) .. ")", 2)
        end

        if position < 1 or position > maxHeight - bHeight then
            error("bad argument #2 (expected position between 1 and " .. maxHeight - bHeight .. ", got " .. position .. ")", 2)
        end

        if position ~= bPosY then
            clear()
            bPosY = position
            draw()
            update("pos-y", bPosY)

            return true
        end

        return false
    end

    --- Gets the size of this button.
    --- @return number, number the width and the height of this window.
    function Button.getSize()
        return bWidth, bHeight
    end

    --- Gets the width of this button.
    --- @return number the width of this button or zero.
    function Button.getWidth()
        return bWidth
    end

    --- Sets the width of this button.
    --- @param new number the new width for this button.
    --- @return boolean true when the width was changed, false otherwise.
    function Button.setWidth(new)
        if type(new) ~= "number" then
            error("bad argument #1 (expected size number, got " .. type(new) .. ")", 2)
        end

        if new < 0 or new > maxWidth - (bPosX - 1) then
            error("bad argument #1 (expected width between 0 and " .. (maxWidth - (bPosX - 1)) .. ", got " .. new .. ")", 2)
        end

        if string.len(bTitle) > 0 and new < string.len(bTitle) then
            error("bad argument #1 (expected width between " .. string.len(bTitle) .. " and " .. (maxWidth - (bPosX - 1)) .. ", got " .. new .. ")", 2)
        end

        if new ~= bWidth then
            clear()
            bWidth = new
            draw()
            update("width", bWidth)

            return true
        end

        return false
    end

    --- Gets the height of this button.
    --- @return number the height of this button or zero.
    function Button.getHeight()
        return bHeight
    end

    --- Sets the height of this button.
    --- @param new number the new height for this button.
    --- @return boolean true when the height was changed, false otherwise.
    function Button.setHeight(new)
        if type(new) ~= "number" then
            error("bad argument #1 (expected size number, got " .. type(new) .. ")", 2)
        end

        if new < 0 and new > maxHeight - (bPosY - 1) then
            error("bad argument #1 (expected height between 0 and " .. (maxHeight - (bPosX - 1)) .. ", got " .. new .. ")", 2)
        end

        if new ~= bHeight then
            clear()
            bHeight = new
            draw()
            update("height", bHeight)

            return true
        end

        return false
    end

    --- Gets the active text color of this button.
    --- @return number the color code of the active text color.
    function Button.getActiveTextColor()
        return 2 ^ tonumber(bColor["active"]["text"], 16)
    end

    --- Sets the active text color of this button.
    --- @param color number|string the color code or hex value of the new active text color.
    --- @return boolean true when the active text color was changed, false otherwise.
    function Button.setActiveTextColor(color)
        if type(color) ~= "number" and type(color) ~= "string" then
            error("bad argument #1 (expected color number or string, got " .. type(color) .. ")", 2)
        end

        if type(color) == "string" then
            color = 2 ^ tonumber(color, 16)
        end

        if hex[color] == nil then
            error("bad argument #1 (expected color code, got " .. color .. ")", 2)
        end

        if hex[color] ~= bColor["active"]["text"] then
            bColor["active"]["text"] = hex[color]
            draw()
            update("color", bColor)

            return true
        end

        return false
    end

    --- Gets the active background color of this button.
    --- @return number the color code of the active background color.
    function Button.getActiveBackgroundColor()
        return 2 ^ tonumber(bColor["active"]["background"], 16)
    end

    --- Sets the active background color of this button.
    --- @param color number|string the color code or hex value of the new active background color.
    --- @return boolean true when the active background color was changed, false otherwise.
    function Button.setActiveBackgroundColor(color)
        if type(color) ~= "number" and type(color) ~= "string" then
            error("bad argument #1 (expected color number or string, got " .. type(color) .. ")", 2)
        end

        if type(color) == "string" then
            color = 2 ^ tonumber(color, 16)
        end

        if hex[color] == nil then
            error("bad argument #1 (expected color code, got " .. color .. ")", 2)
        end

        if hex[color] ~= bColor["active"]["background"] then
            bColor["active"]["background"] = hex[color]
            draw()
            update("color", bColor)

            return true
        end

        return false
    end

    --- Gets the inactive text color of this button.
    --- @return number the color code of the inactive text color.
    function Button.getInactiveTextColor()
        return 2 ^ tonumber(bColor["inactive"]["text"], 16)
    end

    --- Sets the inactive text color of this button.
    --- @param color number|string the color code or hex value of the new inactive text color.
    --- @return boolean true when the inactive text color was changed, false otherwise.
    function Button.setInactiveTextColor(color)
        if type(color) ~= "number" and type(color) ~= "string" then
            error("bad argument #1 (expected color number or string, got " .. type(color) .. ")", 2)
        end

        if type(color) == "string" then
            color = 2 ^ tonumber(color, 16)
        end

        if hex[color] == nil then
            error("bad argument #1 (expected color code, got " .. color .. ")", 2)
        end

        if hex[color] ~= bColor["inactive"]["text"] then
            bColor["inactive"]["text"] = hex[color]
            draw()
            update("color", bColor)

            return true
        end

        return false
    end

    --- Gets the inactive text color of this button.
    --- @return number the color code of the inactive background color.
    function Button.getInactiveBackgroundColor()
        return 2 ^ tonumber(bColor["inactive"]["background"], 16)
    end

    --- Sets the inactive background color of this button.
    --- @param color number|string the color code or hex value of the new inactive background color.
    --- @return boolean true when the inactive background color was changed, false otherwise.
    function Button.setInactiveBackgroundColor(color)
        if type(color) ~= "number" and type(color) ~= "string" then
            error("bad argument #1 (expected color number or string, got " .. type(color) .. ")", 2)
        end

        if type(color) == "string" then
            color = 2 ^ tonumber(color, 16)
        end

        if hex[color] == nil then
            error("bad argument #1 (expected color code, got " .. color .. ")", 2)
        end

        if hex[color] ~= bColor["inactive"]["background"] then
            bColor["inactive"]["background"] = hex[color]
            draw()
            update("color", bColor)

            return true
        end

        return false
    end

    --- Gets whether this button is active.
    --- @return boolean true when this button is active, false otherwise.
    function Button.getActive()
        return bActive
    end

    --- Sets whether this button is active.
    --- @param active boolean whether this button should be active.
    --- @return boolean true when the activation was changed, false otherwise.
    function Button.setActive(active)
        if type(active) ~= "boolean" then
            error("bad argument #1 (expected boolean, got " .. type(active) .. ")", 2)
        end

        if active ~= bActive then
            bActive = active
            draw()
            update("active", bActive)

            return true
        end

        return false
    end

    --- Gets whether this button is visible.
    --- @return boolean true when this button is visible, false otherwise.
    function Button.getVisible()
        return bVisible
    end

    --- Sets whether this button is visible.
    --- @param visible boolean whether this button should be visible.
    --- @return boolean true when the visibility was changed, false otherwise.
    function Button.setVisible(visible)
        if type(visible) ~= "boolean" then
            error("bad argument #1 (expected boolean, got " .. type(visible) .. ")", 2)
        end

        if visible and not bVisible then
            bVisible = true
            draw()
        elseif not visible and bVisible then
            bVisible = false
            clear()
        else
            return false
        end

        update("visible", bVisible)
        return true
    end

    --- Loads this button from the configuration file at the specified path.
    --- @param path string the path to the configuration file.
    --- @return boolean true when the configuration was loaded, false otherwise.
    function Button.load(path)
        if path ~= nil and type(path) ~= "string" then
            error("bad argument #1 (expected string, got " .. type(path) .. ")", 2)
        end

        if path == nil and bConfig == nil then
            error("bad argument #1 (expected path, got nil)", 2)
        end

        if path ~= nil and (bConfig == nil or bConfig.path() ~= path) then
            bConfig = Configuration.create(path)
        end

        if bConfig.load() then
            if bConfig.contains("pos-x") then
                Button.setPosX(bConfig.get("pos-x"))
            end

            if bConfig.contains("pos-y") then
                Button.setPosY(bConfig.get("pos-y"))
            end

            if bConfig.contains("width") then
                Button.setWidth(bConfig.get("width"))
            end

            if bConfig.contains("height") then
                Button.setHeight(bConfig.get("height"))
            end

            if bConfig.contains("title") then
                Button.setTitle(bConfig.get("title"))
            end

            if bConfig.contains("color") then
                local color = bConfig.get("color")

                if type(color) ~= "table" then
                    error("bad argument #1 (expected color table, got " .. type(color) .. ")", 2)
                end

                if color["active"] ~= nil then
                    local active = color["active"]

                    if type(active) ~= "table" then
                        error("bad argument #1 (expected color active table, got " .. type(active) .. ")", 2)
                    end

                    if active["text"] ~= nil then
                        Button.setActiveTextColor(active["text"])
                    end

                    if active["background"] ~= nil then
                        Button.setActiveBackgroundColor(active["background"])
                    end
                end

                if color["inactive"] ~= nil  then
                    local inactive = color["inactive"]

                    if type(inactive) ~= "table" then
                        error("bad argument #1 (expected color inactive table, got " .. type(inactive) .. ")", 2)
                    end

                    if inactive["text"] ~= nil then
                        Button.setInactiveTextColor(inactive["text"])
                    end

                    if inactive["background"] ~= nil then
                        Button.setInactiveBackgroundColor(inactive["background"])
                    end
                end
            end

            --if bConfig.contains("action") then
            --
            --end

            if bConfig.contains("active") then
                Button.setActive(bConfig.get("active"))
            end

            if bConfig.contains("visible") then
                Button.setVisible(bConfig.get("visible"))
            end

            return true
        end

        return false
    end

    --- Saves this button to the configuration file at the specified path.
    --- @param path string the path to the configuration file.
    --- @return boolean true when the configuration was saved, false otherwise.
    function Button.save(path)
        if path ~= nil and type(path) ~= "string" then
            error("bad argument #1 (expected string, got " .. type(path) .. ")", 2)
        end

        if path == nil and bConfig == nil then
            error("bad argument #1 (expected path, got nil)", 2)
        end

        if path ~= nil and (bConfig == nil or bConfig.path() ~= path) then
            bConfig = Configuration.create(path)

            if not equal(bTitle, defaults["title"]) then
                bConfig.set("title", bTitle)
            end

            if not equal(bPosX, defaults["pos-x"]) then
                bConfig.set("pos-x", bPosX)
            end

            if not equal(bPosY, defaults["pos-y"]) then
                bConfig.set("pos-y", bPosY)
            end

            if not equal(bWidth, defaults["width"]) then
                bConfig.set("width", bWidth)
            end

            if not equal(bHeight, defaults["height"]) then
                bConfig.set("height", bHeight)
            end

            if not equal(bColor, defaults["color"]) then
                bConfig.set("color", bColor)
            end

            if not equal(bAction, defaults["action"]) then
                --bConfig.set("action", bAction)
            end

            if not equal(bActive, defaults["active"]) then
                bConfig.set("active", bActive)
            end

            if not equal(bVisible, defaults["visible"]) then
                bConfig.set("visible", bVisible)
            end
        end

        return bConfig.save()
    end

    --- Gets whether the specified position is in range of this button.
    --- @return boolean true, when the position is in range, false otherwise.
    function Button.range(posX, posY)
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

    --- Redraws this button to the terminal.
    function Button.redraw()
        draw()
    end

    --- Performs the actions of this button.
    function Button.press()
        if bActive then
            Button.setActive(false)
        else
            Button.setActive(true)
        end
    end
end