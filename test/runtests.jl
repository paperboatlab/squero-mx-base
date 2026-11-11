using Test
using JSON3
using SqueroBase

@testset "charts" begin
  plot(1:3, [1.0, 4.0, 9.0])
  chart = only(take_charts())
  @test chart.kind == :line
  data = JSON3.read(chart_json(chart))
  @test data["kind"] == "line"
  @test data["series"][1]["y"] == [1.0, 4.0, 9.0]

  subplot(2, 2, 3)
  surf(1:2, 1:3, [1 2; 3 4; 5 6])
  chart = only(take_charts())
  @test (chart.grid, chart.cell) == ((2, 2), (2, 1))
  @test chart.kind == :surface
end

@testset "solvers are selected from the fields" begin
  lp = optimize((f = [-3.0, -2.0], A = [2.0 1.0], b = [4.0], lb = [0.0, 0.0]))
  @test lp.kind == :lp
  @test !haskey(JSON3.read(problem_json(lp)), "options")

  qp = optimize((H = [2.0 0.0; 0.0 2.0], f = [-2.0, -1.0], Aeq = [1.0 1.0], beq = [1.0]))
  @test qp.kind == :qp

  nlp = optimize((fun = "(x1 - 1)^2 + (x2 - 2)^2", x0 = [0.5, 1.5],
                  nonlcon = (c = ["x1^2 + x2^2 - 2"],),
                  options = (display = "iter", tol = 1e-8, max_iter = 400)))
  @test nlp.kind == :nlp
  @test JSON3.read(problem_json(nlp))["options"]["display"] == "iter"

  @test_throws ArgumentError optimize((fun = x -> x[1], x0 = [0.0]))
  @test_throws ArgumentError optimize((f = [1.0], options = (display = "loud",)))
end

@testset "conformance fixtures" begin
  fixture(name) = JSON3.read(read(joinpath(@__DIR__, "fixtures", name), String))
  for (name, kind) in (("lp.json", :lp), ("qp.json", :qp), ("nlp.json", :nlp))
    data = fixture(name)
    rebuilt = optimize(data)
    @test rebuilt.kind == kind
    for key in ("f", "H", "fun", "A", "b", "Aeq", "beq", "lb", "ub", "nonlcon", "options")
      if haskey(data, key)
        @test haskey(rebuilt.data, key)
      end
    end
  end
end

@testset "session events" begin
  clear(); clear(:x); clc()
  events = take_events()
  @test events[1]["type"] == "clear"
  @test events[2]["names"] == ["x"]
  @test events[3]["type"] == "clc"
end

@testset "helpers" begin
  X, Y = meshgrid(1:3, 1:2)
  @test size(X) == (2, 3) && size(Y) == (2, 3)
  Xp, Yp, Z = peaks(9)
  @test size(Z) == (9, 9) && size(Xp) == (9, 9) && size(Yp) == (9, 9)
end
