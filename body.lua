if (ngx.ctx.ncf ~= 1) then
	return
end

local body = ngx.arg[1]
local cm = ngx.shared.cache
ngx.arg[2] = true
--save body to memory
cm:set(ngx.ctx.ck..":body",body,120)
