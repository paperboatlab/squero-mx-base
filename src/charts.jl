# Chart specifications: the shape `@paperboat/shared/plot` and `station` render. The Julia side
# only records them; the kernel returns them with an eval reply and the app renders them.

const SCHEMA_VERSION = 1
const CHARTS = Any[]
const SUBPLOT = Ref((1, 1, 1, 1))  # rows, cols, row, col
const COLORMAP = Ref("viridis")

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

"""`colormap(name)` sets the colour map the following charts use."""
colormap(name::AbstractString) = (COLORMAP[] = String(name); nothing)
colormap(name::Symbol) = colormap(string(name))

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

# The C++ readers and the app take a matrix as rows of numbers, and a surface's x/y as one
# vector each. JSON3 would write a matrix flat (column-major), so convert here, once.
_series_value(::Val{:z}, v::AbstractMatrix) = [[Float64(x) for x in row] for row in eachrow(v)]
_series_value(::Val{:z}, v) = [Float64(x) for x in collect(v)]
_series_value(::Val{:x}, v::AbstractMatrix) = [Float64(x) for x in v[1, :]]
_series_value(::Val{:y}, v::AbstractMatrix) = [Float64(x) for x in v[:, 1]]
_series_value(_, v) = [Float64(x) for x in collect(v)]

_series(; kwargs...) = Dict{String, Any}(
  String(k) => _series_value(Val(k), v) for (k, v) in kwargs
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
surf(xyz::Tuple; kwargs...) = surf(xyz...; kwargs...)
surf(z::AbstractMatrix; kwargs...) = surf(1:size(z, 2), 1:size(z, 1), z; kwargs...)

function surf(x, y, z; title = "surf", colormap = COLORMAP[], point = nothing)
  options = Dict{String, Any}("wireframe" => false, "colormap" => colormap)
  point === nothing || (options["point"] = collect(point))
  _push(:surface, title, [_series(x = x, y = y, z = z)], options = options)
end

function mesh(x, y, z; title = "mesh", point = nothing)
  options = Dict{String, Any}("wireframe" => true)
  point === nothing || (options["point"] = collect(point))
  _push(:surface, title, [_series(x = x, y = y, z = z)], options = options)
end

"""`imagesc(z)` / `heatmap(z)`: a matrix as a colour field."""
imagesc(xyz::Tuple; kwargs...) = imagesc(xyz[3]; kwargs...)
function imagesc(z; title = "imagesc", colormap = COLORMAP[])
  _push(:heat, title, [_series(z = z)], options = Dict("colormap" => colormap))
end

"""`scatter(x, y)`: points."""
function scatter(x, y; title = "scatter", color = "")
  _push(:scatter, title, [_series(x = x, y = y, color = color)])
end
