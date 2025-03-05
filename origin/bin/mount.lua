local fs = require("filesystem")
local shell = require("shell")

local function usage()
  io.stderr:write([==[
用法: mount [选项] [设备] [路径]")
  若不给定参数，则会输出当前的所有挂载点。
  `选项` 请注意可以同时使用多个选项
    -r, --ro    将文件系统挂载为只读
        --bind  创建绑定点挂载，从文件夹到文件夹
  `参数`
    `设备`      通过下列之一指定文件系统：
                  a. 标签
                  b. 地址（可以为缩写）
                  c. 文件夹路径（需要--bind）
    `路径`      要挂载到的文件夹路径

参见`man mount`获取更多细节
  ]==])
  os.exit(1)
end

-- 智能解析，将参数跟在-o后面
local args, opts = shell.parse(...)
opts.readonly = opts.r or opts.readonly

if opts.h or opts.help then
  usage()
end

local function print_mounts()
  -- 对每个挂载
  local mounts = {}

  for proxy,path in fs.mounts() do
    local device = {}

    device.dev_path = proxy.address
    device.mount_path = path
    device.rw_ro = proxy.isReadOnly() and "ro" or "rw"
    device.fs_label = proxy.getLabel() or proxy.address

    mounts[device.dev_path] = mounts[device.dev_path] or {}
    local dev_mounts = mounts[device.dev_path]
    table.insert(dev_mounts, device)
  end

  local smounts = {}
  for key,value in pairs(mounts) do
    smounts[#smounts+1] = {key, value}
  end
  table.sort(smounts, function(a,b) return a[1] < b[1] end)

  for _, dev in ipairs(smounts) do
    local dev_path, dev_mounts = table.unpack(dev)
    for _,device in ipairs(dev_mounts) do
      local rw_ro = "(" .. device.rw_ro .. ")"
      local fs_label = "\"" .. device.fs_label .. "\""

      io.write(string.format("%-8s 挂载于 %-10s %s %s\n",
        dev_path:sub(1,8),
        device.mount_path,
        rw_ro,
        fs_label))
    end
  end
end

local function do_mount()
  -- bind将路径转化为代理
  local proxy, reason = fs.proxy(args[1], opts)
  if not proxy then
    io.stderr:write("挂载失败: ", tostring(reason), "\n")
    os.exit(1)
  end

  local result, mount_failure = fs.mount(proxy, shell.resolve(args[2]))
  if not result then
    io.stderr:write(mount_failure, "\n")
    os.exit(2) -- 错误代码
  end
end

if #args == 0 then
  if next(opts) then
    io.stderr:write("缺少参数\n")
    usage()
  else
    print_mounts()
  end
elseif #args == 2 then
  do_mount()
else
  io.stderr:write("参数数量错误: ", #args, "\n")
  usage()
end
