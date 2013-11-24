whoison = {}
whoison.lastseen = {}

local filename = minetest.get_worldpath().."/online-players"
local seenfile = minetest.get_worldpath().."/last-seen"

function whoison.createFile(loopit)
	local file = io.open(filename, "w")
	file:write(os.time().."\n")
	file:write(minetest.get_server_status().."\n")
	for _,player in ipairs(minetest.get_connected_players()) do
		local name = player:get_player_name()
		local ppos = minetest.pos_to_string(player:getpos())
		local datastring = name.."|"..ppos.."\n"
		file:write( datastring )
	end
	file:close()
	minetest.log("action","Updated online player file")
	if ( loopit == true ) then
		minetest.after(60,whoison.createFile,true)
	end
end

function whoison.saveLastSeen()
	local f = io.open(seenfile,"w")
	f:write(minetest.serialize(whoison.lastseen))
	f:close()	
end

function whoison.loadLastSeen()
	local f = io.open(seenfile,"r")
	if ( f ~= nil ) then
		local ls = f:read("*all")
		f:close()
		if ( ls ~= nil and ls ~= "" ) then
			whoison.lastseen = minetest.deserialize(ls)
		end
	end
end

minetest.register_on_joinplayer(function (player) 
	whoison.createFile(false)
	whoison.lastseen[player:get_player_name()] = os.time()
	whoison.saveLastSeen()
end)

minetest.register_on_leaveplayer(function (player)
	whoison.createFile(false)
	whoison.lastseen[player:get_player_name()] = os.time()
	whoison.saveLastSeen()
end)

minetest.register_chatcommand("seen",{
	param = "<name>",
	description = "Tells the last time a player was online",
	func = function (name, param)
		if ( param ~= nil ) then
			local t = whoison.lastseen[param]
			if ( t ~= nil ) then
				local diff = (os.time() - t)
				minetest.chat_send_player(name,param.." was last online "..breakdowntime(diff).." ago")
			else
				minetest.chat_send_player(name,"Sorry, I have no record of "..param)
			end
		else
			minetest.chat_send_player(name,"Usage is /seen <name>")
		end
	end
}
)

function breakdowntime(t)
	local eng = {"Seconds","Minutes","Hours","Days","Weeks"}
	local inc = {60,60,60,24,7}	
	for k,v in ipairs(inc) do
		if ( t > v ) then
			t = math.floor( (t / v) )
		else
			return tostring(t).." "..eng[k]
		end	
	end	
end

minetest.after(10,whoison.createFile,true)

whoison.loadLastSeen()