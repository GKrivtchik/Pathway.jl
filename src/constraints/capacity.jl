"""
Path capacity constraints.
"""

using Nosy: getcomponents, hascomponent, getcomponent, hasbehavior

# Dynamic capacity constraints should apply only to component names that carry
# EnergyPathway deployment/retirement event behaviors. Fixed-only snapshot components
# remain ordinary Nosy components and are not connected through time.
function _dynamic_capacity_components(p::Path)
    components = Set{String}()
    for y in snapshotyears(p)
        snap = getsnapshot(p, y)
        for (cname, c) in getcomponents(snap)
            if hasbehavior(c, AbstractDeploymentBehavior) || hasbehavior(c, AbstractRetirementBehavior)
                push!(components, String(cname))
            end
        end
    end
    return sort(collect(components))
end

function _has_dynamic_capacity_event(p::Path, cname::String, y::Int)
    snap = getsnapshot(p, y)
    hascomponent(snap, cname) || return false
    c = getcomponent(snap, cname)
    return hasbehavior(c, AbstractDeploymentBehavior) || hasbehavior(c, AbstractRetirementBehavior)
end

function add_dynamic_constraint_capacity!(p::Path)
    for cname in _dynamic_capacity_components(p)
        add_dynamic_constraint_capacity!(p, cname)
    end
end

struct Capacity{T}
    cap::OrderedDict{Int64,T} # capacity per year
    dep::OrderedDict{Int64,T} # deployed capacity
    ret::OrderedDict{Int64,T} # retired capacity
end


function _makecapacity(p::Path{T}, cname::String) where T
    # Fixed first-snapshot capacities are numeric, while later capacities may be
    # JuMP affine expressions. Convert all terms to the path expression type so
    # the three OrderedDicts can share one Capacity{T}.
    cap = OrderedDict{Int64,T}(y => convert(T, capacity(p, cname, y)) for y in snapshotyears(p))
    dep = OrderedDict{Int64,T}(y => convert(T, deployment(p, cname, y)) for y in snapshotyears(p))
    ret = OrderedDict{Int64,T}(y => convert(T, retirement(p, cname, y)) for y in snapshotyears(p))
    return Capacity(cap, dep, ret)
end

# cap holds values for 1 cname
function add_dynamic_constraint_capacity!(p::Path, cname::String)
    cap = _makecapacity(p, cname)
    for y in snapshotyears(p)
        if y == firstsnapshotyear(p) && !_has_dynamic_capacity_event(p, cname, y)
            continue
        end
        @constraint(
            p.sim.model,
            cap.cap[y] == cap.dep[y] - cap.ret[y] + _previouscapacity(p, cname, y)
        )
    end
end

_previouscapacity(p::Path, cname::String, y::Int64) = capacity(p, cname, y-1) # y-1 may fall back to either initialization or previous snapshot
