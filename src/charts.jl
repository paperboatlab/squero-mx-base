# Chart specifications: the shape `@paperboat/shared/plot` and `station` render. The Julia side
# only records them; the kernel returns them with an eval reply and the app renders them.

const SCHEMA_VERSION = 1
const CHARTS = Any[]
const SUBPLOT = Ref((1, 1, 1, 1))  # rows, cols, row, col

mutable struct ChartSpec
  kind::Symbol
  title::String
  grid::Tuple{Int, Int}
  cell::Tuple{Int, Int}
  series::Vector{Any}
  options::Dict{String, Any}
end

function chart_json(spec::ChartSpec)
  return JSON3.write(Dict(
    "kind" => string(spec.kind),
    "title" => spec.title,
    "grid" => [spec.grid[1], spec.grid[2]],
    "cell" => [spec.cell[1], spec.cell[2]],
    "series" => spec.series,
    "options" => spec.options,
    "schema" => SCHEMA_VERSION,
  ))
end

chart_json(charts::AbstractVector) = JSON3.write([JSON3.read(chart_json(c)) for c in charts])
take_charts() = (out = copy(CHARTS); empty!(CHARTS); out)

"""`subplot(m, n, p)` sets the page and cell for the following charts, as MATLAB does."""
function subplot(m::Integer, n::Integer, p::Integer)
  m > 0 && n > 0 || throw(ArgumentError("subplot needs positive m and n"))
  1 <= p <= m * n || throw(ArgumentError("subplot cell $p is outside $m × $n"))
  row = (p - 1) ÷ n + 1
  col = (p - 1) % n + 1
  SUBPLOT[] = (Int(m), Int(n), row, col)
  nothing
end

function _push(kind::Symbol, title::AbstractString, series; options = Dict{String, Any}())
  rows, cols, row, col = SUBPLOT[]
  spec = ChartSpec(kind, String(title), (rows, cols), (row, col), series, options)
  push!(CHARTS, spec)
  spec
end

_thex = (v) -> collect(v)
_series(; kwargs...) = Dict{String, Any}(
  String(k) => _thex(v) for (k, v) in kwargs
  if v !== nothing && !(v isa AbstractString && isempty(v))
)

"""`plot(y)` / `plot(x, y)`: one or more lines."""
function plot(y; title = "plot", label = "", color = "")
  plot(1:length(y), y; title = title, label = label, color = color)
end

function plot(x, y; title = "plot", label = "", color = "")
  _push(:line, title, [_series(x = x, y = y, label = label, color = color)])
end

"""`surf(x, y, z)`: a surface. `mesh` is the same spec with the wireframe option."""
function surf(x, y, z; title = "surf", colormap = "viridis")
  _push(:surface, title, [_series(x = x, y = y, z = z)], options = Dict("wireframe" => false, "colormap" => colormap))
end

function mesh(x, y, z; title = "mesh")
  _push(:surface, title, [_series(x = x, y = y, z = z)], options = Dict("wireframe" => true))
end

"""`imagesc(z)` / `heatmap(z)`: a matrix as a colour field."""
function imagesc(z; title = "imagesc", colormap = "viridis")
  _push(:heat, title, [_series(z = z)], options = Dict("colormap" => colormap))
end

"""`scatter(x, y)`: points."""
function scatter(x, y; title = "scatter", color = "")
  _push(:scatter, title, [_series(x = x, y = y, color = color)])
end
