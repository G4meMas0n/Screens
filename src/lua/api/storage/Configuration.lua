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

--- Creates a new Configuration table object.
--- @param path string the path to the storage file
--- @return table the created configuration table
function create(path)
    -- Check parameter type before initializing configuration table:
    if type(path) ~= "string" then
        error("bad argument #1 (expected string, got " .. type(path) .. ")", 2)
    end

    if fs.exists(path) and fs.isDir(path) then
        error("bad argument #1 (expected file, got directory)", 2)
    end

    local cPath = path
    local cTable = {}

    --- Copies a value
    --- @param value boolean|number|string|table the value to copy
    --- @return boolean|number|string|table the copied value
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

    -- Object Implementation
    local Configuration = {}

    --- Clears this configuration.
    function Configuration.clear()
        cTable = {}
    end

    --- Gets whether this configuration contains the specified key.
    --- @param key string the configuration key to check
    --- @return boolean true when this configuration contains the key, false otherwise
    function Configuration.contains(key)
        if type(key) ~= "string" then
            error("bad argument #1 (expected string, got " .. type(key) .. ")", 2)
        end

        return cTable[key] ~= nil
    end

    --- Gets the value of an configuration key.
    --- @param key string the configuration key for the value to get
    --- @param default nil|boolean|number|string|table the default value for the configuration key
    --- @return nil|boolean|number|string|table the value of the configuration key or the specified default value if it not exist
    function Configuration.get(key, default)
        if type(key) ~= "string" then
            error("bad argument #1 (expected string, got " .. type(key) .. ")", 2)
        end

        local result = cTable[key]

        if result == nil then
            return default
        end

        return copy(result)
    end

    --- Sets a configuration key to a specified value.
    --- @param key string the configuration key for the value to set
    --- @param value nil|boolean|number|string|table the value for the configuration key
    function Configuration.set(key, value)
        if type(key) ~= "string" then
            error("bad argument #1 (expected string, got " .. type(key) .. ")", 2)
        end

        if type(value) ~= "boolean" and type(value) ~= "number" and type(value) ~= "string" and type(value) ~= "table" then
            error("bad argument #2 (expected value, got" .. type(value) .. ")", 2)
        end

        if type(value) == "table" then
            value = textutils.unserialize(textutils.serialize(value))
        end

        cTable[key] = value
    end

    --- Gets all configuration keys of this configuration file.
    --- @return table all configuration keys registered in this configuration
    function Configuration.keys()
        local keys = {}

        for key, _ in pairs(cTable) do
            keys[#keys + 1] = key
        end

        table.sort(keys)

        return keys
    end

    --- Gets all configuration values of this configuration file.
    --- @return table all configuration values registered in this configuration
    function Configuration.values()
        local values = {}

        for _, value in pairs(cTable) do
            values[#values + 1] = value
        end

        table.sort(values)

        return values
    end

    --- Gets the path to the registered file of this configuration.
    --- @return string the path to the configuration file
    function Configuration.path()
        return cPath
    end

    --- Loads the registered file of this configuration.
    --- @return boolean true when the file was loaded successful, false otherwise
    function Configuration.load()
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

    --- Saves this configuration to the registered file.
    --- @return boolean true when the file was saved successful, false otherwise
    function Configuration.save()
        local file = fs.open(cPath, "w")

        if file ~= nil then
            file.write(textutils.serialize(settings))
            file.close()

            return true
        end

        return false
    end

    return Configuration
end
