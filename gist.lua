--[[
    Name: CC-Gist (https://github.com/BJTMastermind/CC-Gist)
    Description: A gist command for ComputerCraft to allow downloading/running lua code from a github gist.
    License: GPL-2.0
    Author: BJTMastermind (https://github.com/BJTMastermind)
--]]

function get_content(owner_username, gist_id)
    io.write("Connecting to gist.github.com... ")
    local request_api = http.get("https://api.github.com/gists/"..gist_id.."/commits")

    if request_api == nil then
        io.write("Failed.\n")
        return
    end

    local latest_revision = textutils.unserialiseJSON(request_api.readAll())[1]["version"]
    local request = http.get("https://gist.githubusercontent.com/"..owner_username.."/"..gist_id.."/raw/"..latest_revision)

    if request == nil then
        io.write("Failed.\n")
        return
    end

    io.write("Success.\n")
    local content = request.readAll()
    request.close()

    return content
end

function help()
    print("Usages:")
    print("gist get <owner_username> <gist_id> <filename>")
    print("gist run <owner_username> <gist_id> [<arguments>]")
end

function get(owner_username, gist_id, filename)
    if fs.exists(filename) then
        print("File already exists")
        return
    end

    local content = get_content(owner_username, gist_id)

    local file = fs.open(filename, "w")
    file.write(content)
    file.close()
    print("Downloaded as "..filename)
end

function run(owner_username, gist_id, ...)
    local content = get_content(owner_username, gist_id)

    local args = {...}

    local env = { arg = args }
    setmetatable(env, { __index = _G })

    local code, err = load(content, "gist_code", "t", env)
    if code then
        local success, err = pcall(code)
        if not success then
            print("Runtime Error:", err)
        end
    else
        print("Compulation Error:", err)
    end
end

if #arg == 0 then
    help()
end

if arg[1] == "get" then
    if arg[2] == nil or arg[3] == nil or arg[4] == nil then
        help()
        return
    end
    get(arg[2], arg[3], arg[4])
elseif arg[1] == "run" then
    if arg[2] == nil or arg[3] == nil then
        help()
        return
    end
    run(arg[2], arg[3], select(4, ...))
end
