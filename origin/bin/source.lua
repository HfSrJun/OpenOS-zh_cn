local shell = require("shell")
local process = require("process")

local args, options = shell.parse(...)

if #args ~= 1 then
  io.stderr:write("请指定一个文件以作为shell脚本执行\n");
  return 1
end

local file, open_reason = io.open(args[1], "r")

if not file then
  if not options.q then
    io.stderr:write(string.format("无法执行%s，原因为: %s\n", args[1], open_reason));
  end
  return 1
end

local lines = file:lines()

while true do
  local line = lines()
  if not line then
    break
  end
  local current_data = process.info().data

  local source_proc = process.load((assert(os.getenv("SHELL"), "no $SHELL set")))
  local source_data = process.list[source_proc].data
  source_data.aliases = current_data.aliases -- 传播子shell环境更改的小窍门
  source_data.vars = current_data.vars
  process.internal.continue(source_proc, _ENV, line)
end

file:close()
