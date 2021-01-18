local bridge = {}

-- local utils = require("util.utils")
-- local socket = require("socket")
-- local memory = require "util.memory"

local lunajson = require("lunajson")

local lua_out = assert(io.open("../lua_out", "wb"))
local lua_in = assert(io.open("../lua_in", "rb"))

local client = nil
local timeStopped = false
local lastSecs = 0
local lastMins = 0
local lastHours = 0
local frames = 0

--[[
local function send(prefix, body)
    if (client) then
        local message = prefix
        if (body) then message = message .. " " .. body end
        client:send(message .. '\n')
        return true
    end
end
--]]

function bridge.send(msg)
    lua_out:write(msg .. "\n")
    lua_out:flush()
    local response = lua_in:read()
    -- print("Sent to Python " .. msg .. " Received from Python " .. response)
    local decoded = lunajson.decode(response)
    return decoded
end

local function readln()
    if (client) then
        local s, status, partial = client:receive('*l')
        if status == "closed" then
            client = nil
            return nil
        end
        if s and s ~= '' then return s end
    end
end

-- Wrapper functions

function bridge.init()
    -- print("Bridge initializing")
    -- client = socket.connect("localhost", 16834)
    -- print("Bridge initialized")
end

function bridge.tweet(message) -- Two of the same tweet in a row will only send one
    print('tweet::' .. message)
    -- return send("tweet", message)
    return true
end

function bridge.pollForName()
    bridge.polling = true
    -- send("poll_name")
end

function bridge.chat(message, extra)
    -- print("Bridge Chat")
    if (extra) then
        print(message .. " || " .. extra)
    else
        print(message)
    end
    -- return send("msg", message)
    return true
end

function bridge.time(time_data)
    if (not timeStopped) then
        -- local seconds = memory.raw(0x1A44)
        -- local minutes = memory.raw(0x1A43)
        -- local hours = memory.raw(0x1A41)
        local seconds = time_data["seconds"]
        local minutes = time_data["minutes"]
        local hours = time_data["hours"]

        if (hours ~= lastHours or minutes ~= lastMinutes or seconds ~=
            lastSeconds) then
            frames = 0
            lastSeconds = seconds
            lastMinutes = minutes
            lastHours = hours
        end
        seconds = seconds + frames / 60

        if (seconds < 10) then seconds = "0" .. seconds end
        if (minutes < 10) then minutes = "0" .. minutes end
        local message = hours .. ":" .. minutes .. ":" .. seconds
        -- send("setgametime", message)
        frames = frames + 1
    end
end

function bridge.stats(message)
    -- print("Bridge Stats")
    -- return send("stats", message)
    return true
end

function bridge.command(command)
    -- print("Bridge Command")
    -- return send(command)
    return true
end

function bridge.comparisonTime()
    -- print("Bridge Comparison Time")
    -- return send("getcomparisonsplittime")
    return true
end

function bridge.process()
    local response = readln()
    if (response) then
        -- print('>'..response)
        if (response:find("name:")) then
            return response:gsub("name:", "")
        else

        end
    end
end

function bridge.input(key)
    -- send("input", key)
end

function bridge.caught(name)
    if (name) then
        -- send("caught", name)
    end
end

function bridge.hp(curr, max)
    -- send("hp", curr..","..max)
end

function bridge.liveSplit()
    -- print("Bridge Start Timer")
    -- send("pausegametime")
    -- send("starttimer")
    timeStopped = false
end

function bridge.split(encounters, finished)
    -- print("Bridge Split")
    if (encounters) then
        -- database.split(utils.igt(), encounters)
    end
    if (finished) then timeStopped = true end
    -- send("split")
end

function bridge.encounter()
    -- send("encounter")
end

function bridge.reset()
    -- print("Bridge Reset")
    -- send("reset")
    timeStopped = false
end

function bridge.close()
    -- print("Bridge closing")
    if client then
        client:close()
        client = nil
    end
    -- print("Bridge closed")
    lua_in:close()
    lua_out:close()
end

return bridge
