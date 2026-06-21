@testset "Path optimization and extraction" begin
    mesh2 = TimeMesh(fill(1 // 1, 2))
    path = Path(HiGHS.Optimizer, PathOpt(2020:10:2020; mesh=mesh2))
    set_silent(model(path))
    add_dispatch_system!(path[2020], 4)

    @test_throws AssertionError extract(path)

    optimize!(path, cost(path))
    result = extract(path)
    @test result isa Path{Float64}
    @test capacity(result, "gen", 2020) ≈ 4.0
    @test deployment(result, "gen", 2020) ≈ 4.0
    @test occursin("optimized", sprint(show, result))
    @test_throws ArgumentError extract(result)
end
