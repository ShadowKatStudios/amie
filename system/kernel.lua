syscalls = {}
syscalls.lmods = {}
function syscalls.register(name,callback)
 syscalls[name] = callback
end
function syscall(name,...)
 call = syscalls[name]
 if call then
  return call(...)
 else
  error("syscall failed: "..name)
 end
end

component.proxy(computer.getBootAddress()).remove("/system/system.log") -- clean off the old system log

syscall("register","log", function(data)
 local bootfs=component.proxy(computer.getBootAddress())
 local handle=bootfs.open("/system/system.log","a")
 bootfs.write(handle,tostring(data) .. "\n")
 bootfs.close(handle)
end)

function error(blah)
 syscall("log",blah)
end

syscall("log","Begin logging.")

syscall("register","set_module_loaded", function(name)
 syscalls.lmods[name] = true
end)
syscall("register","set_module_unloaded", function(name)
 syscalls.lmods[name] = nil
end)

syscall("log","Module system initiated")

local eventStack = {}
local listeners = {}
syscall("register","event_listen", function(evtype,callback)
 if listeners[evtype] ~= nil then
  table.insert(listeners[evtype],callback)
  return #listeners
 else
  listeners[evtype] = {callback}
  return 1
 end
end)
syscall("register","event_ignore", function(evtype,id)
 table.remove(listeners[evtype],id)
end)
syscall("register","event_pull", function(filter)
 if not filter then return table.remove(eventStack,1)
 else
  for _,v in pairs(eventStack) do
   if v == filter then
    return v
   end
  end
  repeat
   t=table.pack(computer.pullSignal())
   evtype = table.remove(t,1)
   if listeners[evtype] ~= nil then
    for k,v in pairs(listeners[evtype]) do
     local evt,rasin = pcall(v,evtype,table.unpack(t))
     if not evt then
     end
    end
   end
  until evtype == filter
  return evtype, table.unpack(t)
 end
end)
syscall("register","event_push", function(...)
 local tEv = {...}
 computer.pushSignal(...)
 syscall("event_pull",tEv[1])
end)

syscall("log","Event system initiated")

_G.writeFunctions = {}
syscall("register","write", function(...)
 local targ = {...}
 for k,v in pairs(targ) do
  for j,w in pairs(writeFunctions) do
   pcall(w,v)
  end
 end
end)
syscall("register","readln",function()
 text = syscall("event_pull","readln")
 return text
end)

syscall("log","Term I/O initiated")

-- testing, thanks stackoverflow
-- gonna leave this in, methinks. Super-useful function.
function string.split(inputstr, sep)
 if sep == nil then
  sep = "%s"
 end
 local t={} ; i=1
 for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
  t[i] = str
  i = i + 1
 end
 return t
end
function string.cut(inputstr,len)
 local inputstr = tostring(inputstr)
 if inputstr:len() < len then
  return {inputstr}
 else
  local t = {}
  repeat
   table.insert(t,string.sub(inputstr,1,len))
   inputstr = string.sub(inputstr,len+1)
  until inputstr == ""
  return t
 end
end

syscall("log","String magic loaded.")

--Filesystem stuff, "fun"
fs = {}
fs.drive_map={}
fs.drive_map["boot"]=component.proxy(computer.getBootAddress())
fs.drive_map["vfs"]={}
function fs.drive_map.vfs.list()
 syscall("log","VFS list called")
 --[[
 local t = {}
 for k,v in pairs(fs.drive_map) do
  table.insert(t,k)
  syscall("log","VFS list magic: "..v)
 end
 t[n]=#t
 return t
 ]]--
 return { "Fuck it, I don't need a fancy meta-VFS to make everything else, it's just stopping progress." }
end

syscall("register","fs_resolve",function(path)
 -- syscall("log","Splitting path:") -- damn debug messages
 fields = string.split(path,"/")
 for k,v in pairs(fields) do
 --  syscall("log",v)
  if v == ".." then
   table.remove(fields,k)
   table.remove(fields,k-1)
  end
  if v == "." then
   table.remove(fields,k)
  end
 end
 local drive=table.remove(fields,1)
 if drive == nil or drive == "" then
  drive = "vfs"
 end
 dpath = ""
 for k,v in pairs(fields) do
  dpath = dpath .. "/" .. v
 end
 if dpath == "" then
  dpath = "/"
 end
 return drive,dpath
end)

-- poptarts get

syscall("register","fs_exec_on_drive",function(drive,method,...)
 return fs.drive_map[drive][method](...)
end)

-- dinner get

syscall("register","fs_mount",function(index,proxy)
 fs.drive_map[index]=proxy -- totally not my fault if you break the shit out of everything using this.
end)
syscall("register","fs_umount",function(index)
 fs.drive_map[index]=nil
end)

syscall("register","fs_mounts",function() -- returns a table of mounted drives and their proxies
 return fs.drive_map
end)

syscall("register","fs_list",function(path)
 local drive,path = syscall("fs_resolve",path)
 local t = syscall("fs_exec_on_drive",drive,"list",path)
 t["n"] = nil
 return t
end)

syscall("register","fs_exists",function(path)
 local drive,path = syscall("fs_resolve",path)
 return syscall("fs_exec_on_drive",drive,"exists",path)
end)
syscall("register","fs_size",function(path)
 local drive,path = syscall("fs_resolve",path)
 return syscall("fs_exec_on_drive",drive,"size",path)
end)
syscall("register","fs_is_directory",function(path)
 local drive,path = syscall("fs_resolve",path)
 return syscall("fs_exec_on_drive",drive,"isDirectory",path)
end)
syscall("register","fs_timestamp",function(path)
 local drive,path = syscall("fs_resolve",path)
 return syscall("fs_exec_on_drive",drive,"lastModified",path)
end)
syscall("register","fs_make_directory",function(path)
 local  drive,path = syscall("fs_resolve",path)
 return syscall("fs_exec_on_drive",drive,"makeDirectory",path)
end)
syscall("register","fs_make_directory",function(path)
 local drive,path = syscall("fs_resolve",path)
 return syscall("fs_exec_on_drive",drive,"remove",path)
end)

-- and here's the big one

syscall("log","fs_open up next!")

syscall("register","fs_open", function(path,mode)
 drive,path = syscall("fs_resolve",path)
 return {drive, syscall("fs_exec_on_drive",drive,"open",path,mode or "r")}
end)

syscall("register","fs_close", function(fobj)
 return syscall("fs_exec_on_drive",fobj[1],"close",fobj[2])
end)

syscall("register","fs_read", function(fobj,len)
 return syscall("fs_exec_on_drive",fobj[1],"read",fobj[2],len)
end)

syscall("register","fs_read_all", function(fobj)
 local a = ""
 s=syscall("fs_exec_on_drive",fobj[1],"read",fobj[2],math.huge)
 repeat
  a=a..s
  s=syscall("fs_exec_on_drive",fobj[1],"read",fobj[2],math.huge)
 until s == nil or s == ""
 return a
end)

syscall("register","fs_write", function(fobj,data)
 return syscall("fs_exec_on_drive",fobj[1],"write",fobj[2],data or "")
end)

syscall("register","loadfile",function(path)
 local fobj = syscall("fs_open",path)
 local c = load(syscall("fs_read_all",fobj))
 syscall("fs_close",fobj)
 return c
end)
syscall("register","runfile",function(path,...)
 syscall("loadfile",path)(...)
end)

-- both a useful test and a useful function: mount the temporary filesystem
syscall("log","Mounting /temp/") -- heheheh
syscall("fs_mount","temp",component.proxy(computer.tmpAddress()))

syscall("log",tostring(math.floor((computer.totalMemory()-computer.freeMemory())/1024)).."k memory used.")

while true do
 for k,v in pairs(syscall("fs_list","/boot/system/init")) do
  syscall("log",v)
  syscall("runfile","/boot/system/init/"..v)
 end
end
