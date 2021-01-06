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

--                           --
--   JSON Decoding Section   --
--                           --

--- Table of all allowed escape characters in json strings.
local escapes = {
    ["\n"] = "\\n",
    ["\r"] = "\\r",
    ["\t"] = "\\t",
    ["\b"] = "\\b",
    ["\f"] = "\\f",
    ["\""] = "\\\"",
    ["\\"] = "\\\\"
}

--- Table of all allowed number characters in json strings.
local numbers = {
    ['e'] = true,
    ['E'] = true,
    ['.'] = true
}

--- Table of all allowed space characters in json strings.
local spaces = {
    ['\n'] = true,
    ['\r'] = true,
    ['\t'] = true,
    [' '] = true
}

--- Removes all whitespace characters at the beginning.
--- @param sequence string the input string to trim.
--- @return string the trimmed string.
local function remove(sequence)
    while spaces[sequence:sub(1, 1)] do
        sequence = sequence:sub(2)
    end

    return sequence
end

--- Checks whether the next sequence character is the required char.
--- @param sequence string the input string to check.
--- @param char string the required char for the next sequence character.
--- @return string the rest of the sequence without the required char.
local function require(sequence, char)
    if sequence:sub(1, 1) ~= char then
        error("expected character '" .. char .. "', got '" .. sequence:sub(1, 1) .. "'", 2)
    end

    return remove(sequence:sub(2))
end

--- Decodes the complete input string into an json object.
--- @param input string the json string to decode.
--- @return table|string|number|nil|boolean, string the parsed json value and the rest of the input.
local function decodeValue(input)

    --- Decodes the next sequence of the input string into a number.
    --- @param sequence string the string to parse.
    --- @return number the parsed number value and the rest of the sequence.
    local function decodeNumber(sequence)
        local range = 1

        if sequence:sub(1, 1) == "-" then
            range = range + 1
        end

        while tonumber(sequence:sub(range, range)) or numbers[sequence:sub(range, range)] do
            range = range + 1
        end

        local number = tonumber(sequence:sub(1, range - 1))

        if number == nil then
            error("expected valid number, got '" .. sequence:sub(1, range - 1) .. "'")
        end

        return number, remove(sequence:sub(range))
    end

    --- Decodes the next sequence of the input string into a string.
    --- @param sequence string the string to decode.
    --- @return string, string the parsed string and the rest of the sequence.
    local function decodeString(sequence)
        sequence = require(sequence, "\"")

        local content = ""
        local next, escape

        while sequence:sub(1, 1) ~= "\"" do
            next = sequence:sub(1, 1)
            sequence = sequence:sub(2)

            if next == "\n" or next == "\r" then
                error("expected character '\"', got '" .. escapes[next] .. "'")
            end

            if next == "\\" then
                escape = sequence:sub(1, 1)
                sequence = sequence:sub(2)

                if escapes[next .. escape] == nil then
                    error("expected escape character, got '" .. escape .. "'")
                end

                next = escapes[next .. escape]
            end

            content = content .. next
        end

        return content, remove(sequence:sub(2))
    end

    --- Decodes the next sequence of the input string into an json array.
    --- @param sequence string the string to decode.
    --- @return table the parsed json array, with numbers as keys and the rest of the sequence.
    local function decodeArray(sequence)
        sequence = require(sequence, "[")

        local array = {}
        local value

        while sequence:sub(1, 1) ~= "]" do
            value, sequence = decodeValue(sequence)
            array[#array + 1] = value

            if sequence:sub(1, 1) ~= "]" then
                sequence = require(sequence, ",")
            end
        end

        return array, remove(sequence:sub(2))
    end

    --- Decodes the next sequence of the input string into an json object.
    --- @param sequence string the string to decode.
    --- @return table the parsed json object, with strings as keys and the rest of the sequence.
    local function decodeObject(sequence)
        sequence = require(sequence, "{")

        local object = {}
        local key, value

        while sequence:sub(1, 1) ~= "}" do
            key, sequence = decodeString(sequence)

            if object[key] ~= nil then
                error("expected unique keys, got key '" .. key .. "' twice")
            end

            value, sequence = decodeValue(require(sequence, ":"))
            object[key] = value

            if sequence:sub(1, 1) ~= "}" then
                sequence = require(sequence, ",")
            end
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

    if input:sub(1, 1) == "-" or tonumber(input:sub(1, 1)) ~= nil then
        return decodeNumber(input)
    end

    if input:sub(1, 4) == "null" then
        return nil, remove(input:sub(5))
    end

    if input:sub(1, 4) == "true" then
        return true, remove(input:sub(5))
    end

    if input:sub(1, 5) == "false" then
        return false, remove(input:sub(6))
    end

    error("unexpected character '" .. input:sub(1, 1) .. "'")
end

--- Decodes the given string into a json object.
--- @param input string the json string to decode.
--- @return table|string|number|boolean the resulting json object.
function decode(input)
    if type(input) ~= "string" then
        error("bad argument #1 (expected string, got " .. type(input) .. ")", 2)
    end

    local success, result = pcall(decodeValue, remove(input))

    if not success then
        error("bad argument #1 (invalid json string: " .. result .. ")", 2)
    end

    return result
end

--                           --
--   JSON Encoding Section   --
--                           --

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

    return max == #array
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

--- Encodes the complete json object into a json string.
--- @param object table|string|number|boolean the json object to encode.
--- @param level number the current tab level for string.
--- @param seen table the list of all seen tables.
--- @return string the resulting json string of the given json object.
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
        local index, last = 0, size(other)

        for key, value in pairs(other) do
            output = output .. encodeString(key) .. ":" .. encodeValue(value, level + 1, seen)
            index = index + 1

            if index < last then
                output = output .. ",\n" .. string.rep("\t", level + 1)
            end
        end

        return output .. "\n" .. string.rep("\t", level) .. "}"
    end

    if type(object) == "table" then
        if seen[object] ~= nil then
            error("expected cycle-less table")
        end

        seen[object] = true

        if isArray(object) then
            return encodeArray(object)
        end

        if isObject(object) then
            return encodeObject(object)
        end

        error("expected json array or object")
    end

    if type(object) == "string" then
        return encodeString(object)
    end

    if type(object) == "boolean" or type(object) == "number" then
        return tostring(object)
    end

    error("expected json value, got '" .. type(object) .. "'")
end

--- Encodes the given json object into a string.
--- @param object string the json object to encode.
--- @return string the encoded json object.
function encode(object)
    if type(object) ~= "table" then
        error("bad argument #1 (expected table, got " .. type(object) .. ")", 2)
    end

    local success, result = pcall(encodeValue, object, 0, {})

    if not success then
        error("bad argument #1 (invalid json object: " .. result .. ")", 2)
    end

    return result
end
