@testset "Path options" begin
    mesh2 = TimeMesh(fill(1 // 1, 2))
    mesh1 = TimeMesh(fill(1 // 1, 1))

    @test PathOpt(2030:-10:2020; mesh=mesh2).years == [2020, 2030]
    @test PathOpt(; mesh=mesh2).baseyear == 0
    @test PathOpt(; mesh=mesh2).endyear == 0
    meshes = Dict{Int64,TimeMesh}(2030 => mesh1, 2020 => mesh2)
    @test mesh(PathOpt(2020:10:2030; mesh=meshes), 2030) === mesh1
    @test discount(PathOpt(2020:10:2030; discountrate=0.05, baseyear=2020, mesh=mesh2), 2030) ≈ 1 / 1.05^10

    @test_throws ArgumentError PathOpt([2020, 2020]; mesh=mesh2)
    @test_throws ArgumentError PathOpt(2020:10:2030; discountrate=0.5, mesh=mesh2)
    @test_throws ArgumentError PathOpt(2020:10:2030; baseyear=2040, endyear=2030, mesh=mesh2)
    @test_throws ArgumentError PathOpt(2020:10:2030; endyear=2025, mesh=mesh2)
    @test_throws ArgumentError PathOpt(2020:10:2030; mesh=Dict{Int64,TimeMesh}(2020 => mesh2))
    @test_throws ArgumentError PathOpt(Int[]; mesh=Dict{Int64,TimeMesh}())
    @test_throws ArgumentError mesh(PathOpt(2020:10:2030; mesh=mesh2), 2040)
    @test_throws ArgumentError PathOpt(2020:10:2030; mesh=mesh2, ini=[(2020, "gen", 1, 20)])
    @test_throws ArgumentError PathOpt(2020:10:2030; mesh=mesh2, ini=[(1990, "gen", 1, 20)])

    @test occursin("Path options (2 snapshot year(s): 2020:10:2030", sprint(show, PathOpt(2020:10:2030; mesh=mesh2)))
    @test occursin("0 historical capacity entries", sprint(show, PathOpt(; mesh=mesh2)))
end
