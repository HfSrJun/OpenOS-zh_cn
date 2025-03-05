local component = require("component")
local shell = require("shell")
local fs = require("filesystem")

local args, options = shell.parse(...)

if #args < 1 and not options.l then
  io.write("用法: flash [-qlr] [<bios.lua>] [标签]\n")
  io.write(" q: 安静模式，不询问用户。\n")
  io.write(" l: 显示当前安装的EEPROM的内容。\n")
  io.write(" r: 将当前安装的EEPROM中的内容保存到文件。\n")
  return
end

local function printRom()
  local eeprom = component.eeprom
  io.write(eeprom.get())
end

local function readRom()
  local eeprom = component.eeprom
  local fileName = shell.resolve(args[1])
  if not options.q then
    if fs.exists(fileName) then
      io.write("确定要覆盖" .. fileName .. "吗？\n")
      io.write("输入`y`进行确定。\n")
      repeat
        local response = io.read()
      until response and response:lower():sub(1, 1) == "y"
    end
    io.write("读取EEPROM " .. eeprom.address .. "。\n" )
  end
  local bios = eeprom.get()
  local file = assert(io.open(fileName, "wb"))
  file:write(bios)
  file:close()
  if not options.q then
    io.write("完成！\n标签为'" .. eeprom.getLabel() .. "'。\n")
  end
end

local function writeRom()
  local file = assert(io.open(args[1], "rb"))
  local bios = file:read("*a")
  file:close()

  if not options.q then
    io.write("请插入你需要刷写的EEPROM。\n")
    io.write("准备好写入时，输入`y`确定。\n")
    repeat
      local response = io.read()
    until response and response:lower():sub(1, 1) == "y"
    io.write("开始刷写EEPROM.\n")
  end

  local eeprom = component.eeprom

  if not options.q then
    io.write("正在刷写EEPROM" .. eeprom.address .. "。\n")
    io.write("请不要在此操作期间关机或重启电脑！\n")
  end

  eeprom.set(bios)

  local label = args[2]
  if not options.q and not label then
    io.write("输入该EEPROM的新标签。留空则不修改标签。\n")
    label = io.read()
  end
  if label and #label > 0 then
    eeprom.setLabel(label)
    if not options.q then
      io.write("将标签设置为'" .. eeprom.getLabel() .. "'。\n")
    end
  end

  if not options.q then
    io.write("完成！你可以移除EEPROM并重新安装原有EEPROM了。\n")
  end
end

if options.l then
  printRom()
elseif options.r then
  readRom()
else
  writeRom()
end
