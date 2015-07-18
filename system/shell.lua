log("[luash] luash starting")
writeln("\f[luash v0]\n"..tostring(math.floor((computer.totalMemory()-computer.freeMemory())/1024)).. "k memory used, " .. tostring(math.floor(computer.totalMemory()/1024)) .. "k memory total\nPress enter to activate this terminal")
function ls(path)
 for k,v in ipairs(fs.list(path)) do
  writeln(v)
 end
end
function cat(path)
 local fobj = fs.open(path,"r")
 if fobj ~= nil then
  local dat = fs.readAll(fobj)
  for k,v in ipairs(string.split(dat,"\n")) do
   writeln(v)
  end
  fs.close(fobj)
 else
  writeln("Failed.")
 end
end
while true do
 local text=readln()
 if text == nil then text = "" end
 writeln(pcall(load(text),...))
end
