while true do
 local text=syscall("readln")
 pcall(load(text))
end
