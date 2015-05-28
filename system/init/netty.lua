if component.list("modem")() ~= nil then
 local modem = component.proxy(component.list("modem")())
 local password = ""
 local port = ""
 local stHosts = {}
 local lnbuffer = {}
 syscall("event_listen","modem_message",function(_,from,port,_,t,d)
  if t == "regListen" and d == password then
   table.insert(stHosts,from)
  elseif t == "readln" then
   table.insert(lnbuffer,d)
  end
 end)
 syscall("event_listen","writeln",function(data)
  for k,v in ipairs(stHosts) do
   modem.send(v,port,data)
  end
 end)
 syscall("event_listen","readln",function()
  if lnbuffer[1] ~= nil then
   return table.remove(lnbuffer,1)
  else
   repeat
    syscall("event_pull","modem_message")
   until lnbuffer[1] ~= nil
   return table.remove(lnbuffer,1)
  end
 end
end
