if component.list("chat_box")() ~= nil and _G.cbterm_loaded ~= true then
 syscall("log","[netterm] Modem found, enabling netterm")
 local modem = component.proxy(component.list("modem")())
 local cfghnd = syscall("fs_open","/boot/system/config/netterm.cfg")
 local cfgfile = syscall("fs_read_all",cfghnd)
 local sclients = {}
 local buffer = ""
 syscall("fs_close",cfghnd)
 local lsp1=cfgfile:find("\n")
 local pass=cfgfile:sub(1,lsp1-1)
 syscall("event_listen","writeln",function(_,val)
  for k,v in ipaies(sclients) do
   modem.send(v,22,val)
  end
 end)
 syscall("event_listen","modem_message",function(_,_,from,_,dat1,dat2,dat3)
  if dat1 == "subscribe" then
   if dat2 == pass then
    table.insert(sclients,from)
    syscall("log","[netterm] Client "..from.." added to list.")
    modem.send(from,22,"ack")    
   else
    syscall("log","[netterm] Client "..from.." denied access with pass "..dat2)
    modem.send(from,22,"nak")
   end
  elseif dat1 == "keypress" and dat2 == pass then
   buffer=buffer..dat3
  elseif dat1 == "unsub" then
   local nclients = {}
   for k,v in ipairs(sclients) do
    if v ~= from then
     table.insert(nclients,v)
    end
   end
   sclients=nclients
  end
 end)
 syscall("event_push","writeln","netterm initialized.")
 _G.cbterm_loaded = true
end
