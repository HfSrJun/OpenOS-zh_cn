local computer = require("computer")
local total = computer.totalMemory()
local max = 0
for _=1,40 do
  max = math.max(max, computer.freeMemory())
  os.sleep(0) -- 调用gc
end
io.write(string.format("总计%12d\n已使用%13d\n空闲%13d\n", total, total - max, max))
