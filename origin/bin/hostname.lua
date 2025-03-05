local shell = require("shell")
local args, ops = shell.parse(...)
local hostname = args[1]

if hostname then
  local file, reason = io.open("/etc/hostname", "w")
  if not file then
    io.stderr:write("无法打开文件写入: ", reason, "\n")
    return 1
  end
  file:write(hostname)
  file:close()
  ops.update = true
else
  local file = io.open("/etc/hostname")
  if file then
    hostname = file:read("*l")
    file:close()
  end
end

if ops.update then
  os.setenv("HOSTNAME_SEPARATOR", hostname and #hostname > 0 and ":" or "")
  os.setenv("HOSTNAME", hostname)
elseif hostname then
  print(hostname)
else
  io.stderr:write("未设定主机名\n")
  return 1
end
