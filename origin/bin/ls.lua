-- 如果可以的话，加载complex（内存可能不足）

local ok, why = pcall(function(...)
  return loadfile("/lib/core/full_ls.lua", "bt", _G)(...)
end, ...)

if not ok then
  if type(why) == "table" then
    if why.code == 0 then
      return
    end
    why = why.reason
  end
  io.stderr:write(tostring(why) .. "\n对于内存较小的设备，请尝试使用`list`\n")
  return 1
end

return why
