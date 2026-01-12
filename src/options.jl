using OrderedCollections: LittleDict
using ArgCheck

struct PathOpt
    years::Vector{Int64} # sorted at construction
    discountrate::Float64
    baseyear::Int64
    mesh::LittleDict{Int64,TimeMesh}
    ini::Dict{String,Float64} # initialized capacity, exempted from cost and construction

    function PathOpt(years, discountrate::Float64, baseyear::Int64, mesh::Union{AbstractDict{Int64,TimeMesh},TimeMesh}, ini::Union{Nothing,Dict{String,Float64}})
        @argcheck !isempty(years) "years cannot be empty"
        years = sort(years) # invariant: years are sorted at constructor
        @argcheck all(isinteger, years) "years must be integers"
        @argcheck 0 <= discountrate <= 0.2 "suspicious discountrate value - expected value around 0.05"
        
        if mesh isa AbstractDict
            @argcheck all(haskey(mesh, y) for y in years) "mesh must have entries for all years"
            mesh = LittleDict(y => mesh[y] for y in years) # adapt to correct format
        elseif mesh isa TimeMesh
            mesh = LittleDict(y => mesh for y in years)
        end

        if isnothing(ini)
            ini = Dict{String,Float64}() # initialization of capacity to empty Dict
        end

        new(years, discountrate, baseyear, mesh, ini)
    end
end

years(o::PathOpt) = o.years

function mesh(o::PathOpt, y::Int64)
    @argcheck haskey(o.mesh, y) "mesh not defined for year $y"
    return o.mesh[y]
end