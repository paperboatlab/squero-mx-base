using Test
using JSON3
using SqueroBase
using Aqua

@testset "SqueroBase" begin

@testset "session events" begin
    reset_queues!()
    clear(); clear(:x, "y"); clc()
    events = take_events()
    @test [e["type"] for e in events] == ["clear", "clear", "clc"]
    @test !haskey(events[1], "names")
    @test events[2]["names"] == ["x", "y"]
    @test isempty(take_events())          # taken once
    @test clear() === nothing && clc() === nothing
    reset_queues!()
    @test isempty(take_events())
end

@testset "no plotting surface" begin
    for name in (:plot, :surf, :mesh, :meshgrid, :peaks, :state_space, :figure, :title, :xlabel, :hold, :subplot)
        @test !isdefined(SqueroBase, name)
    end
end

@testset "problems are queued for the kernel" begin
    take_problems()
    p = optimize((f = [-1.0, -1.0], lb = [0.0, 0.0], ub = [1.0, 1.0]))
    @test only(take_problems()) === p
    @test sprint(show, p) == "OptimizationProblem(lp)"
end

@testset "matrices travel as rows" begin
    problem = optimize((H = [2.0 1.0; 1.0 2.0], f = [-1.0, -1.0], A = [1.0 2.0], b = [3.0]))
    data = JSON3.read(problem_json(problem))
    @test data["H"] == [[2.0, 1.0], [1.0, 2.0]]
    @test data["A"] == [[1.0, 2.0]]
    @test sprint(write, problem) == problem_json(problem)
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
    @test_throws ArgumentError optimize((fun = "x1", H = [1.0;;]))
    @test_throws ArgumentError optimize((lb = [0.0],))
    take_problems()
end

@testset "conformance fixtures" begin
    fixture(name) = JSON3.read(read(joinpath(@__DIR__, "fixtures", name), String))
    for (name, kind) in (("lp.json", :lp), ("qp.json", :qp), ("nlp.json", :nlp))
        data = fixture(name)
        rebuilt = optimize(data)
        @test rebuilt.kind == kind
        for key in ("f", "H", "fun", "A", "b", "Aeq", "beq", "lb", "ub", "nonlcon", "options")
            haskey(data, key) && @test haskey(rebuilt.data, key)
        end
    end
    take_problems()
end

@testset "simulation bridge" begin
    take_runs()
    graph = (nodes = [(id = "plant", type = "control/state_space",
                       params = (A = [0.0 1.0; -2.0 -3.0], B = [0.0; 1.0;;], C = [1.0 0.0], D = [0.0;;], domain = :s))],
             edges = [])
    r = simulate(graph; duration = 10, dt = 0.01, solver = :rk45, variables = (x0 = [1.0, 0.0],))
    @test only(take_runs()) === r
    data = JSON3.read(run_json(r))
    @test data["type"] == "graph.run"
    @test data["settings"]["solver"] == "rk45" && data["settings"]["duration"] == 10.0 && data["settings"]["dt"] == 0.01
    @test data["graph"]["nodes"][1]["params"]["A"] == [[0.0, 1.0], [-2.0, -3.0]]
    @test data["graph"]["nodes"][1]["params"]["domain"] == "s"
    @test data["variables"]["x0"] == [1.0, 0.0]
    @test occursin("1 nodes", sprint(show, r))
    @test !haskey(JSON3.read(run_json(simulate((nodes = [], edges = []))))["settings"], "solver")
    @test_throws ArgumentError simulate((nodes = [],))
    @test_throws ArgumentError simulate(graph; solver = :magic)
    @test_throws ArgumentError simulate(graph; dt = 0)
    @test_throws ArgumentError simulate(graph; duration = -1)
    take_runs()
end

@testset "Aqua" begin
    Aqua.test_all(SqueroBase; persistent_tasks = false)
end

end
