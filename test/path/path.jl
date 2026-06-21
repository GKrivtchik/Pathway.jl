@testset "Path construction and snapshots" begin
    mesh2 = TimeMesh(fill(1 // 1, 2))

    psim = PathSim(HiGHS.Optimizer, PathOpt(2020:10:2030; mesh=mesh2))
    @test occursin("ScaledOptimizer", solver_name(psim.model))
    @test psim.model === psim.dsim[2020].model
    @test psim.dsim[2030].options[:scalingtarget] == 1

    jump_model = Model()
    psim = PathSim(jump_model, PathOpt(2020:10:2020; mesh=mesh2))
    @test psim.model === jump_model
    @test psim.dsim[2020].model === jump_model

    empty_path = Path(HiGHS.Optimizer, PathOpt(; mesh=mesh2))
    set_silent(model(empty_path))
    @test isempty(snapshotyears(empty_path))
    @test occursin("Pathway with 0 snapshot year(s) (no years)", sprint(show, empty_path))

    snap2020 = addsnapshot!(empty_path, 2020)
    @test snap2020 === empty_path[2020]
    @test snapshotyears(empty_path) == [2020]
    @test firstsnapshotyear(empty_path) == 2020
    @test lastsnapshotyear(empty_path) == 2020
    @test lastyear(empty_path) == 2020

    snap2030 = Snapshot(Sim(Model(), mesh=mesh2))
    @test_throws ArgumentError addsnapshot!(empty_path, snap2030, 2030)
    snap2030 = Snapshot(Sim(model(empty_path), mesh=mesh2, suffix="2030"))
    @test addsnapshot!(empty_path, snap2030, 2030) === snap2030
    @test snapshotyears(empty_path) == [2020, 2030]
    @test lastyear(empty_path) == 2030
    @test haskey(empty_path, 2020)
    @test length(collect(values(empty_path))) == 2
    first_pair = first(empty_path)
    @test first_pair.first == 2020
    @test first_pair.second === empty_path.snap[2020]

    opt = PathOpt(2020:10:2030; discountrate=0.05, endyear=2030, mesh=mesh2)
    path = Path(HiGHS.Optimizer, opt)
    set_silent(model(path))

    @test length(path) == 2
    @test collect(keys(path)) == [2020, 2030]
    @test path[2020] === getsnapshot(path, 2020)
    @test nsteps(sim(path, 2020)) == 2
    @test alltech(path) == String[]
    @test occursin("Pathway with 2 snapshot year(s) (2020:10:2030)", sprint(show, path))
    @test sprint(show, path.sim) == "Path simulation (2 snapshot year(s), ScaledOptimizer(HiGHS))"
    @test startswith(sprint(show, path.snap[2020]), "Meta snapshot 2020: Snapshot with 0 component(s)")
    @test snapshotyear(path, 2029) == 2020
    @test snapshotyear(path, 2030) == 2030
    @test_throws ArgumentError snapshotyear(path, 2019)
    @test_throws ArgumentError getsnapshot(path, 2010)

    ini_path = Path(HiGHS.Optimizer, PathOpt(2020:10:2030; mesh=mesh2, ini=[(2010, "old_gen", 2, 30)]))
    @test firstyear(ini_path) == 2010
    @test first(allyears(ini_path)) == 2010
    @test "old_gen" in alltech(ini_path)

    add_dispatch_system!(path[2020], 10)
    add_dispatch_system!(path[2030], 20)
    add_dispatch_system!(path[2030], 0; late=true)

    @test alltech(path) == ["gen", "late_gen", "load"]
    @test capacity(path, "late_gen", 2020) == 0.0
    @test fixedcost(path, "late_gen", 2020) == 0.0
    @test variablecost(path, "late_gen", 2020) == 0.0
end
