local computer = require("computer")
local options

do
  local basic, reason = loadfile("/lib/core/install_basics.lua", "bt", _G)
  if not basic then
    io.stderr:write("加载install失败: " .. tostring(reason) .. "\n")
    return 1
  end
  options = basic(...)
end

if not options then
  return
end

if computer.freeMemory() < 50000 then
  print("内存不足，回收垃圾")
  for i = 1, 20 do
    os.sleep(0)
  end
end

local transfer = require("tools/transfer")
for _, inst in ipairs(options.cp_args) do
  local ec = transfer.batch(table.unpack(inst))
  if ec ~= nil and ec ~= 0 then
    return ec
  end
end

print("安装完成！")

if options.setlabel then
  pcall(options.target.dev.setLabel, options.label)
end

if options.setboot then
  local address = options.target.dev.address
  if computer.setBootAddress(address) then
    print("引导地址设定为" .. address)
  end
end

if options.reboot then
  io.write("立刻重启？[Y/n] ")
  if ((io.read() or "n") .. "y"):match("^%s*[Yy]") then
    print("\n正在重启！\n")
    computer.shutdown(true)
  end
end

print("正在返回shell。\n")
