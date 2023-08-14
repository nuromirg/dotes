local awful = require('awful')

local swal_ignore = {
    'obsidian',
    'keepassxc',
    'calibre',
    'anki',
    'firefox',
    'libreoffice',
    'mullvad-vpn',
    'wluma',
    'firefox',
    'gimp',
}

local table_is_swallowed = { "[Tt]erm", "[Pp]cmanfm", '[Aa]lacritty' }
local table_minimize_parent = { "Io.github.celluloid_player.Celluloid" }
local table_cannot_swallow = { "Dragon" }

local function is_in_Table(table, element)
    for _, value in pairs(table) do
        if element:match(value) then
            return true
        end
    end
    return false
end

local function is_to_be_swallowed(c)
    return (c.class and is_in_Table(table_is_swallowed, c.class)) and true or false
end

local function can_swallow(class)
    return not is_in_Table(table_cannot_swallow, class)
end

local function is_parent_minimized(class)
    return is_in_Table(table_minimize_parent, class)
end

local function copy_size(c, parent_client)
    if (not c or not parent_client) then
        return
    end
    if (not c.valid or not parent_client.valid) then
        return
    end
    c.x=parent_client.x;
    c.y=parent_client.y;
    c.width=parent_client.width;
    c.height=parent_client.height;
end
local function check_resize_client(c)
    if(c.child_resize) then
        copy_size(c.child_resize, c)
    end
end

local function get_parent_pid(child_ppid, callback)
    local ppid_cmd = string.format("pstree -ps %s", child_ppid)
    awful.spawn.easy_async(ppid_cmd, function(stdout, stderr, reason, exit_code)
        -- primitive error checking
        if stderr and stderr ~= "" then
            callback(stderr)
            return
        end
        local ppid = stdout
        callback(nil, ppid)
    end)
end

client.connect_signal("property::size", check_resize_client)
client.connect_signal("property::position", check_resize_client)
client.connect_signal("manage", function(c)
    -- if is_to_be_swallowed(c) then -- comment out
    --     return                    -- these lines
    -- end                           -- for a bling style
    local parent_client=awful.client.focus.history.get(c.screen, 1)
    get_parent_pid(c.pid, function(err, ppid)
        if err then
            error(err)
            return
        end
        local parent_pid = ppid
        -- if parent_client and (parent_pid:find("("..parent_client.pid..")")) and can_swallow(c.class) then     -- uncomment this line
        if parent_client and (parent_pid:find("("..parent_client.pid..")")) and is_to_be_swallowed(parent_client) and can_swallow(c.class) then -- window swallowing function
            if is_parent_minimized(c.class) then
                parent_client.child_resize=c
                parent_client.minimized = true
                c:connect_signal("unmanage", function() parent_client.minimized = false end)
                copy_size(c, parent_client)
            else
                parent_client.child_resize=c
                c.floating=true
                copy_size(c, parent_client)
            end
        end
    end)
end)

