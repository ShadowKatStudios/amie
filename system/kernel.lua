component.proxy(computer.getBootAddress()).remove("/system/system.log") -- clean off the old system log

function log(data)
 local bootfs=component.proxy(computer.getBootAddress())
 local handle=bootfs.open("/system/system.log","a")
 bootfs.write(handle,tostring(data) .. "\n")
 bootfs.close(handle)
end

function error(blah)
 log(blah)
end

log("amie DR0 starting.")

-- event code begins here, tame for now
_G.event = {}

local eventStack = {}
local listeners = {}
function event.listen(evtype,callback)
 if listeners[evtype] ~= nil then
  table.insert(listeners[evtype],callback)
  return #listeners
 else
  listeners[evtype] = {callback}
  return 1
 end
end
function event.ignore(evtype,id)
 table.remove(listeners[evtype],id)
end
function event.pull(filter)
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
end
function event.push(...)
 local tEv = {...}
 computer.pushSignal(...)
-- event.pull(tEv[1])
end

log("Event system loaded successfully")
-- 'terminal' code begins here. heh.

function writeln(...)
 event.push("writeln",...)
end
function readln()
 _,text = event.pull("readln")
 return text
end

log("Term I/O events loaded successfully")

-- testing, thanks stackoverflow
-- gonna leave this in, methinks. Super-useful function.
function string.split(inputstr, sep)
 if inputstr == nil then return {} end
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

function string.chars(str)
 local bT = {}
 for a = 1, string.len(str)+1 do
--  table.insert(bT, string.sub(str,a,a))
  bT[#bT+1] = string.sub(str,a,a)
 end
 return bT
end

log("String magic loaded.")

--Filesystem stuff begins here, "fun"
fs = {}
fs.drive_map={}
fs.drive_map["boot"]=component.proxy(computer.getBootAddress())
fs.drive_map["vfs"]={}
function fs.drive_map.vfs.list()
 log("VFS list called")
 --[[
 local t = {}
 for k,v in pairs(fs.drive_map) do
  table.insert(t,k)
  log("VFS list magic: "..v)
 end
 t[n]=#t
 return t
 ]]--
 return { "boot/", "temp/" } -- meaningful but hardcoded info ;-;
end

function fs.resolve(path)
 fields = string.split(path,"/")
 for k,v in pairs(fields) do
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
end

function fs.executeOnDrive(drive,method,...)
 return fs.drive_map[drive][method](...)
end

function fs.mount(index,proxy)
 fs.drive_map[index]=proxy -- totally not my fault if you break the shit out of everything using this.
end
function fs.umount(index)
 fs.drive_map[index]=nil
end

function fs.mounts() -- returns a table of mounted drives and their proxies
 return fs.drive_map
end

function fs.list(path)
 local drive,path = fs.resolve(path)
 local t = fs.executeOnDrive(drive,"list",path)
 t["n"] = nil
 return t
end

function fs.exists(path)
 local drive,path = fs.resolve(path)
 return fs.executeOnDrive(drive,"exists",path)
end
function fs.size(path)
 local drive,path = fs.resolve(path)
 return fs.executeOnDrive(drive,"size",path)
end
function fs.isDirectory(path)
 local drive,path = fs.resolve(path)
 return fs.executeOnDrive(drive,"isDirectory",path)
end
function fs.lastModified(path)
 local drive,path = fs.resolve(path)
 return fs.executeOnDrive(drive,"lastModified",path)
end
function fs.mkdir(path)
 local drive,path = fs.resolve(path)
 return fs.executeOnDrive(drive,"makeDirectory",path)
end
function fs.rmdir(path)
 local drive,path = fs.resolve(path)
 return fs.executeOnDrive(drive,"remove",path)
end

function fs.open(path,mode)
 local drive,path = fs.resolve(path)
 return {drive, fs.executeOnDrive(drive,"open",path,mode or "r")}
end

function fs.close(fobj)
 return fs.executeOnDrive(fobj[1],"close",fobj[2])
end

function fs.read(fobj,len)
 return fs.executeOnDrive(fobj[1],"read",fobj[2],len)
end

function fs.readAll(fobj)
 local a = ""
 s=fs.executeOnDrive(fobj[1],"read",fobj[2],math.huge)
 repeat
  a=a..s
  s=fs.executeOnDrive(fobj[1],"read",fobj[2],math.huge)
 until s == nil or s == ""
 return a
end

function fs.write(fobj,data)
 return fs.executeOnDrive(fobj[1],"write",fobj[2],data or "")
end

function loadfile(path)
 local fobj = fs.open(path)
 local c = load(fs.readAll(fobj))
 fs.close(fobj)
 return c
end
function runfile(path,...)
 return xpcall(loadfile(path),function() log(debug.traceback()) end,...)
end

log("Mounting /temp/")
fs.mount("temp",component.proxy(computer.tmpAddress()))

log(tostring(math.floor((computer.totalMemory()-computer.freeMemory())/1024)).."k memory used.")

local initFile = fs.open("/boot/system/config/init.cfg","r")
if initFile == nil then
 initFiles = fs.list("/boot/system/init") -- fallback - load everything. Probably going to be default.
 log("init.cfg not found, running everything.")
else
 log("init.cfg found, running selected files")
 initFiles = string.split(fs.readAll(initFile),"\n")
 fs.close(initFile)
end
log("Beginning init")
for k,v in pairs(initFiles) do
 log(v)
 runfile("/boot/system/init/"..v)
end

while true do
 for k,v in ipairs({runfile("/boot/system/shell.lua")}) do
  log(v)
 end
end
