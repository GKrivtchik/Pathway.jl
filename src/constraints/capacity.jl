"""
Path capacity constraints.
"""

function add_dynamic_constraint_capacity!(p::Path)
    for cname in alltech(p; cwith=[:capacity], cwithout=Symbol[], nwith=Symbol[], nwithout=Symbol[])
        add_dynamic_constraint_capacity!(p, String(cname))
    end
end

struct Capacity{T}
    cap::OrderedDict{Int64,T} # capacity per year
    dep::OrderedDict{Int64,T} # deployed capacity
    ret::OrderedDict{Int64,T} # retired capacity
end


function _makecapacity(p::Path, cname::String)
    cap = OrderedDict(y => capacity(p, cname, y) for y in snapshotyears(p))
    dep = OrderedDict(y => deployment(p, cname, y) for y in snapshotyears(p))
    ret = OrderedDict(y => retirement(p, cname, y) for y in snapshotyears(p))
    return Capacity(cap, dep, ret)
end

# cap holds values for 1 cname
function add_dynamic_constraint_capacity!(p::Path, cname::String)
    cap = _makecapacity(p, cname)
    for y in snapshotyears(p)
        @constraint(
            p.sim.model,
            cap.cap[y] == cap.dep[y] - cap.ret[y] + _previouscapacity(p, cname, y)
        )
    end
end

_previouscapacity(p::Path, cname::String, y::Int64) = capacity(p, cname, y-1) # y-1 may fall back to either initialization or previous snapshot