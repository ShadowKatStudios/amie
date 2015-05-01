if component.list("gpu")() ~= nil and component.list("screen")() ~= nil then
 -- screen init
 local ttytab = {}
 ttytab.y = 1
 ttytab.gpu = {}
 ttytab.w,ttytab.h=0,0
 ttytab.cstr = ""
 ttytab.stack={}
 local function gpu_init()
  ttytab.gpu=component.proxy(component.list("gpu")())
  ttytab.gpu.bind(component.list("screen")())
  ttytab.w, ttytab.h = ttytab.gpu.getResolution()
  ttytab.gpu.setResolution(w,h)
  ttytab.gpu.setBackground(0x000000)
  ttytab.gpu.setForeground(0xFFFFFF)
  ttytab.gpu.fill(1,1,w,h," ")  
 end
 syscall("event_listen","writeln",function(v)
  if ttytab.gpu and ttytab.screen then
   ttytab.gpu.set(1, y, msg)
   if ttytab.y == ttytab.h - 1 then
    ttytab.gpu.copy(1, 2, w, h - 1, 0, -1)
    ttytab.gpu.fill(1, h, w, 1, " ")
   else
    y = y + 1
   end
  end
 end)
 local function redraw_text()
  local lineend = "_"
  local processed = cstr
  for k,v in pairs(1,w) do
   processed = processed .. " "
  end
  processed = processed..lineend
  ttytab.gpu.set(1,h,processed)
 end
 syscall("event_listen","char",function(char)
  cstr = cstr .. char
  redraw_text()
 end)
 syscall("event_listen","key_down",function(_,char,code,_)
  if code == "<backspace>" then
   cstr = cstr.sub(1,cstr.len()-1)
   redraw_text()
  elseif code == "<enter>" then
   syscall("event_push","readlndone",cstr)
   cstr=""
   redraw_text()
  else
   cstr = cstr .. string.char(char)
  end
 end)
 syscall("event_listen","readlndone",function(str)
  syscall("event_push","readln",str)
 end)
end
