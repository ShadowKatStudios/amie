if component.list("gpu")() ~= nil and component.list("screen")() ~= nil then
 -- screen init
 local ttytab = {}
 ttytab.gpu = {}
 ttytab.w,ttytab.h=0,0
 ttytab.cx,ttytab.cy = 1,1 -- current x and y
 local function gpu_init()
  ttytab.gpu=component.proxy(component.list("gpu")())
  ttytab.gpu.bind(component.list("screen")())
  ttytab.w, ttytab.h = ttytab.gpu.getResolution()
  ttytab.gpu.setResolution(w,h)
  ttytab.gpu.setBackground(0x073642)
  ttytab.gpu.setForeground(0xFDF6E3)
  ttytab.gpu.fill(1,1,w,h," ")
  ttytab.gpu.set(1,1,"█")
 end
 if ttytab.gpu and ttytab.screen then
  syscall("event_listen","write",function(v)
   for char in v:gmatch(".") do
    if char == "\n" then
     ttytab.cx,ttytab.cy = 1,ttytab.cy+1 -- go to next line, return to start of line
    elseif char == "\r" then
     ttytab.cx = 1 -- return to start of line
    elseif char == "\b" then
     if ttytab.cx > 1 then
      ttytab.cx = ttytab.cx - 1
      ttytab.gpu.set(ttytab.cx,ttytab.cy,"█ ")
     end
    else
     ttytab.gpu.set(ttytab.cx-1,ttytab,cy,char.."█ ")
    end
   end
  end)
 end
end
