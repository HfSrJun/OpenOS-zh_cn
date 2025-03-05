local shell = require("shell")
local args, options = shell.parse(...)

if options.help then
  print([[用法: sleep 数字[后缀]...
暂停运行`数字`秒。`后缀`可以是's'代表秒（默认）、'm'代表分钟、'h'代表小时、'd'代表
天。不像大多数实现中`数字`必须是整数，这里的数字可以是任意浮点数。给定两个或更多的参
数，将会暂停所有参数的总和。]])
end

local function help(bad_arg)
  print("sleep: 无效选项 -- '"..tostring(bad_arg).."'")
  print("执行`sleep --help`以获取更多信息。")
end

local function time_type_multiplier(time_type)
  if not time_type or #time_type == 0 or time_type == 's' then
    return 1
  elseif time_type == 'm' then
    return 60
  elseif time_type == 'h' then
    return 60 * 60
  elseif time_type == 'd' then
    return 60 * 60 * 24
  end

  -- 神秘问题，我的错
  assert(false,'解析参数失败:'..tostring(time_type))
end

options.help = nil
if next(options) then
  help(next(options))
  return 1
end

local total_time = 0

for _,v in ipairs(args) do
  local interval, time_type = v:match('^([%d%.]+)([smhd]?)$')
  interval = tonumber(interval)

  if not interval or interval < 0 then
    help(v)
    return 1
  end

  total_time = total_time + time_type_multiplier(time_type) * interval
end

local ins = io.stdin.stream
local pull = ins.pull
local start = 1
if not pull then
  pull = require("event").pull
  start = 2
end
pull(select(start, ins, total_time, "interrupted"))
