"""SqueroBase: the Julia-side verbs of Squero Studio MX.

It does not draw or solve. It turns MATLAB-like verbs into the JSON specifications owned by
Paperboat: chart specs for `@paperboat/shared/plot`/`station`, optimization problems for the
optimization toolkit, and `clear`/`clc` session events for `squero-kernel/0`.
"""
module SqueroBase

using JSON3

export plot, surf, mesh, imagesc, scatter, subplot
export optimize, state_space
export clear, clc
export meshgrid, peaks
export ChartSpec, OptimizationProblem
export take_charts, take_events, take_problems, chart_json, problem_json

include("charts.jl")
include("helpers.jl")
include("optimize.jl")
include("session.jl")

end
