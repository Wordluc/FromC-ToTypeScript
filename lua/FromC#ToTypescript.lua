local uv = require('luv')
local M = {}

local function manage_server(reg, host, port)
	local client = uv.new_tcp()
	client:connect(host, port, function(err)
		if err then
			print("Error connecting to server:", err)
			return
		end
		vim.schedule(function()
			client:write(vim.fn.getreg(reg))
		end)
		client:read_start(function(err, data)
			if err then
				print("Error receiving data: ", err)
				return
			end
			if data then
				local response = vim.json.decode(data)
				if response.Status.Code == 200 then
					vim.schedule(function()
						print("Converted")
						vim.fn.setreg(reg, response.Body)
					end)
				else
					print("Error:", response.Status.Msg)
				end
				client:close()
			end
		end)
	end)
end

M.convertDto = function(port, reg)
	if reg == nil then
		reg = ""
	end
	uv.run("nowait") -- This is necessary to start the event loop
	local script_path = debug.getinfo(1, "S").source:sub(2)
	local executable_path = script_path:match(".*/") .. "../src/GoFromCsToTypescript/GoFromCsToTypescript.exe"
	--local executable_path = "..\\..\\src\\GoFromCsToTypescript\\GoFromCsToTypescript.exe"
	local handle, pid = uv.spawn(
		executable_path
		, { args = { port } }, function() end
	)
	if handle == nil then
		print("Error starting server:" .. pid)
	end
	local timer = uv.new_timer()
	timer:start(200, 0, function()
		if pid then
			manage_server(reg, "127.0.0.1", port)
		else
			print("Error starting server creation job.")
		end

		timer:close()
	end)

	uv.stop()
end
return M
