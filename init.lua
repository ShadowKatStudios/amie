_G.bootaddr = computer.getBootAddress() -- get boot address, from Lua BIOS
local bootfs = component.proxy(_G.bootaddr) -- assign that FS to local bootfs
local handle = bootfs.open("/system/kernel.lua","r") -- open a handle for boot/kernel.lua on that drive

-- read magics
c=""
s=bootfs.read(handle,math.huge)
repeat
 c=c..s
 s=bootfs.read(handle,math.huge)
until s==nil -- tl;dr this loop reads the contents of the file into variable c

bootfs.close(handle) -- close the handle, as there is a limit (and memory!)

load(c)() -- load and execute boot/kernel.lua
