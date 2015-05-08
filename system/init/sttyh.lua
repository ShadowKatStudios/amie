if component.list("gpu")() ~= nil and component.list("screen")() ~= nil then
 -- screen init
 syscall("log","GPU and screen found!")
 local ttytab = {}
 ttytab.gpu = {}
 ttytab.w,ttytab.h=0,0
 ttytab.cx,ttytab.cy = 1,1 -- current x and y
 local function gpu_init()
  ttytab.gpu=component.proxy(component.list("gpu")())
  ttytab.gpu.bind(component.list("screen")())
  ttytab.w, ttytab.h = ttytab.gpu.getResolution()
  ttytab.gpu.setResolution(ttytab.w,ttytab.h)
  ttytab.gpu.setBackground(0x073642)
  ttytab.gpu.setForeground(0xFDF6E3)
  ttytab.gpu.fill(1,1,ttytab.w,ttytab.h," ")
  ttytab.gpu.set(1,1,"█")
 end
 gpu_init()
 syscall("log","Found GPU and screen!")
 syscall("event_listen","writeln",function(v)
  syscall("log","writing "..v)
  for char in v:gmatch(".") do
   if char == "\n" then
    ttytab.cx,ttytab.cy = 1,ttytab.cy+1 -- go to next line, return to start of line
    syscall("log","newline!")
   elseif char == "\r" then
    ttytab.cx = 1 -- return to start of line
    syscall("log","return!")
   elseif char == "\b" then
    if ttytab.cx > 1 then
     ttytab.cx = ttytab.cx - 1
     ttytab.gpu.set(ttytab.cx,ttytab.cy,"█ ")
    end
    syscall("log","backspace!")
   else
    ttytab.gpu.set(ttytab.cx-1,ttytab,cy,char.."█ ")
    syscall("log","wrote "..char)
   end
  end
 end)
 syscall("log","Successfully initiated sttyh.lua")
 syscall("write","this is a test\naaa\rbbb\b")
 syscall("log","Written text to screen!")
end
