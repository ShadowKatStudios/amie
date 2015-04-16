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

--Filesystem stuff, "fun"
fs = {}
fs.cpath = "boot:/"
fs.drive_map = {}
fs.active_drive = "boot"
syscall("register","fs_mount",function(proxy,index) fs.drive_map[index]=proxy end)
syscall("register","fs_unmount",function(index) fs.drive_map[index]=nil end)
syscall("register","fs_proxy",function(index) return fs.drive_map[index] end)
syscall("register","fs_invoke",function(method,...) return fs.drive_map[fs.active_drive][method](...) end) --wtf?
syscall("register","fs_invoke_on_drive",function(method,drive,...) return fs.drive_map[drive][method](...) end) --wtf?
syscall("register","fs_get_drive",function() return fs.active_drive end)
syscall("register","fs_set_drive",function(index) fs.active_drive=index end)
syscall("register","fs_get_drive_map", function() return fs.drive_map end)
syscall("register","fs_exists", function(path) drive,path = syscall("fs_resolve",path) return syscall("fs_invoke_on_drive",drive,"exists",path) end)
syscall("register","fs_is_dir", function(path) drive,path = syscall("fs_resolve",path) return syscall("fs_invoke_on_drive",drive,"isDirectory",path) end)
syscall("register","fs_mkdir", function(path) drive,path = syscall("fs_resolve",path) return syscall("fs_invoke_on_drive",drive,"makeDirectory",path) end)
syscall("register","fs_list", function(path) drive,path = syscall("fs_resolve",path) return syscall("fs_invoke_on_drive",drive,"list",path or "/") end)
syscall("register","fs_remove", function(path) drive,path = syscall("fs_resolve",path) return syscall("fs_invoke_on_drive",drive,"remove",path) end)
syscall("register","fs_move", function(path1, path2) syscall("fs_copy",path1,path2) return syscall("fs_remove",path1) end)
syscall("register","fs_size", function(path) drive,path = syscall("fs_resolve",path) return syscall("fs_invoke_on_drive",drive,"size",path) end)
syscall("register","fs_resolve",function(path)
 local path=path:gsub("\\","/")
 local sC,_ = path:find(":") or path:len()
 local sS,_ = path:find("/") or 0
 if sC < sS then
  return path:sub(1,sC-1), path:sub(sC+1,path:len())
 else
  return syscall("fs_get_drive"), path
 end
end)
syscall("register","fs_open",function(path,mode)
 if not mode then mode = "r" end
 local proxyFile = {}
 local handle = 0
 local drive, path = syscall("fs_resolve",path)
 local fsInUse = syscall("fs_get_drive_map")[drive]
 if fsInUse == nil then return false, "drive not found" end
 if not fsInUse.exists(path) and mode:sub(1,1) == "r" then return false, "file not found" end
 handle = fsInUse.open(path,mode)
 if mode:sub(1,1) == "r" then
  function proxyFile.read(len)
   if not len then len = math.huge end
   return fsInUse.read(handle,len)
  end
 else
  function proxyFile.write(data)
   fsInUse.write(handle,data)
  end
 end
 function proxyFile.close()
  fsInUse.close(handle)
  proxyFile = nil
  fsInUse = nil
 end
 function proxyFile.seek(w,o)
  fsInUse.seek(handle,w,o)
 end
 return proxyFile
end)
syscall("register","fs_copy", function(origPath, destPath)
 local sF = syscall("fs_open",origPath,"r")
 local dF = syscall("fs_open",destPath,"w")
 if not sF or not dF then return false, "file not found" end
 c = ""
 l = ""
 repeat
  l=sF.read() or ""
  dF.write(l)
 until l == ""
 sF.close()
 dF.close()
end)
syscall("fs_mount",component.proxy(computer.getBootAddress()),"boot")

syscall("register","loadfile", function(path)
 f=syscall("fs_open",path)
 c=""
 s=f.read()
 repeat
  c=c..s
  s=f.read()
 until s==nil
 return load(c)
end)
syscall("register","runfile", function(path,...)
 return syscall("loadfile",path)(...)
end)

syscall("log","Filesystem loaded, boot device: "..fs.drive_map[syscall("fs_get_drive")].address)

-- actual init stuff \o/

for file in syscall("fs_list","boot:/system/hooks/") do
 syscall("runfile","boot:/system/hooks/"..file)
end
