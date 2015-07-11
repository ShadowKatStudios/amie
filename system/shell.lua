log("Reached the shell! :D")
while true do
 local text=readln()
 pcall(load(text))
end
