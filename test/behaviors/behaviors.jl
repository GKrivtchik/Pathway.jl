@testset "Path behaviors" begin
    mesh2 = TimeMesh(fill(1 // 1, 2))
    path = Path(HiGHS.Optimizer, PathOpt(2020:10:2020; mesh=mesh2))
    snap = path[2020]
    carrier = EnergyCarrier("behavior_power", snap.sim)
    grid = Node("behavior_grid", carrier)

    @test_throws ArgumentError VariableDeployment("output", energy; lb=-1)
    @test_throws ArgumentError VariableDeployment("output", energy; lb=2, ub=1)
    @test_throws ArgumentError FixedDeployment("output", energy, -1)
    @test_throws ArgumentError VariableRetirement("output", energy; lb=-1)
    @test_throws ArgumentError VariableRetirement("output", energy; lb=2, ub=1)
    @test_throws ArgumentError FixedRetirement("output", energy, -1)
    @test_throws ArgumentError Lifetime(0)
    @test_throws ArgumentError SingleCost(:capex, :bad, "output", energy, 1.0, nothing)
    @test_throws ArgumentError SingleCost(:capex, :deployment, "output", energy, 1.0, Dict(0 => 0.7))

    @test sprint(show, VariableDeployment("output", energy)) == "Variable deployment on \"output\" energy (0.0 <= deployment <= Inf)"
    @test sprint(show, FixedDeployment("output", energy, 3)) == "Fixed deployment on \"output\" energy (3.0)"
    @test sprint(show, VariableRetirement("output", energy)) == "Variable retirement on \"output\" energy (0.0 <= retirement <= Inf)"
    @test sprint(show, FixedRetirement("output", energy, 2)) == "Fixed retirement on \"output\" energy (2.0)"
    @test sprint(show, Lifetime(30)) == "Lifetime (30 year(s))"
    @test sprint(show, SingleCost(:capex, :deployment, "output", energy, 1.0, nothing)) == "Single cost :capex on deployment of \"output\" energy (1.0, profile 0 => 1.0)"
    @test sprint(show, SingleCost(:capex, :deployment, "output", energy, 2.0, Dict(-1 => 0.5, 0 => 0.5))) == "Single cost :capex on deployment of \"output\" energy (2.0, profile -1 => 0.5, 0 => 0.5)"

    @test_throws ArgumentError Component(
        "missing_port",
        DispatchableSource(carrier),
        [VariableCapacity("output", energy), VariableDeployment("missing", energy)],
    )
    @test_throws ArgumentError Component(
        "wrong_deployment_modifier",
        DispatchableSource(carrier),
        [VariableCapacity("output", mass), VariableDeployment("output", energy)],
    )
    @test_throws ArgumentError Component(
        "wrong_retirement_modifier",
        DispatchableSource(carrier),
        [VariableCapacity("output", mass), VariableRetirement("output", energy)],
    )

    gen = Component(
        "behavior_gen",
        DispatchableSource(carrier),
        [
            VariableCapacity("output", energy),
            VariableDeployment("output", energy; lb=1, ub=5),
            VariableRetirement("output", energy; lb=0, ub=5),
            Lifetime(12),
            SingleCost(:capex, :deployment, "output", energy, 3.0, Dict(0 => 1.0)),
        ],
    )
    connect!(snap, gen, grid)

    @test occursin("Component \"behavior_gen\" based on dispatchable source", sprint(show, gen))
    @test singlecost(path, "behavior_gen", 2020, :missing) == 0.0
    @test singlecost(path, "behavior_gen", 2019, :capex) == 0.0
end
