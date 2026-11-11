# The optimization surface: build exactly the problem JSON the C++ optimization toolkit reads
# (`read_problem` for LP/QP, `read_nlp_problem` for NLP). The solver stays in Paperboat.

const PROBLEM_SCHEMA_VERSION = 1

struct OptimizationProblem
  kind::Symbol             # :lp, :qp or :nlp
  data::Dict{String, Any}
end

function Base.show(io::IO, p::OptimizationProblem)
  print(io, "OptimizationProblem(", p.kind, ")")
end

"""The JSON text the Paperboat optimization block reads."""
problem_json(p::OptimizationProblem) = JSON3.write(p.data)
Base.write(io::IO, p::OptimizationProblem) = print(io, problem_json(p))

_to_dict(x::AbstractDict) = Dict{String, Any}(string(k) => _plain(v) for (k, v) in x)
_to_dict(x::NamedTuple) = Dict{String, Any}(string(k) => _plain(v) for (k, v) in pairs(x))
_plain(v::AbstractDict) = _to_dict(v)
_plain(v::NamedTuple) = _to_dict(v)
_plain(v::AbstractVector) = [_plain(x) for x in v]
_plain(v::Tuple) = [_plain(x) for x in v]
_plain(v::Function) = throw(ArgumentError("pass the objective/constraints as expression strings (x1, x2, …); a Julia Function cannot travel to Paperboat"))
_plain(v) = v

"""`optimize(problem)` builds an LP, QP or NLP from the fields present."""
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
  return OptimizationProblem(kind, data)
end
