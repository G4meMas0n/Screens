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

--- Creates a new config table object.
--- @param cPath string the path to the storage file.
--- @return table the created config table.
function create(cPath)
    if type(cPath) ~= "string" then
        error("bad argument #1 (expected string, got " .. type(cPath) .. ")", 2)
    end

    if fs.exists(cPath) and fs.isDir(cPath) then
        error("bad argument #1 (expected file, got directory at " .. cPath .. ")", 2)
    end

    local cTable = {}

    local function copy(value)
        if type(value) == "table" then
            local result = {}

            for key, content in pairs(value) do
                result[key] = copy(content)
            end

            return result
        end

        return value
    end

    --                           --
    --   Config Implementation   --
    --                           --

    local config = {}

    --- Clears this config.
    function config.clear()
        cTable = {}
    end

    --- Gets whether this config contains the specified key.
    --- @param key string the key to check for.
    --- @return boolean true when the key exists, false otherwise.
    function config.contains(key)
        if type(key) ~= "string" then
            error("bad argument #1 (expected string, got " .. type(key) .. ")", 2)
        end

        local point = key:find("%.")

        if point ~= nil then
            local primary = key:sub(1, point - 1)

            if type(cTable[primary]) ~= "table" then
                return false
            end

            return cTable[primary][key:sub(point + 1)] ~= nil
        end

        return cTable[key] ~= nil
    end

    --- Gets the value of an config key.
    --- @param key string the key for the value to get.
    --- @param default nil|boolean|number|string|table the default value for the key.
    --- @return nil|boolean|number|string|table the value of the key or the default value.
    function config.get(key, default)
        if type(key) ~= "string" then
            error("bad argument #1 (expected string, got " .. type(key) .. ")", 2)
        end

        local value = cTable[key]
        local point = key:find("%.")

        if point ~= nil then
            local primary = key:sub(1, point - 1)

            if type(cTable[primary]) ~= "table" then
                return default
            end

            value = cTable[primary][key:sub(point + 1)]
        end

        if value == nil then
            return default
        end

        return copy(value)
    end

    --- Sets the value of an config key.
    --- @param key string the key for the value to set.
    --- @param value nil|boolean|number|string|table the new value for the key.
    function config.set(key, value)
        if type(key) ~= "string" then
            error("bad argument #1 (expected string, got " .. type(key) .. ")", 2)
        end

        if type(value) ~= "boolean" and type(value) ~= "nil" and type(value) ~= "number" and type(value) ~= "string" and type(value) ~= "table" then
            error("bad argument #2 (expected boolean, nil, number, string or table, got" .. type(value) .. ")", 2)
        end

        if type(value) == "table" then
            if value == cTable then
                error("bad argument #2 (expected new table, got listed table)", 2)
            end

            value = textutils.unserialize(textutils.serialize(value))
        end

        local point = key:find("%.")

        if point ~= nil then
            local primary = key:sub(1, point - 1)

            if type(cTable[primary]) ~= "table" then
                cTable[primary] = {}
            end

            cTable[primary][key:sub(point + 1)] = value
        else
            cTable[key] = value
        end
    end

    --- Gets all keys of this config.
    --- @return table all keys registered in this config.
    function config.keys()
        local keys = {}

        for key, _ in pairs(cTable) do
            keys[#keys + 1] = key
        end

        table.sort(keys)

        return keys
    end

    --- Gets all values of this config.
    --- @return table all values registered in this config.
    function config.values()
        local values = {}

        for _, value in pairs(cTable) do
            values[#values + 1] = value
        end

        table.sort(values)

        return values
    end

    --- Gets the path of this config.
    --- @return string the registered config file path.
    function config.path()
        return cPath
    end

    --- Loads the registered file of this config.
    --- @return boolean true when the file was loaded successful, false otherwise.
    function config.load()
        local file = fs.open(cPath, "r")

        if file ~= nil then
            local text = file.readAll()

            file.close()

            local content = textutils.unserialize(text)

            if type(content) ~= "table" then
                error("bad file #1 (expected table, got " .. type(content) .. ")", 2)
            end

            for key, value in pairs(content) do
                if type(key) == "string" and (type(value) == "boolean" or type(value) == "number" or type(value) == "string" or type(value) == "table") then
                    if type(value) == "table" then
                        value = textutils.unserialize(textutils.serialize(value))
                    end

                    cTable[key] = value
                end
            end

            return true
        end

        return false
    end

    --- Saves this config to the registered file.
    --- @return boolean true when the file was saved successful, false otherwise.
    function config.save()
        local file = fs.open(cPath, "w")

        if file ~= nil then
            file.write(textutils.serialize(cTable))
            file.close()

            return true
        end

        return false
    end

    return config
end
