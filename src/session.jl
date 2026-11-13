# Session events: the kernel applies these after the current top-level statement. They are not
# functions that mutate the caller: `clear` makes the kernel swap in a fresh session module (or
# drop names), `clc` tells the app to clear its console. Neither touches the app's figure history.

"""The events recorded since the last `take_events()`, in order."""
const EVENTS = Any[]

"""
    clear()
    clear(:x, :y)

`clear()` resets the session before the next statement; `clear(:x)` drops just those bindings.
Figures already in the app's history stay there.
"""
function clear(names...)
    if isempty(names)
        push!(EVENTS, Dict{String, Any}("type" => "clear"))
    else
        push!(EVENTS, Dict{String, Any}("type" => "clear", "names" => [string(n) for n in names]))
    end
    return nothing
end

"""`clc()` clears the app's console."""
function clc()
    push!(EVENTS, Dict{String, Any}("type" => "clc"))
    return nothing
end

"""`take_events()`: the recorded session events (and forget them)."""
take_events() = (out = copy(EVENTS); empty!(EVENTS); out)
