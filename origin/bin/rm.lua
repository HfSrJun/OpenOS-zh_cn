local fs = require("filesystem")
local shell = require("shell")

local function usage()
  print("用法: rm [选项] <文件名1> [<文件名2> [...]]"..[[

  -f          忽略不存在的文件与参数，从不提示
  -r          递归删除目录与其中的内容
  -v          解释做出的操作
      --help  显示该帮助信息并退出

要获取完整文档与更多选项，请运行: man rm]])
end

local args, options = shell.parse(...)
if #args == 0 or options.help then
  usage()
  return 1
end

local bRec = options.r or options.R or options.recursive
local bForce = options.f or options.force
local bVerbose = options.v or options.verbose
local bEmptyDirs = options.d or options.dir
local promptLevel = (options.I and 3) or (options.i and 1) or 0

bVerbose = bVerbose and not bForce
promptLevel = bForce and 0 or promptLevel

local function perr(...)
  if not bForce then
    io.stderr:write(...)
  end
end

local function pout(...)
  if not bForce then
    io.stdout:write(...)
  end
end

local metas = {}

-- promptLevel 3 done before fs.exists
-- promptLevel 1 asks for each, displaying fs.exists on hit as it visits

local function _path(m) return shell.resolve(m.rel) end
local function _link(m) return fs.isLink(_path(m)) end
local function _exists(m) return _link(m) or fs.exists(_path(m)) end
local function _dir(m) return not _link(m) and fs.isDirectory(_path(m)) end
local function _readonly(m) return not _exists(m) or fs.get(_path(m)).isReadOnly() end
local function _empty(m) return _exists(m) and _dir(m) and (fs.list(_path(m))==nil) end

local function createMeta(origin, rel)
  local m = {origin=origin,rel=rel:gsub("/+$", "")}
  if _dir(m) then
    m.rel = m.rel .. '/'
  end
  return m
end

local function unlink(path)
  os.remove(path)
  return true
end

local function confirm()
  if bForce then
    return true
  end
  local r = io.read()
  return r == 'y' or r == 'yes'
end

local remove

local function remove_all(parent)
  if parent == nil or not _dir(parent) or _empty(parent) then
    return true
  end

  local all_ok = true
  if bRec and promptLevel == 1 then
    pout(string.format("rm: 进入目录`%s`继续操作？ ", parent.rel))
    if not confirm() then
      return false
    end

    for file in fs.list(_path(parent)) do
      local child = createMeta(parent.origin, parent.rel .. file)
      all_ok = remove(child) and all_ok
    end
  end

  return all_ok
end

remove = function(meta)
  if not remove_all(meta) then
    return false
  end

  if not _exists(meta) then
    perr(string.format("rm: 无法删除`%s`: 不存在该文件或目录\n", meta.rel))
    return false
  elseif _dir(meta) and not bRec and not (_empty(meta) and bEmptyDirs) then
    if not bEmptyDirs then
      perr(string.format("rm: 无法删除`%s`: 为目录\n", meta.rel))
    else
      perr(string.format("rm: 无法删除`%s`: 目录非空\n", meta.rel))
    end
    return false
  end

  local ok = true
  if promptLevel == 1 then
    if _dir(meta) then
      pout(string.format("rm: 要删除目录`%s`吗？", meta.rel))
    elseif meta.link then
      pout(string.format("rm: 要删除符号链接`%s`吗？", meta.rel))
    else -- 文件
      pout(string.format("rm: 要删除普通文件`%s`吗？", meta.rel))
    end

    ok = confirm()
  end

  if ok then
    if _readonly(meta) then
      perr(string.format("rm: 无法删除`%s': 为只读\n", meta.rel))
      return false
    elseif not unlink(_path(meta)) then
      perr(meta.rel .. ": 删除失败\n")
      ok = false
    elseif bVerbose then
      pout("已删除'" .. meta.rel .. "'\n");
    end
  end

  return ok
end

for _,arg in ipairs(args) do
  metas[#metas+1] = createMeta(arg, arg)
end

if promptLevel == 3 and #metas > 3 then
  pout(string.format("rm: 删除%i参数吗？", #metas))
  if not confirm() then
    return
  end
end

local ok = true
for _,meta in ipairs(metas) do
  local result = remove(meta)
  ok = ok and result
end

return bForce or ok
