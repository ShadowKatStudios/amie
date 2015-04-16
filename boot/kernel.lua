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

component.proxy(computer.getBootAddress()).remove("/system.log") -- clean off the old system log

syscall("register","log", function(data)
 local bootfs=component.proxy(computer.getBootAddress())
 local handle=bootfs.open("system.log","a")
 bootfs.write(handle,tostring(data) .. "\n")
 bootfs.close(handle)
end)

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
 computer.pushSignal(...)
end)

syscall("log","Event system initiated")

syscall("register","writeln", function(...)
 local targ = {...}
 for k,v in pairs(targ) do
  syscall("event_push","writeln",v)
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

--Filesystem stuff, "fun"
fs = {}
fs.drive_map={}
fs.drive_map["boot"]=component.proxy(computer.getBootAddress())
fs.drive_map["vfs"]={}
function fs.drive_map.vfs.list()
 syscall("log","VFS list called")
 local t = {}
 for k,v in pairs(fs.drive_map) do
  table.insert(t,k)
  syscall("log","VFS list magic: "..v)
 end
 t[n]=#t
 --return t
 return { "Fuck it, I don't need a fancy meta-VFS to make everything else, it's just stopping progress." }
end

syscall("register","fs_resolve",function(path)
 syscall("log","Splitting path:")
 fields = string.split(path,"/")
 for k,v in pairs(fields) do
  syscall("log",v)
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

--sanity check, we could probably use one or two
local testpath = "/boot/maybe/init.lua"
local a,b=syscall("fs_resolve",testpath)
syscall("log","FS resolver init, sanity check: "..testpath.." resolves to drive ".. a .. " with path ".. b)
-- fs_exec_on_drive test
syscall("log","Attempting to list /boot/ as a sanity check:")
local t = syscall("fs_exec_on_drive","boot","list","/")
for k,v in pairs(t) do
 syscall("log",k.." : "..v)
end
-- this is a bad idea, VFS listing, prepare for everything to crash
-- no crash, just shit all happening. Good to know.
syscall("log","Attempting to list / as a sanity check:")
local t = syscall("fs_exec_on_drive","vfs","list","/")
for k,v in pairs(t) do
 syscall("log",k.." : "..v)
end

