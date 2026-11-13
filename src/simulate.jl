# The simulation bridge: a `graph.run` request for a Paperboat backend (`paperboat/0`). The graph's
# blocks (state_space, transfer_fn, rhs, …) and their solvers are Paperboat's; SqueroBase only
# packages the request, with matrices as rows. The app sends it to the attached backends.

const RUNS = Any[]

"""`take_runs()`: the run requests built since the last call (and forget them)."""
take_runs() = (out = copy(RUNS); empty!(RUNS); out)

const SOLVERS = ("rk4", "rk45", "rk2", "euler", "discrete", "cvode", "ida")

"""A `graph.run` message for a Paperboat backend."""
struct SimulationRequest
    data::Dict{String, Any}
end

Base.show(io::IO, r::SimulationRequest) = print(io, "SimulationRequest(", length(r.data["graph"]["nodes"]), " nodes, ",
    get(r.data["settings"], "duration", "default"), " s)")

"""`run_json(r)`: the `graph.run` message as JSON text."""
run_json(r::SimulationRequest) = JSON3.write(r.data)

"""
    simulate(graph; duration, dt, solver, speed, variables) -> SimulationRequest

Queue a run of a Paperboat graph (`nodes`, `edges`; a NamedTuple or Dict in the backend's graph
shape). Settings left out keep the backend's defaults. `solver` is one of rk4, rk45, rk2, euler,
discrete, cvode, ida. `variables` are sent with the run (matrices as rows).
"""
function simulate(graph; duration = nothing, dt = nothing, solver = nothing, speed = nothing, variables = nothing)
    g = _to_dict(graph)
    haskey(g, "nodes") && haskey(g, "edges") || throw(ArgumentError("a graph has nodes and edges"))
    settings = Dict{String, Any}("mode" => "clock")
    duration === nothing || (duration >= 0 || throw(ArgumentError("duration must be ≥ 0")); settings["duration"] = Float64(duration))
    dt === nothing || (dt > 0 || throw(ArgumentError("dt must be > 0")); settings["dt"] = Float64(dt))
    speed === nothing || (settings["speed"] = Float64(speed))
    if solver !== nothing
        s = lowercase(string(solver))
        s in SOLVERS || throw(ArgumentError("solver must be one of $(join(SOLVERS, ", "))"))
        settings["solver"] = s
    end
    data = Dict{String, Any}("type" => "graph.run", "graph" => g, "settings" => settings)
    variables === nothing || (data["variables"] = _to_dict(variables))
    r = SimulationRequest(data)
    push!(RUNS, r)
    return r
end
