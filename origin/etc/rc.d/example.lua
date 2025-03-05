local count = 0

function start(msg)
  print("该脚本显示了一条欢迎信息，并计数自身被调用的次数。欢迎信息可以在`/etc/rc.cfg`配置文件中修改。")
  print(args)
  if msg then
    print(msg)
  end
  print(count)
  print("runlevel: " .. require("computer").runlevel())
  count = count + 1
end
