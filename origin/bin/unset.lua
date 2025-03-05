local args = {...}

if #args < 1 then
  io.write("用法: unset <变量名>[ <变量名2> [...]]\n")
else
  for _, k in ipairs(args) do
    os.setenv(k, nil)
  end
end
