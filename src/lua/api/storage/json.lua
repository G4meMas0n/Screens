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

--                       --
--   JSON Util Section   --
--                       --

--- Allowed escape characters for strings.
local escapes = {
    ["\n"] = "\\n",
    ["\r"] = "\\r",
    ["\t"] = "\\t",
    ["\b"] = "\\b",
    ["\f"] = "\\f",
    ["\""] = "\\\"",
    ["\\"] = "\\\\"
}

--- Allowed characters for numbers.
local numbers = {
    ['e'] = true,
    ['E'] = true,
    ['+'] = true,
    ['-'] = true,
    ['.'] = true
}

--- Allowed formatting characters for json strings.
local removal = {
    ['\n'] = true,
    ['\r'] = true,
    ['\t'] = true,
    [' '] = true,
    [','] = true
}

--- Removes all characters at the beginning of the given string until a non formatting characters comes.
--- @param input string the input string to trim.
--- @return string the trimmed string.
local function remove(input)
    while removal[input:sub(1, 1)] do
        input = input:sub(2)
    end

    return input
end

--- Returns the size of the given table.
--- @param object table the table the get the size.
--- @return number the size of the table or zero when the table is empty.
local function size(object)
    local count = 0

    for _, _ in pairs(object) do
        count = count + 1
    end

    return count
end

--- Checks whether the given table represents an json array.
--- @param array table the table to check.
--- @return boolean true when the table represents an json array, false otherwise.
local function isArray(array)
    local max = 0

    for key, _ in pairs(array) do
        if type(key) ~= "number" then
            return false
        end

        if key > max then
            max = key
        end
    end

    return max == size(array)
end

--- Checks whether the given table represents an json object.
--- @param object table the table to check.
--- @return boolean true when the table represents an json object, false otherwise.
local function isObject(object)
    for key, _ in pairs(object) do
        if type(key) ~= "string" then
            return false
        end
    end

    return true
end

--                           --
--   JSON Decoding Section   --
--                           --

--- Decodes the complete input string into an json object.
--- @param input string the json string to decode.
--- @return table|string|number|nil|boolean, string the parsed json value and the rest of the input.
local function decodeValue(input)

    --- Decodes the next sequence of the input string into a boolean.
    --- @param sequence string the string to decode.
    --- @return boolean the parsed boolean value and the rest of the input.
    local function decodeBoolean(sequence)
        if sequence:sub(1, 4) == "true" then
            return true, remove(sequence:sub(5))
        end

        if sequence:sub(1, 5) == "false" then
            return false, remove(sequence:sub(6))
        end
    end

    --- Decodes the next sequence of the input string into nil value.
    --- @param sequence string the string to decode.
    --- @return nil the parsed nil value and the rest of the input.
    local function decodeNull(sequence)
        if sequence:sub(1, 3) == "nil" then
            return nil, remove(sequence:sub(4))
        end

        if sequence:sub(1, 4) == "null" then
            return nil, remove(sequence:sub(5))
        end
    end

    --- Decodes the next sequence of the input string into a number.
    --- @param sequence string the string to parse.
    --- @return number the parsed number value and the rest of the input.
    local function decodeNumber(sequence)
        local range = 1

        while tonumber(sequence:sub(range, range)) or numbers[sequence:sub(range, range)] do
            range = range + 1
        end

        return tonumber(sequence:sub(1, range - 1)), remove(sequence:sub(range))
    end

    --- Decodes the next sequence of the input string into a string.
    --- @param sequence string the string to decode.
    --- @return string the parsed string and the rest of the input.
    local function decodeString(sequence)
        if sequence:sub(1, 1) ~= "\"" then
            error("invalid json string #3 (expected beginning quotation mark, got " .. sequence:sub(1, 1) .. ")", 2)
        end

        sequence = sequence:sub(2)

        local content = ""

        while sequence:sub(1, 1) ~= "\"" do
            local next = sequence:sub(1, 1)
            sequence = sequence:sub(2)

            if next == "\n" or next == "\r" then
                error("invalid json string #3 (expected closing quotation mark, got " .. escapes[next] .. ")", 2)
            end

            if next == "\\" then
                local escape = sequence:sub(1, 1)
                sequence = sequence:sub(2)

                if escapes[next .. escape] == nil then
                    error("invalid json string #3 (expected escape character, got " .. escape .. ")", 2)
                end

                next = escapes[next .. escape]
            end

            content = content .. next
        end

        return content, remove(sequence:sub(2))
    end

    --- Decodes the next sequence of the input string into an json array.
    --- @param sequence string the string to decode.
    --- @return table the parsed json array, with numbers as keys and the rest of the input.
    local function decodeArray(sequence)
        if sequence:sub(1, 1) ~= "[" then
            error("invalid json string #2 (expected beginning square bracket, got " .. sequence:sub(1, 1) .. ")", 2)
        end

        sequence = remove(sequence:sub(2))

        local array = {}
        local value

        while sequence:sub(1, 1) ~= "]" do
            value, sequence = decodeValue(sequence)
            array[#array + 1] = value
        end

        return array, remove(sequence:sub(2))
    end

    --- Decodes the next sequence of the input string into an json object.
    --- @param sequence string the string to decode.
    --- @return table the parsed json object, with strings as keys and the rest of the input.
    local function decodeObject(sequence)
        if sequence:sub(1, 1) ~= "{" then
            error("invalid json string #1 (expected beginning curly bracket, got " .. sequence:sub(1, 1) .. ")", 2)
        end

        sequence = remove(sequence:sub(2))

        local object = {}
        local key, value

        while sequence:sub(1, 1) ~= "}" do
            key, sequence = decodeString(sequence)

            if object[key] ~= nil then
                error("invalid json string #2 (expected unique object keys, got " .. key .. " twice)", 2)
            end

            if sequence:sub(1, 1) ~= ":" then
                error("invalid json string #2 (expected key value separator, got " .. sequence:sub(1, 1) .. ")", 2)
            end

            value, sequence = decodeValue(remove(sequence:sub(2)))
            object[key] = value
        end

        return object, remove(sequence:sub(2))
    end

    if input:sub(1, 1) == "{" then
        return decodeObject(input)
    end

    if input:sub(1, 1) == "[" then
        return decodeArray(input)
    end

    if input:sub(1, 1) == "\"" then
        return decodeString(input)
    end

    if tonumber(input:sub(1,1)) ~= nil or numbers[input:sub(1,1)] then
        return decodeNumber(input)
    end

    if input:sub(1, 3) == "nil" or input:sub(1, 4) == "null" then
        return decodeNull(input)
    end

    if input:sub(1, 4) == "true" or input:sub(1, 5) == "false" then
        return decodeBoolean(input)
    end

    error("invalid json string #1 (expected json value, got " .. input:sub(1, input:find("[\n\r\t ,}%]]")) .. ")", 2)
end

--- Decodes the given string into a json object.
--- @param input string the json string to decode.
--- @return table the resulting json object.
function decode(input)
    if type(input) ~= "string" then
        error("bad argument #1 (expected string, got " .. type(input) .. ")", 2)
    end

    if input:sub(1, 1) ~= "{" and input:sub(1, 1) ~= "[" then
        error("bad argument #1 (expected json array or json object)", 2)
    end

    return decodeValue(remove(input))
end

--                           --
--   JSON Encoding Section   --
--                           --

--- Encodes the complete json object into a json string.
--- @param object table|string|number|boolean the json object to encode.
--- @return string the parsed json string
local function encodeValue(object, level, seen)

    --- Encodes the text into a json string.
    --- @param text string the text to encode.
    --- @return string the encoded text.
    local function encodeString(text)
        return "\"" .. text:gsub("[%c\"\\]", escapes) .. "\""
    end

    --- Encodes the json array into a json string.
    --- @param array table the json array to decode.
    --- @return string the encoded json array.
    local function encodeArray(array)
        local output = "[\n" .. string.rep("\t", level + 1)
        local last = size(array)

        for key, value in pairs(array) do
            output = output .. encodeValue(value, level + 1, seen)

            if key < last then
                output = output .. ",\n" .. string.rep("\t", level + 1)
            end
        end

        return output .. "\n" .. string.rep("\t", level) .. "]"
    end

    --- Encodes the json object into a json string.
    --- @param other table the json object to encode.
    --- @return string the encoded json object.
    local function encodeObject(other)
        local output = "{\n" .. string.rep("\t",level + 1)
        local last = size(other)
        local index = 0

        for key, value in pairs(other) do
            output = output .. encodeString(key) .. ": " .. encodeValue(value, level + 1, seen)
            index = index + 1

            if index < last then
                output = output .. ",\n" .. string.rep("\t", level + 1)
            end
        end

        return output .. "\n" .. string.rep("\t", level) .. "}"
    end

    if type(object) == "table" then
        if seen[object] ~= nil then
            error("invalid json object #2 (expected cycle-less table)", 2)
        end

        seen[object] = true

        if isArray(object) then
            return encodeArray(object)
        end

        if isObject(object) then
            return encodeObject(object)
        end

        error("invalid json object #2 (expected json array or object)", 2)
    end

    if type(object) == "string" then
        return encodeString(object)
    end

    if type(object) == "boolean" or type(object) == "number" then
        return tostring(object)
    end

    error("invalid json object #1 (expected supported json values, got " .. type(object) .. ")", 2)
end

--- Encodes the given json object into a string.
--- @param object string the json object to encode.
--- @return string the encoded json object.
function encode(object)
    if type(object) ~= "table" then
        error("bad argument #1 (expected table, got " .. type(object) .. ")", 2)
    end

    return encodeValue(object, 0, {})
end
