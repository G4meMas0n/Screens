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

--- Removes all control and space characters at the beginning of the given string.
local function remove(sequence)
    return sequence:gsub("^[%c%s]+", "")
end

--- Removes the given char at the beginning of the given string or throws an error.
local function require(sequence, char)
    if sequence:sub(1, 1) ~= char then
        error("expected character '" .. char .. "', got '" .. sequence:sub(1, 1) .. "'", 0)
    end

    return remove(sequence:sub(2))
end

--- Decodes the given json string into an json value.
--- @param input string the json string to decode.
--- @return table|string|number|nil|boolean, string the decoded json value and the rest of the input.
local function decodeValue(input)

    --- Decodes the given input sequence into a number.
    local function decodeNumber(sequence)
        local range, number, pattern = 2, nil, "[%d%.eE]"

        while sequence:sub(range, range):match(pattern) do
            if sequence:sub(range, range):lower() == "e" then
                if sequence:sub(range + 1, range + 1) == "-" then
                    range = range + 1
                end

                pattern = "[%d]"
            elseif sequence:sub(range, range) == "." then
                pattern = "[%deE]"
            end

            range = range + 1
        end

        number = tonumber(sequence:sub(1, range - 1))

        if number == nil then
            error("expected number, got '" .. sequence:sub(1, range - 1) .. "'", 0)
        end

        return number, remove(sequence:sub(range))
    end

    --- Decodes the given input sequence into a string.
    local function decodeString(sequence)
        sequence = require(sequence, "\"")

        local content = ""
        local next, escape

        while sequence:sub(1, 1) ~= "\"" do
            next = sequence:sub(1, 1)
            sequence = sequence:sub(2)

            if next == "\n" or next == "\r" then
                error("expected character '\"', got '" .. escapes[next] .. "'", 0)
            end

            if next == "\\" then
                escape = sequence:sub(1, 1)
                sequence = sequence:sub(2)

                if escapes[next .. escape] == nil then
                    error("expected escape character, got '" .. escape .. "'", 0)
                end

                next = escapes[next .. escape]
            end

            content = content .. next
        end

        return content, remove(sequence:sub(2))
    end

    --- Decodes the given input sequence into an array.
    local function decodeArray(sequence)
        sequence = require(sequence, "[")

        local object = {}
        local value

        while sequence:sub(1, 1) ~= "]" do
            value, sequence = decodeValue(sequence)
            object[#object + 1] = value

            if sequence:sub(1, 1) ~= "]" then
                sequence = require(sequence, ",")
            end
        end

        return object, remove(sequence:sub(2))
    end

    --- Decodes the given input sequence into an object.
    local function decodeObject(sequence)
        sequence = require(sequence, "{")

        local object = {}
        local key, value

        while sequence:sub(1, 1) ~= "}" do
            key, sequence = decodeString(sequence)

            if object[key] ~= nil then
                error("expected unique keys, got key '" .. key .. "' twice", 0)
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
    elseif input:sub(1, 1) == "[" then
        return decodeArray(input)
    elseif input:sub(1, 1) == "\"" then
        return decodeString(input)
    end

    if input:sub(1, 1):match("[%-%d]") then
        return decodeNumber(input)
    end

    if input:sub(1, 4) == "null" then
        return nil, remove(input:sub(5))
    elseif input:sub(1, 4) == "true" then
        return true, remove(input:sub(5))
    elseif input:sub(1, 5) == "false" then
        return false, remove(input:sub(6))
    end

    error("unexpected character '" .. input:sub(1, 1) .. "'", 0)
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
        error("invalid json string (" .. result .. ")", 2)
    end

    return result
end

--                           --
--   JSON Encoding Section   --
--                           --

--- Checks whether the given table represents an json array.
local function array(object)
    local max = 0

    for key, _ in pairs(object) do
        if type(key) ~= "number" then
            return false
        end

        if key > max then
            max = key
        end
    end

    return max == #object
end

--- Encodes the given json value into a json string.
--- @param object table|string|number|boolean the json object to encode.
--- @param level number the current tab level for string formatting.
--- @param tracker table the list of all tracked tables.
--- @return string the encoded json string.
local function encodeValue(object, level, tracker)

    --- Encodes the given string into a json string.
    local function encodeString(text)
        return "\"" .. text:gsub("[%c\"\\]", escapes) .. "\""
    end

    --- Encodes the given array into a json string.
    local function encodeArray(other)
        local output, count = "[\n" .. string.rep("\t", level + 1), 0

        for _, value in pairs(other) do
            if count > 0 then
                output = output .. ",\n" .. string.rep("\t", level + 1)
            end

            output = output .. encodeValue(value, level + 1, tracker)
            count = count + 1
        end

        return output .. "\n" .. string.rep("\t", level) .. "]"
    end

    --- Encodes the given object into a json string.
    local function encodeObject(other)
        local output, count = "{\n" .. string.rep("\t",level + 1), 0

        for key, value in pairs(other) do
            if type(key) == "string" then
                if count > 0 then
                    output = output .. ",\n" .. string.rep("\t", level + 1)
                end

                output = output .. string.format("%q", key) .. ": " .. encodeValue(value, level + 1, tracker)
                count = count + 1
            end
        end

        return output .. "\n" .. string.rep("\t", level) .. "}"
    end

    if type(object) == "table" then
        if tracker[object] ~= nil then
            error("expected cycle-less table")
        end

        tracker[object] = true

        if array(object) then
            return encodeArray(object)
        end

        return encodeObject(object)
    elseif type(object) == "string" then
        return encodeString(object)
    elseif type(object) == "boolean" or type(object) == "number" then
        return tostring(object)
    end

    error("expected boolean, number, string or table, got '" .. type(object) .. "'", 0)
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
        error("invalid json value (" .. result .. ")", 2)
    end

    return result
end
