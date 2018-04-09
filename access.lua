local cache_on = ngx.var.lua_cache
if (cache_on ~= 'on') then
	return
end

--from http://lua-users.org/wiki/SplitJoin
function split(str, pat)
   local t = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
         table.insert(t,cap)
      end
      last_end = e+1
      s, e, cap = str:find(fpat, last_end)
   end
   if last_end <= #str then
      cap = str:sub(last_end)
      table.insert(t, cap)
   end
   return t
end
local method = ngx.req.get_method()
local tg_arg = ngx.var.cache_key_get_arg
local tp_arg = ngx.var.cache_key_post_arg
if not (tg_arg or tp_arg) then
	return
end
if (method == "GET" and tg_arg == nil) then
	return
end

local tg_t = split(tg_arg,',')
local tp_t = split(tp_arg,',')
if not (tg_t or tp_t) then
	return
end
local cct = ''
--for loop get args
if (tg_t) then
	for i in pairs(tg_t) do
		local arg = ngx.var['arg_'..tg_t[i]]
		if (arg) then
			cct = cct .. 'g' .. tg_t[i] .. ":" .. arg .. ":"
		end
	end
end
--for loop post args
--ngx.say("cct:"..cct)
if (method == "POST" and tp_t) then
	--lua_need_request_body()
	ngx.req.read_body()
	local content_type = ngx.req.get_headers()["content-type"]
	-- urlencoded
	if string.find(content_type,"urlencoded") then
		local args,err = ngx.req.get_post_args()
		if not args then
			return
		end
		for k,v in pairs(args) do
			if type(v) ~= "table" then
				cct = cct .. 'p' .. k .. ":" .. v .. ":"
			end
		end
	-- multipart/form-data don't support now!
	elseif string.find(content_type,"form-data") then
	-- json
	elseif string.find(content_type,"json") then
	end
end
local cm = ngx.shared.cache
local ck = ngx.md5(cct)
local mck = cm:get(ck..":body")
local hmck = cm:get(ck..":header")
if ((mck and hmck)== nil) then
	ngx.ctx.ncf = 1
	ngx.ctx.ck = ck
else
	local tt = ''
	local header_lr = split(hmck,'\n')
	if header_lr then
		for i in pairs(header_lr) do
			--tt = tt .. header_lr[i] .. "\n"
			local header_l = split(header_lr[i],':')
			--tt = tt .. header_l[2] .. '\n'
			ngx.header[header_l[1]] = nil
			ngx.header[header_l[1]] = header_l[2]
		end
	end
	ngx.ctx.ncf = 0
	ngx.header.cua = "HIT"
	ngx.print(mck)
end
