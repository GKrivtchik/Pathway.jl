@testset "Initial capacity" begin
    ini = InitialCapacity([(2010, "gen", 2, 20)])
    @test ini.capacities[2010][1].capacity == 2.0
    @test InitialCapacity([(year=2010, cname="gen", capacity=2, lifetime=20)]).capacities[2010][1].cname == "gen"
    @test InitialCapacity(ini) === ini
    @test isempty(InitialCapacity().capacities)
    @test collect(keys(InitialCapacity([(2015, "a", 1, 20), (2010, "b", 2, 20)]).capacities)) == [2010, 2015]

    @test_throws ArgumentError InitialCapacity([(2010, "gen", 2, 20), (2010, "gen", 3, 20)])
    @test_throws ArgumentError InitialCapacity([(2010, "gen", 0, 20)])
    @test_throws ArgumentError InitialCapacity([(2010, "gen", 1, 0)])
    @test_throws ArgumentError InitialCapacity([(2010, "gen", 1, 20.5)])

    @test sprint(show, ini.capacities[2010][1]) == "Historical capacity \"gen\" (2.0, lifetime 20 year(s))"
    @test sprint(show, ini) == "Initial capacity with 1 entry in 1 year(s)"
    @test sprint(show, InitialCapacity([(2010, "a", 1, 20), (2011, "b", 1, 20)])) == "Initial capacity with 2 entries in 2 year(s)"
end
