"""
Pathway-style cost metrics.

Costs are initially defined in Nosy for snapshots. However, some costs (investment) must be reimplemented.
Time-dependency must be added to all cost metrics.
"""

import Nosy: variablecost

function singlecost(p::Path, cname::String, year::Int, type::Union{Nothing,Symbol}=nothing) # Pathway only
    _singlecost(p, cname, year, type)
end

function variablecost(p::Path{T}, cname::String, year::Int, type::Union{Nothing, Symbol}=nothing) where T # based on Nosy
    # variable costs are assumed to be zero before the next snapshot
    if year < firstsnapshotyear(p)
        return zero(T)
    end

    # get the Nosy variable cost, then discount it against baseyear
    snap = getsnapshot(p, snapshotyear(p, year))
    disc = discount(p.opt, year - p.opt.baseyear)
    if isnothing(type)
        c = Nosy.variablecost(snap, cname)
    else
        c = Nosy.variablecost(snap, cname, type)
    end
    return c * disc
end