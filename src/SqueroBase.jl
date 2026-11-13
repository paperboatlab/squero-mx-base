"""
    SqueroBase

The session layer of Squero Studio MX: `clear`/`clc` session events, and the bridges that hand
work to Paperboat (`optimize` builds a problem for its solver, `simulate` a run request for a
backend). It does not plot, solve or integrate; plotting is SqueroPlot's, solving and simulation
are Paperboat's.

The kernel collects what a statement recorded with `take_events`, `take_problems` and `take_runs`.
"""
module SqueroBase

using JSON3

export clear, clc
export optimize, OptimizationProblem, problem_json
export simulate, SimulationRequest, run_json
export take_events, take_problems, take_runs, reset_queues!

include("session.jl")
include("optimize.jl")
include("simulate.jl")

"""`reset_queues!()`: drop every recorded event, problem and run (a kernel `reset`)."""
function reset_queues!()
    empty!(EVENTS)
    empty!(PROBLEMS)
    empty!(RUNS)
    return nothing
end

end
