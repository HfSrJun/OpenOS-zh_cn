local component = require("component")
local fs = require("filesystem")
local internet = require("internet")
local shell = require("shell")
local text = require("text")

if not component.isAvailable("internet") then
  io.stderr:write("该程序需要因特网卡才能运行。")
  return
end

local args, options = shell.parse(...)
options.q = options.q or options.Q

if #args < 1 then
  io.write("用法: wget [-fq] <url> [<文件名>]\n")
  io.write(" -f: 强制覆盖现有文件\n")
  io.write(" -q: 安静模式，不输出状态信息\n")
  io.write(" -Q: 超级安静模式，不输出报错信息")
  return
end

local url = text.trim(args[1])
local filename = args[2]
if not filename then
  filename = url
  local index = string.find(filename, "/[^/]*$")
  if index then
    filename = string.sub(filename, index + 1)
  end
  index = string.find(filename, "?", 1, true)
  if index then
    filename = string.sub(filename, 1, index - 1)
  end
end
filename = text.trim(filename)
if filename == "" then
  if not options.Q then
    io.stderr:write("无法推断文件名，请指定一个")
  end
  return nil, "missing target filename" -- 提供给调用wget的程序
end
filename = shell.resolve(filename)

local preexisted
if fs.exists(filename) then
  preexisted = true
  if not options.f then
    if not options.Q then
      io.stderr:write("文件已存在")
    end
    return nil, "file already exists" -- 提供给调用wget的程序
  end
end

local f, reason = io.open(filename, "a")
if not f then
  if not options.Q then
    io.stderr:write("无法打开文件进行写入: " .. reason)
  end
  return nil, "failed opening file for writing: " .. reason -- 提供给调用wget的程序
end
f:close()
f = nil

if not options.q then
  io.write("下载中... ")
end
local result, response = pcall(internet.request, url, nil, {["user-agent"]="Wget/OpenComputers"})
if result then
  local result, reason = pcall(function()
    for chunk in response do
      if not f then
        f, reason = io.open(filename, "wb")
        assert(f, "无法打开文件进行写入: " .. tostring(reason))
      end
      f:write(chunk)
    end
  end)
  if not result then
    if not options.q then
      io.stderr:write("失败\n")
    end
    if f then
      f:close()
      if not preexisted then
        fs.remove(filename)
      end
    end
    if not options.Q then
      io.stderr:write("HTTP请求失败: " .. reason .. "\n")
    end
    return nil, reason -- 提供给调用wget的程序
  end
  if not options.q then
    io.write("成功\n")
  end

  if f then
    f:close()
  end

  if not options.q then
    io.write("将文件保存到" .. filename .. "\n")
  end
else
  if not options.q then
    io.write("失败\n")
  end
  if not options.Q then
    io.stderr:write("HTTP请求失败: " .. response .. "\n")
  end
  return nil, response -- 提供给调用wget的程序
end
return true -- 提供给调用wget的程序
