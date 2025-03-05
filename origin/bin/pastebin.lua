--[[ 该程序可用于从pastebin.com下载程序，或上传程序。
     作者: Sangar, Vexatos ]]
local component = require("component")
local fs = require("filesystem")
local internet = require("internet")
local shell = require("shell")

if not component.isAvailable("internet") then
  io.stderr:write("该程序需要因特网卡才能运行。")
  return
end

local args, options = shell.parse(...)

-- 该代码从网站获取代码并将其保存到指定文件中。
local function get(pasteId, filename)
  local f, reason = io.open(filename, "w")
  if not f then
    io.stderr:write("无法打开文件进行写入: " .. reason)
    return
  end

  io.write("正在从pastebin.com下载... ")
  local url = "https://pastebin.com/raw/" .. pasteId
  local result, response = pcall(internet.request, url)
  if result then
    io.write("成功\n")
    for chunk in response do
      if not options.k then
        string.gsub(chunk, "\r\n", "\n")
      end
      f:write(chunk)
    end

    f:close()
    io.write("将数据保存到 " .. filename .. "\n")
  else
    io.write("失败\n")
    f:close()
    fs.remove(filename)
    io.stderr:write("HTTP请求失败: " .. response .. "\n")
  end
end

-- 该代码确保字符串可安全用于URL。
local function encode(code)
  if code then
    code = string.gsub(code, "([^%w ])", function (c)
      return string.format("%%%02X", string.byte(c))
    end)
    code = string.gsub(code, " ", "+")
  end
  return code
end

-- 该代码将程序存储到临时文件，在程序执行完成后会删除。
local function run(pasteId, ...)
  local tmpFile = os.tmpname()
  get(pasteId, tmpFile)
  io.write("正在运行...\n")

  local success, reason = shell.execute(tmpFile, nil, ...)
  if not success then
    io.stderr:write(reason)
  end
  fs.remove(tmpFile)
end

-- 将指定文件上传为pastebin.com的一个新paste。
local function put(path)
  local config = {}
  local configFile = loadfile("/etc/pastebin.conf", "t", config)
  if configFile then
    local result, reason = pcall(configFile)
    if not result then
      io.stderr:write("加载配置失败: " .. reason)
    end
  end
  config.key = config.key or "fd92bd40a84c127eeb6804b146793c97"
  local file, reason = io.open(path, "r")

  if not file then
    io.stderr:write("无法打开文件进行读取: " .. reason)
    return
  end

  local data = file:read("*a")
  file:close()

  io.write("正在上传到pastebin.com... ")
  local result, response = pcall(internet.request,
        "https://pastebin.com/api/api_post.php",
        "api_option=paste&" ..
        "api_dev_key=" .. config.key .. "&" ..
        "api_paste_format=lua&" ..
        "api_paste_expire_date=N&" ..
        "api_paste_name=" .. encode(fs.name(path)) .. "&" ..
        "api_paste_code=" .. encode(data))

  if result then
    local info = ""
    for chunk in response do
      info = info .. chunk
    end
    if string.match(info, "^Bad API request, ") then
      io.write("失败\n")
      io.write(info)
    else
      io.write("成功\n")
      local pasteId = string.match(info, "[^/]+$")
      io.write("上传为" .. info .. "\n")
      io.write('运行 "pastebin get ' .. pasteId .. '" 以将其下载到任意位置')
    end
  else
    io.write("失败\n")
    io.stderr:write(response)
  end
end

local command = args[1]
if command == "put" then
  if #args == 2 then
    put(shell.resolve(args[2]))
    return
  end
elseif command == "get" then
  if #args == 3 then
    local path = shell.resolve(args[3])
    if fs.exists(path) then
      if not options.f or not os.remove(path) then
        io.stderr:write("文件已存在")
        return
      end
    end
    get(args[2], path)
    return
  end
elseif command == "run" then
  if #args >= 2 then
    run(args[2], table.unpack(args, 3))
    return
  end
end

-- 如果执行到了这里代表有无效输入
io.write("用法:\n")
io.write("pastebin put [-f] <文件>\n")
io.write("pastebin get [-f] <id> <文件>\n")
io.write("pastebin run [-f] <id> [<参数...>]\n")
io.write(" -f: 强制覆盖现有文件。\n")
io.write(" -k: 让换行符保持原样（否则会将Windows换行符转化为Unix换行符）。")