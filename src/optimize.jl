# The optimization bridge: build exactly the problem JSON the C++ optimization toolkit reads
# (`read_problem` for LP/QP, `read_nlp_problem` for NLP; see schema/). The solver stays in Paperboat.

const PROBLEMS = Any[]

"""`take_problems()`: the problems built since the last call (and forget them)."""
take_problems() = (out = copy(PROBLEMS); empty!(PROBLEMS); out)

"""An LP, QP or NLP for the Paperboat optimization toolkit: `kind` and the problem's fields."""
struct OptimizationProblem
    kind::Symbol             # :lp, :qp or :nlp
    data::Dict{String, Any}
end

Base.show(io::IO, p::OptimizationProblem) = print(io, "OptimizationProblem(", p.kind, ")")

"""`problem_json(p)`: the JSON text the Paperboat optimization block reads."""
problem_json(p::OptimizationProblem) = JSON3.write(p.data)
Base.write(io::IO, p::OptimizationProblem) = print(io, problem_json(p))

_to_dict(x::AbstractDict) = Dict{String, Any}(string(k) => _plain(v) for (k, v) in x)
_to_dict(x::NamedTuple) = Dict{String, Any}(string(k) => _plain(v) for (k, v) in pairs(x))
_plain(v::AbstractDict) = _to_dict(v)
_plain(v::NamedTuple) = _to_dict(v)
_plain(v::AbstractVector) = [_plain(x) for x in v]
# A matrix is rows of numbers, the shape the C++ readers expect (not JSON3's flat column order).
_plain(v::AbstractMatrix) = [[_plain(v[i, j]) for j in axes(v, 2)] for i in axes(v, 1)]
_plain(v::Tuple) = [_plain(x) for x in v]
_plain(v::Symbol) = string(v)
_plain(v::Function) = throw(ArgumentError("pass the objective/constraints as expression strings (x1, x2, …); a Julia Function cannot travel to Paperboat"))
_plain(v) = v

"""
    optimize(problem) -> OptimizationProblem

Build an LP, QP or NLP from the fields present (`f`, `H`, `fun`, `x0`, `A`, `b`, `Aeq`, `beq`,
`lb`, `ub`, `nonlcon`, `options`) and queue it for Paperboat's solver. `fun` and `nonlcon` are
expression strings over `x1, x2, …`. The result comes back to the app, which binds `x_opt` and
`f_opt`.
"""
function optimize(problem)
    data = _to_dict(problem)
    if haskey(data, "options")
        options = data["options"]
        if haskey(options, "display")
            display = lowercase(string(options["display"]))
            display in ("off", "final", "iter", "iter-detailed", "final-detailed", "notify") ||
                throw(ArgumentError("options.display must be off, final or iter"))
            options["display"] = display
        end
    end
    kind = haskey(data, "fun") ? :nlp : (haskey(data, "H") && data["H"] !== nothing ? :qp : :lp)
    kind === :nlp && haskey(data, "H") && throw(ArgumentError("an NLP has fun, not H"))
    kind === :nlp && !(data["fun"] isa AbstractString) && throw(ArgumentError("fun must be an expression string"))
    kind === :lp && !haskey(data, "f") && throw(ArgumentError("an LP needs f (or give fun and x0 for an NLP)"))
    p = OptimizationProblem(kind, data)
    push!(PROBLEMS, p)
    return p
end
