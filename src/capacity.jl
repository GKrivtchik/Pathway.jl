"""
Time-dependent tracking of capacity.
"""

using JuMP

# Dict of year => (Dict of tech name => capacity)
struct Capacity{T}
    ini::Dict{String,Float64}
    cur::LittleDict{Int64, Dict{String,T}}
    dep::LittleDict{Int64, Dict{String,T}}
    ret::LittleDict{Int64, Dict{String,T}}
end

# return a capacity dict for a snapshot
# filter with tags for both nodes and components that will be integrated into the capacity dict
# this is necessary to remove components that are not supposed to be tracked (e.g. foreign)
function _getcapacities(s::Snapshot{T}; cwith=Symbol[], cwithout=Symbol[], nwith=Symbol[], nwithout=Symbol[]) where T
    d = Dict{String,T}()
    for (kn,_) in getnodes(s, with=nwith, without=nwithout)
        for (k,v) in getcomponents(s, kn, with=cwith, without=cwithout)
            if !haskey(d, k) # avoid duplicates in case of component connected to multiple nodes
                c = capacity(v) # TODO check efficiency
                if !isnothing(c)
                    d[k] = c
                end
            end
        end
    end
    return d
end

# this method must only be called once
# otherwise deployment / retirement variables are duplicated
function Capacity(p::Path{T}) where T
    # initialization of capacity, from options
    ini = copy(p.opt.ini) # copy to protect from potential modifications of ini

    # Dict of all present capacities
    # in this context, "present" means: present as a variable (possibly equal to zero)
    cur = LittleDict{Int64, Dict{String,T}}()
    for (y,msnap) in p
        cur[y] = _getcapacities(msnap.snap)
    end

    # all capacities can be deployed if they are present
    # capacities that are not present cannot be deployed
    # so the deployment dict mirrors the current dict
    dep = LittleDict{Int64, Dict{String,T}}()
    for (y, d) in cur
        dep[y] = Dict{String, T}()
        for (cname, _) in d
            dep[y][cname] = Nosy._to_affexpr(@variable(p.sim.model, base_name="deploy_$(cname)_$(y)", lower_bound=0.0), p.sim.model) # TODO: add upper bound
        end
    end

    # all capacities can be retired if they are present
    # capacities that are not present anymore, but were present before, can be retired
    ret = LittleDict{Int64, Dict{String,T}}()
    stech = Set(ini) # initialized from ini, iteratively built, as years are iterated chronologically in the (always sorted) LittleDict
    for (y, d) in cur
        ret[y] = Dict{String, T}()
        
        # increment set of technologies so far, including technologies not present in current year
        for (cname, _) in d
            push!(stech, cname)
        end
        
        # add retirement variables for all technologies seen so far
        for cname in stech
            ret[y][cname] = Nosy._to_affexpr(@variable(p.sim.model, base_name="retire_$(cname)_$(y)", lower_bound=0.0), p.sim.model) # TODO: add upper bound
        end
    end

    return Capacity{T}(ini, cur, dep, ret)
end

_previousyear(c::Capacity, y::Int) = maximum(filter(yy -> yy < y, keys(c.d))) where T # if no previous year: return nothing

# return initialization value (capacity before sim starts). If not present, ini is zero
function _inicap(c::Capacity{T}, cname::String) where T
    if haskey(c.ini, cname)
        return c.ini[cname]
    else
        return zero(T)
    end
end

# variables
# * new capacity as variable > 0
# * retirement as variable > 0
# functions
# * new capacity as expression of current + old capacity
# * retirement as expression
# constraints
# * current = old + new - retired

# return difference between current capacity and previous capacity
function deltacap(c::Capacity{T}, cname::String, y::Int64) where T
    @assert haskey(c.d, y) "Year $y not found in capacity data"
    
    # current capacity
    # if component is not present: current capacity is zero
    # otherwise: dict lookup
    if haskey(c.d[y], cname)
        cc = c.d[y][cname]
    else 
        cc = zero(T)
    end

    # previous capacity
    py = _previousyear(c, y)
    if isnothing(py)
        pc = _inicap(c, cname) # if no previous year: old capacity is set to ini
    else
        if haskey(c.d[py], cname)
            pc = c.d[py][cname]
        else 
            pc = zero(T)
        end
    end
    
    return cc - pc

end