# Helpers MATLAB scripts expect that Julia Base does not define with the same shape.

"""`meshgrid(x, y)` returns `X, Y`, both `length(y) × length(x)`, as MATLAB does."""
function meshgrid(x, y)
  X = [xi for _ in y, xi in x]
  Y = [yi for yi in y, _ in x]
  return X, Y
end

"""The `peaks` height field over `[-3, 3]²`, n × n."""
function peaks(n::Integer = 49)
  n >= 2 || throw(ArgumentError("peaks needs at least 2 points per side"))
  x = range(-3.0, 3.0, length = n)
  X, Y = meshgrid(x, x)
  Z = [3 * (1 - xi)^2 * exp(-xi^2 - (yi + 1)^2) -
       10 * (xi / 5 - xi^3 - yi^5) * exp(-xi^2 - yi^2) -
       exp(-(xi + 1)^2 - yi^2) / 3 for yi in x, xi in x]
  return X, Y, Z
end
