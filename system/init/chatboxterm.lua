if component.list("chat_box")() ~= nil and _G.cbterm_loaded ~= true then
 log("[cbterm] Chatbox found, enabling cbterm!")
 local cbox = component.proxy(component.list("chat_box")())
 local cfghnd = fs.open("/boot/system/config/cbterm.cfg","r")
 if cfghnd ~= nil then
  local cfgfile = fs.readAll(cfghnd)
  fs.close(cfghnd)
  local config = string.split(cfgfile,"\n")
  local prefix=config[1]
  cbox.setDistance(tonumber(config[2]))
 else
  local prefix="#!>"
  cbox.setDistance(10)
 end
 event.listen("writeln",function(_,val)
  if val:find("\n") == nil then
   cbox.say(val)
  end
  for line in val:gmatch("[^\r\n]+") do
   cbox.say(line)
  end
 end)
 event.listen("chat_message",function(_,_,user,msg)
  if msg:sub(1,prefix:len())==prefix then
   event.push("readln",msg:sub(prefix:len()+1))
  end
 end)
 event.push("writeln","cbterm initialized.")
 _G.cbterm_loaded = true
end
