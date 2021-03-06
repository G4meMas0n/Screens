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

--- Creates a new label table object.
--- @param lTerm table the parent terminal, window or monitor.
--- @param lPosX nil|number the label's x position.
--- @param lPosY nil|number the label's y position.
--- @param lWidth nil|number the label's width.
--- @param lText nil|string the label's title.
--- @return table the created label table.
function create(lTerm, lPosX, lPosY, lWidth, lText)
    if type(lTerm) ~= "table" then
        error("bad argument #1 (expected table, got " .. type(lTerm) .. ")", 2)
    end

    do
        local maxWidth, maxHeight = lTerm.getSize()

        if lPosX ~= nil then
            if type(lPosX) ~= "number" then
                error("bad argument #2 (expected number, got " .. type(lPosX) .. ")", 2)
            end

            if lPosX < 1 or lPosX > maxWidth then
                error("bad argument #2 (expected position between 1 and " .. maxWidth .. ", got " .. lPosX .. ")", 2)
            end
        else
            lPosX = 1
        end

        if lPosY ~= nil then
            if type(lPosY) ~= "number" then
                error("bad argument #3 (expected number, got " .. type(lPosY) .. ")", 2)
            end

            if lPosY < 1 or lPosY > maxHeight then
                error("bad argument #3 (expected position between 1 and " .. maxHeight .. ", got " .. lPosY .. ")", 2)
            end
        else
            lPosY = 1
        end

        if lWidth ~= nil then
            if type(lWidth) ~= "number" then
                error("bad argument #4 (expected number, got " .. type(lWidth) .. ")", 2)
            end

            if lWidth < 0 or lWidth > maxWidth - (lPosX - 1) then
                error("bad argument #4 (expected width between 0 and " .. maxWidth - (lPosX - 1) .. ", got " .. lWidth .. ")", 2)
            end
        else
            lWidth = maxWidth - (lPosX - 1)
        end

        if lText ~= nil then
            if type(lText) ~= "string" then
                error("bad argument #5 (expected string, got " .. type(lText) .. ")", 2)
            end

            if lText:len() > lWidth then
                error("bad argument #5 (expected length between 0 and " .. lWidth .. ", got " .. lText:len() .. ")", 2)
            end
        else
            lText = ""
        end
    end

    local cText, cBackground = hex[lTerm.getTextColor()], hex[lTerm.getBackgroundColor()]
    local lAlign, lVisible = "right", false
    local lAction, lConfig

    local function clear()
        local oldX, oldY = lTerm.getCursorPos()

        lTerm.setCursorPos(lPosX, lPosY)
        lTerm.blit(string.rep(" ", lWidth), hex[lTerm.getTextColor()]:rep(lWidth), hex[lTerm.getBackgroundColor()]:rep(lWidth))
        lTerm.setCursorPos(oldX, oldY)
    end

    local function draw()
        if lVisible then
            local oldX, oldY = lTerm.getCursorPos()
            local text = lText

            if lAlign == "center" then
                local spacing = (lWidth - text:len()) / 2

                text = string.rep(" ", math.ceil(spacing)) .. text .. string.rep(" ", math.floor(spacing))
            elseif lAlign == "left" then
                text = text .. string.rep(" ", lWidth - text:len())
            elseif lAlign == "right" then
                text = string.rep(" ", lWidth - text:len()) .. text
            end

            lTerm.setCursorPos(lPosX, lPosY)
            lTerm.blit(text, cText:rep(lWidth), cBackground:rep(lWidth))
            lTerm.setCursorPos(oldX, oldY)
        end
    end

    local function loadKey(key, method)
        if lConfig ~= nil and lConfig.contains(key) then
            local success, message = pcall(method, lConfig.get(key))

            if not success then
                error("bad configuration #" .. key .. " (" .. message:gsub(".*%((.+)%)", "%1") .. ")", 3)
            end
        end
    end

    local function saveKey(key, value)
        if lConfig ~= nil and lConfig.get(key) ~= value then
            lConfig.set(key, value)
            lConfig.save()
        end

        return value
    end

    --                          --
    --   Label Implementation   --
    --                          --

    local label = {}

    --- Gets the text of this label.
    --- @return string the label's text or an empty string.
    function label.getText()
        return lText
    end

    --- Sets the text of this label.
    --- @param text string the new text for this label.
    --- @return boolean true when the text was changed, false otherwise.
    function label.setText(text)
        if type(text) ~= "string" then
            error("bad argument #1 (expected string, got " .. type(text) .. ")", 2)
        end

        if text:len() > lWidth then
            error("bad argument #1 (expected length between 0 and " .. lWidth .. ", got " .. text:len() .. ")", 2)
        end

        if text ~= lText then
            lText = saveKey("text", text)
            draw()

            return true
        end

        return false
    end

    --- Gets the position of this label.
    --- @return number, number the label's x and y position.
    function label.getPosition()
        return lPosX, lPosY
    end

    --- Gets the x position of this label.
    --- @return number the label's x position.
    function label.getPosX()
        return lPosX
    end

    --- Sets the x position of this label.
    --- @param posX number the new x position.
    --- @return boolean true when the x position was changed, false otherwise.
    function label.setPosX(posX)
        if type(posX) ~= "number" then
            error("bad argument #1 (expected number, got " .. type(posX) .. ")", 2)
        end

        local maxWidth, _ = lTerm.getSize()

        if posX < 1 or posX > maxWidth - lWidth then
            error("bad argument #2 (expected position between 1 and " .. maxWidth - lWidth .. ", got " .. posX .. ")", 2)
        end

        if posX ~= lPosX then
            clear()
            lPosX = saveKey("pos-x", posX)
            draw()

            return true
        end

        return false
    end

    --- Gets the y position of this label.
    --- @return number the label's y position.
    function label.getPosY()
        return lPosY
    end

    --- Sets the y position of this label.
    --- @param posY number the new y position.
    --- @return boolean true when the y position was changed, false otherwise.
    function label.setPosY(posY)
        if type(posY) ~= "number" then
            error("bad argument #1 (expected number, got " .. type(posY) .. ")", 2)
        end

        local _, maxHeight = lTerm.getSize()

        if posY < 1 or posY > maxHeight then
            error("bad argument #2 (expected position between 1 and " .. maxHeight .. ", got " .. posY .. ")", 2)
        end

        if posY ~= lPosY then
            clear()
            lPosY = saveKey("pos-y", posY)
            draw()

            return true
        end

        return false
    end

    --- Gets the size of this label.
    --- @return number, number the label's width and 1.
    function label.getSize()
        return lWidth, 1
    end

    --- Gets the width of this label.
    --- @return number the label's width.
    function label.getWidth()
        return lWidth
    end

    --- Sets the width of this label.
    --- @param width number the new width.
    --- @return boolean true when the width was changed, false otherwise.
    function label.setWidth(width)
        if type(width) ~= "number" then
            error("bad argument #1 (expected number, got " .. type(width) .. ")", 2)
        end

        local maxWidth, _ = lTerm.getSize()

        if width < lText:len() or width > maxWidth - (lPosX - 1) then
            error("bad argument #1 (expected width between " .. lText:len() .. " and " .. (maxWidth - (lPosX - 1)) .. ", got " .. width .. ")", 2)
        end

        if width ~= lWidth then
            clear()
            lWidth = saveKey("width", width)
            draw()

            return true
        end

        return false
    end

    --- Gets the text color of this label.
    --- @return number the color code of the text color.
    function label.getTextColor()
        return 2 ^ tonumber(cText, 16)
    end

    --- Sets the text color of this label.
    --- @param color number|string the new color, represented by the color code or hex value.
    --- @return boolean true when the color was changed, false otherwise.
    function label.setTextColor(color)
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
            cText = saveKey("color.text", hex[color])
            draw()

            return true
        end

        return false
    end

    --- Gets the background color of this label.
    --- @return number the color code of the background color.
    function label.getBackgroundColor()
        return 2 ^ tonumber(cBackground, 16)
    end

    --- Sets the background color of this label.
    --- @param color number|string the new color, represented by the color code or hex value.
    --- @return boolean true when the color was changed, false otherwise.
    function label.setBackgroundColor(color)
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
            cBackground = saveKey("color.background", hex[color])
            draw()

            return true
        end

        return false
    end

    --- Gets the alignment of this label.
    --- @return string 'left', 'center' or 'right' depending on the alignment.
    function label.getAlign()
        return lAlign
    end

    --- Sets the alignment of this label.
    --- @param align string 'left', 'center', 'right' depending on the new alignment.
    --- @return boolean true when the alignment was changed, false otherwise
    function label.setAlign(align)
        if type(align) ~= "string" then
            error("bad argument #1 (expected string, got " .. type(align) .. ")", 2)
        end

        if align ~= "left" and align ~= "center" and align ~= "right" then
            error("bad argument #1 (expected 'left', 'center' or 'right', got '" .. align .. "')", 2)
        end

        if align ~= lAlign then
            lAlign = saveKey("align", align)
            draw()

            return true
        end

        return false
    end

    --- Gets the update action of this label.
    --- @return function the action function.
    function label.getAction()
        return lAction
    end

    --- Sets the update action of this label.
    --- @param action function|string the new action.
    --- @return function true when the action was changed, false otherwise.
    function label.setAction(action)
        if type(action) ~= "function" and type(action) ~= "string" then
            error("bad argument #1 (expected function or string, got " .. type(action) .. ")", 2)
        end

        if type(action) == "string" then
            local func, message = load(action, "action", "t")

            if not func then
                error("bad argument #1 (" .. message .. ")", 2)
            end
        end

        if action ~= lAction then
            lAction = action

            return true
        end

        return false
    end

    --- Gets whether this label is visible.
    --- @return boolean true when it is visible, false otherwise.
    function label.getVisible()
        return lVisible
    end

    --- Sets whether this label is visible.
    --- @param visible boolean whether it should be visible.
    --- @return boolean true when the visibility was changed, false otherwise.
    function label.setVisible(visible)
        if type(visible) ~= "boolean" then
            error("bad argument #1 (expected boolean, got " .. type(visible) .. ")", 2)
        end

        if visible ~= lVisible then
            lVisible = saveKey("visible", visible)

            if visible then
                draw()
            else
                clear()
            end

            return true
        end

        return false
    end

    --- Loads this label from the configuration file at the specified path.
    --- @param path string the path to the configuration file.
    --- @return boolean true when the configuration was loaded, false otherwise.
    function label.load(path)
        if path ~= nil and type(path) ~= "string" or path == nil and lConfig == nil then
            error("bad argument #1 (expected string, got " .. type(path) .. ")", 2)
        end

        if path ~= nil and (lConfig == nil or lConfig.path() ~= path) then
            lConfig = config.create(path)
        end

        if lConfig.load() then
            loadKey("pos-x", label.setPosX)
            loadKey("pos-y", label.setPosY)
            loadKey("width", label.setWidth)
            loadKey("text", label.setText)
            loadKey("color.text", label.setTextColor)
            loadKey("color.background", label.setBackgroundColor)
            loadKey("align", label.setAlign)
            loadKey("action", label.setAction)
            loadKey("visible", label.setVisible)

            return true
        end

        return false
    end

    --- Saves this label to the configuration file at the specified path.
    --- @param path string the path to the configuration file.
    --- @return boolean true when the configuration was saved, false otherwise.
    function label.save(path)
        if path ~= nil and type(path) ~= "string" or path == nil and lConfig == nil then
            error("bad argument #1 (expected string, got " .. type(path) .. ")", 2)
        end

        if path ~= nil and (lConfig == nil or lConfig.path() ~= path) then
            lConfig = config.create(path)

            saveKey("pos-x", lPosX)
            saveKey("pos-y", lPosY)
            saveKey("width", lWidth)
            saveKey("text", lText)
            saveKey("color.text", cText)
            saveKey("color.background", cBackground)
            saveKey("align", lAlign)
            saveKey("visible", lVisible)
        end

        return lConfig.save()
    end

    --- Draws the label to the terminal.
    function label.redraw()
        clear()
        draw()
    end

    --- Updates the text of this label.
    function label.update()
        local function set(method, value)
            local success, message = pcall(method, value)

            if not success then
                error("bad action #return (" .. message:gsub(".*%((.+)%)", "%1") .. ")", 4)
            end
        end

        if lAction ~= nil then
            local success, text, color, background = pcall(lAction, lWidth)

            if not success then
                error("bad action #run (" .. text .. ")", 3)
            end

            set(label.setText, text)
            set(label.setTextColor, color)
            set(label.setBackgroundColor, background)
            draw()
        end
    end

    return label
end