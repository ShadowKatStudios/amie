if component.list("chat_box")() ~= nil and _G.cbterm_loaded ~= true then
 syscall("log","[cbterm] Chatbox found, enabling cbterm!")
 local cbox = component.proxy(component.list("chat_box")())
 local cfghnd = syscall("fs_open","/boot/system/config/cbterm.cfg")
 local cfgfile = syscall("fs_read_all",cfghnd)
 syscall("fs_close",cfghnd)
 local lsp1=cfgfile:find("\n")
 local prefix=cfgfile:sub(1,lsp1-1)
 cbox.setDistance(tonumber(cfgfile:sub(lsp1+1)))
 syscall("event_listen","writeln",function(_,val)
  if val:find("\n") == nil then
   cbox.say(val)
  end
  for line in val:gmatch("[^\r\n]+") do
   cbox.say(line)
  end
 end)
 syscall("event_listen","chat_message",function(_,_,user,msg)
  if msg:sub(1,prefix:len())==prefix then
   syscall("event_push","readln",msg:sub(prefix:len()+1))
  end
 end)
 syscall("event_push","writeln","cbterm initialized.")
 _G.cbterm_loaded = true
end
