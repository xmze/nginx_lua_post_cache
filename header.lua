if (ngx.ctx.ncf ~= 1) then
	return
end
local cm = ngx.shared.cache
ngx.header.cua = "None"
local rh = ngx.resp.get_headers(100,true)
local header_s = ''
for h,v in pairs(rh) do
	header_s = header_s .. h .. ":" .. v .. "\n"
end
--ngx.log(ngx.ERR,header_s)
cm:set(ngx.ctx.ck..":header",header_s,120)

