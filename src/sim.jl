using OrderedCollections: OrderedDict
using Memoize

using Nosy: Sim, exptype

using JuMP
using Gurobi, HiGHS

# @memoize gurobienv() = Gurobi.Env()
# makesim() = Sim(Model(() -> Gurobi.Optimizer(gurobienv())))

"""
    PathSim(opt; optimizer=HiGHS.Optimizer, model=nothing, simkwargs...)

Shared simulation state for a `Path`.

`PathSim` owns one JuMP model and one Nosy `Sim` per snapshot year. Each `Sim`
uses the `TimeMesh` configured for its year in `opt`.
"""
struct PathSim
    model::JuMP.AbstractModel
    dsim::OrderedDict{Int64,Sim}
    opt::PathOpt
    type::Type
    simkwargs::Dict{Symbol,Any}
end

function PathSim(opt::PathOpt; optimizer=HiGHS.Optimizer, model=nothing, simkwargs...)
    # m = Model(() -> Gurobi.Optimizer(gurobienv()))
    m = isnothing(model) ? Model(optimizer) : model
    kwargs = Dict{Symbol,Any}(pairs(simkwargs))
    sample = Sim(m, mesh=opt.defaultmesh; kwargs...)
    s = OrderedDict{Int64,Sim}((y => Sim(m, mesh=mesh(opt, y), suffix=string(y); kwargs...) for y in years(opt))...)
    return PathSim(m, s, opt, exptype(sample), kwargs)
end
