function syscall() -- will be overwritten - or at least inaccessable
 -- files to be grabbed, in the format {destination, url}
 local files = {
  {"/system/init/sttyh.lua","https://raw.githubusercontent.com/shadowkatstudios/amie/master/system/init/sttyh.lua"}
 }
 -- kernel can be run from RAM
 local kernel = "https://raw.githubusercontent.com/shadowkatstudios/amie/master/system/kernel.lua"
 -- I am a bad person.
 -- dirs to be created
 local dirs = {
  "/system",
 "/system/init",
 }
 
 local tmp = component.proxy(computer.tmpAddress())
 local inet = component.proxy(component.list("internet")())
 for k,v in ipairs(dirs) do
  tmp.makeDirectory(v)
  computer.beep()
 end
 
 local function getURL(url) --haaa
  local request, reason = inet.request(url, post)
  local s = ""
  repeat
   s = s..request.read()
  until data == nil
  return s
 end
 
 for k,v in ipairs(files) do
  local fData = getURL(v[2])
  local fHandle = tmp.open(v[1],"w")
  tmp.write(fHandle,fData)
  tmp.close(fHandle)
 end
 _G.kernelstr = getURL(kernel)
end

function computer.getBootAddress() -- I am a bad person.
 return computer.tmpAddress()
end

syscall()
load(_G.kernelstr)() -- don't mind leaving it accessable, in case they want to write it to disk