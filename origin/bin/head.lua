local shell = require("shell")

local args, options = shell.parse(...)
local error_code = 0

local function pop(key, convert)
  local result = options[key]
  options[key] = nil
  if result and convert then
    local c = tonumber(result)
    if not c then
      io.stderr:write(string.format("请使用--%s=n，此处的n为数字\n", key))
      options.help = true
      error_code = 1
    end
    result = c
  end
  return result
end

local bytes = pop('bytes', true)
local lines = pop('lines', true)
local quiet = {pop('q'), pop('quiet'), pop('silent')}
quiet = quiet[1] or quiet[2] or quiet[3]
local verbose = {pop('v'), pop('verbose')}
verbose = verbose[1] or verbose[2]
local help = pop('help')

if help or next(options) then
  local invalid_key = next(options)
  if invalid_key then
    invalid_key = string.format('无效选项: %s\n', invalid_key)
    error_code = 1
  else
    invalid_key = ''
  end
  print(invalid_key .. [[用法: head [--lines=n] 文件
输出给定的各个`文件`的前10行到标准输出。
要获取更多信息请执行：man head]])
  os.exit(error_code)
end

if #args == 0 then
  args = {'-'}
end

if quiet and verbose then
  quiet = false
end

local function new_stream()
  return
  {
    open=true,
    capacity=math.abs(lines or bytes or 10),
    bytes=bytes,
    buffer=(lines and lines < 0 and {}) or (bytes and bytes < 0 and '')
  }
end

local function close(stream)
  if stream.buffer then
    if type(stream.buffer) == 'table' then
      stream.buffer = table.concat(stream.buffer)
    end
    io.stdout:write(stream.buffer)
    stream.buffer = nil
  end
  stream.open = false
end

local function push(stream, line)
  if not line then
    return close(stream)
  end

  local cost = stream.bytes and line:len() or 1
  stream.capacity = stream.capacity - cost

  if not stream.buffer then
    if stream.bytes and stream.capacity < 0 then
      line = line:sub(1,stream.capacity-1)
    end
    io.write(line)
    if stream.capacity <= 0 then
      return close(stream)
    end
  else
    if type(stream.buffer) == 'table' then -- 存储行
      stream.buffer[#stream.buffer+1] = line
      if stream.capacity < 0 then
        table.remove(stream.buffer, 1)
        stream.capacity = 0 -- zero out
      end
    else -- 存储字节
      stream.buffer = stream.buffer .. line
      if stream.capacity < 0 then
        stream.buffer = stream.buffer:sub(-stream.capacity+1)
        stream.capacity = 0 -- zero out
      end
    end
  end

end

for i=1,#args do
  local arg = args[i]
  local file, reason
  if arg == '-' then
    arg = 'standard input'
    file = io.stdin
  else
    file, reason = io.open(arg, 'r')
    if not file then
      io.stderr:write(string.format([[head: 无法打开'%s'进行读取: %s]], arg, reason))
    end
  end
  if file then
    if verbose or #args > 1 then
      io.write(string.format('==> %s <==\n', arg))
    end

    local stream = new_stream()

    while stream.open do
      push(stream, file:read('*L'))
    end

    file:close()
  end
end
