log("[ttyh] ttyh loaded, running.")
if component.list("gpu")() ~= nil and component.list("screen")() ~= nil then
 -- screen init
 log("[ttyh] GPU and screen found!")
 local ttytab = {}
 ttytab.gpu = {}
 ttytab.w,ttytab.h=0,0 -- resolution
 ttytab.cx,ttytab.cy = 1,1 -- current x and y
 local function gpu_init()
  ttytab.gpu=component.proxy(component.list("gpu")())
  ttytab.gpu.bind(component.list("screen")())
  ttytab.w, ttytab.h = ttytab.gpu.getResolution()
  ttytab.gpu.setResolution(ttytab.w,ttytab.h)
  ttytab.gpu.setBackground(0x000000)
  ttytab.gpu.setForeground(0xFFFFFF)
  ttytab.gpu.fill(1,1,ttytab.w,ttytab.h," ")
  ttytab.gpu.set(1,1,"█")
 end
 gpu_init()
 log("[ttyh] Terminal initialized.")
 local function newline()
  ttytab.gpu.set(ttytab.cx,ttytab.cy," ")
  ttytab.cx,ttytab.cy = 1,ttytab.cy+1 -- go to next line, return to start of line
  if ttytab.cy > ttytab.h then
   ttytab.gpu.copy(1, 2, ttytab.w, ttytab.h - 1, 0, -1)
   ttytab.gpu.fill(1, ttytab.h, ttytab.w, 1, " ")
   ttytab.cx,ttytab.cy = 1,ttytab.h
  end
  ttytab.gpu.set(ttytab.cx,ttytab.cy,"█ ")
 end
 event.listen("writeterm",function(_,char)
  if char == nil then return end
  if char == "\n" then
   newline()
  elseif char == "\r" then
   ttytab.gpu.set(ttytab.cx,ttytab.cy," ")
   ttytab.cx = 1 -- return to start of line
  elseif char == "\b" then
   if ttytab.cx > 1 then
    ttytab.cx = ttytab.cx - 1
    ttytab.gpu.set(ttytab.cx,ttytab.cy,"█ ")
   end
  elseif char == "\f" then
   ttytab.cx,ttytab.cy = 1,1
   gpu_init()
  else
   if ttytab.cx >ttytab.w then
    newline()
   end
   ttytab.gpu.set(ttytab.cx,ttytab.cy,char.."█ ")
   ttytab.cx = ttytab.cx + 1
  end
 end)
 event.listen("writeln",function(_,...)
  local sArgs = {...}
  for key, str in ipairs(sArgs) do
   str = tostring(str)
   local strtab = string.chars(str.."\n")
   strtab[#strtab]=nil
   for key,value in pairs(strtab) do
    event.push("writeterm",value)
   end
  end
 end)
 log("[ttyh] ttyh loaded successfully!")
end
