using EnergyPathway
using Test

using HiGHS
using JuMP: is_solved_and_feasible, objective_value, set_silent, solver_name, value
using Nosy: nsteps

@testset verbose=true "EnergyPathway" begin

    include("tools.jl")

    include("options/_includes.jl")
    include("path/_includes.jl")
    include("behaviors/_includes.jl")
    include("metrics/_includes.jl")
    include("optimization/_includes.jl")

end
