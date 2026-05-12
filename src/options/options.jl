using OrderedCollections: OrderedDict
using ArgCheck: @argcheck

using Nosy: TimeMesh

using Infiltrator

function _sort_ordered_dict!(d::OrderedDict)
    entries = sort(collect(d); by=first)
    empty!(d)
    for (k, v) in entries
        d[k] = v
    end
    return d
end

"""
    PathOpt(years; discountrate=0.05, baseyear=first(years), endyear=last(years), mesh=TimeMesh(), ini=[])
    PathOpt(years, discountrate, baseyear, endyear, mesh; ini=[])

Temporal options for a Pathway model.

`years` are the snapshot years. `mesh` can be one `TimeMesh` shared by all
snapshots or a dictionary mapping each snapshot year to a `TimeMesh`. `ini`
describes historical capacity installed before the first snapshot year.
"""
mutable struct PathOpt
    years::Vector{Int64} # sorted at construction
    discountrate::Float64
    baseyear::Int64
    endyear::Int64
    mesh::OrderedDict{Int64,TimeMesh}
    ini::InitialCapacity # initialized capacity, exempted from cost and construction
    defaultmesh::TimeMesh
    _baseyear_auto::Bool
    _endyear_auto::Bool

    function PathOpt(years, discountrate::Number, baseyear::Int, endyear::Int, mesh::Union{AbstractDict{Int64,TimeMesh},TimeMesh}; ini=[], baseyear_auto::Bool=false, endyear_auto::Bool=false)
        years = sort(years) # invariant: years are sorted at constructor
        @argcheck all(isinteger, years) "years must be integers"
        @argcheck allunique(years) "years must be unique"
        @argcheck 0 <= discountrate <= 0.2 "suspicious discountrate value - expected value around 0.05"
        @argcheck baseyear <= endyear "baseyear must be before or equal to endyear"
        isempty(years) || @argcheck last(years) <= endyear "endyear must be after or equal to the last snapshot year"
        
        if mesh isa AbstractDict
            isempty(years) || @argcheck all(haskey(mesh, y) for y in years) "mesh must have entries for all years"
            @argcheck !isempty(mesh) "mesh dictionary cannot be empty"
            defaultmesh = first(values(mesh))
            mesh = OrderedDict(y => mesh[y] for y in years) # adapt to correct format
        elseif mesh isa TimeMesh
            defaultmesh = mesh
            mesh = OrderedDict(y => mesh for y in years)
        end

        re_ini = InitialCapacity(ini)
        isempty(years) || _check_initial_capacity(re_ini, first(years))

        new(Int64.(years), Float64(discountrate), Int64(baseyear), Int64(endyear), mesh, re_ini, defaultmesh, baseyear_auto, endyear_auto)
    end
end

function PathOpt(
    years=Int64[];
    discountrate::Number=0.05,
    baseyear::Union{Nothing,Int}=nothing,
    endyear::Union{Nothing,Int}=nothing,
    mesh::Union{AbstractDict{Int64,TimeMesh},TimeMesh}=TimeMesh(),
    ini=[],
)
    years_vector = collect(years)
    sorted_years = sort(Int64.(years_vector))
    by = isnothing(baseyear) ? (isempty(sorted_years) ? 0 : first(sorted_years)) : baseyear
    ey = isnothing(endyear) ? (isempty(sorted_years) ? by : last(sorted_years)) : endyear
    return PathOpt(
        sorted_years,
        discountrate,
        by,
        ey,
        mesh;
        ini=ini,
        baseyear_auto=isnothing(baseyear),
        endyear_auto=isnothing(endyear),
    )
end

function _check_initial_capacity(ini::InitialCapacity, firstyear::Int)
    @argcheck all(y < firstyear for y in keys(ini.capacities)) "initial capacities can only be defined before the first snapshot year"
    for (y, v) in ini.capacities
        for tech in v
            @argcheck tech.lifetime + y >= firstyear "initialized capacity for component $(tech.cname) in year $y has expired before first snapshot year $firstyear"
        end
    end
end

function _addyear!(o::PathOpt, y::Int, m::TimeMesh)
    y = Int64(y)
    @argcheck !(y in o.years) "snapshot year $y already exists"

    push!(o.years, y)
    sort!(o.years)
    o.mesh[y] = m
    _sort_ordered_dict!(o.mesh)

    firsty = first(o.years)
    lasty = last(o.years)
    _check_initial_capacity(o.ini, firsty)
    if o._baseyear_auto
        o.baseyear = firsty
    end
    if o._endyear_auto
        o.endyear = lasty
    else
        @argcheck lasty <= o.endyear "endyear must be after or equal to the last snapshot year"
    end

    return y
end

"""
    years(opt::PathOpt)

Return the sorted snapshot years configured in `opt`.
"""
years(o::PathOpt) = o.years

"""
    mesh(opt::PathOpt, year)

Return the `TimeMesh` associated with snapshot `year`.
"""
function mesh(o::PathOpt, y::Int64)
    @argcheck haskey(o.mesh, y) "mesh not defined for year $y"
    return o.mesh[y]
end
