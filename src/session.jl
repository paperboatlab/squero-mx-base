# Session events: the kernel applies these after the current top-level statement. They are not
# renders; `clear` resets the session module, `clc` clears the console.

const EVENTS = Any[]

"""`clear()` resets the session; `clear(:x)` drops one binding."""
function clear(names...)
  if isempty(names)
    push!(EVENTS, Dict("type" => "clear"))
  else
    push!(EVENTS, Dict("type" => "clear", "names" => [string(n) for n in names]))
  end
  nothing
end

"""`clc()` clears the console."""
function clc()
  push!(EVENTS, Dict("type" => "clc"))
  nothing
end

take_events() = (out = copy(EVENTS); empty!(EVENTS); out)
