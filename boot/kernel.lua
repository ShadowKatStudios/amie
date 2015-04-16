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

syscall("register","fs_resolve",function(path)
 syscall("log","Splitting path:")
 fields = string.split(path,"/")
 for k,v in pairs(fields) do
  syscall("log",v)
 end
 drive=table.remove(fields,1)
 dpath = ""
 for k,v in pairs(fields) do
  dpath = dpath .. "/" .. v
 end
 return drive,dpath
end)
local testpath = "/boot/maybe/init.lua"
local a,b=syscall("fs_resolve",testpath)
syscall("log","FS resolver init, sanity check: "..testpath.." resolves to drive ".. a .. " with path ".. b)

