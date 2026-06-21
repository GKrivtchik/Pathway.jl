"""
Path capacity metrics.
"""

using Nosy: addto!, hascomponent

import Nosy: capacity

"""
    capacity(p::Path{T}, cname::String, year::Int) where T
Return a Vector of (capacity, time ratio).
The time ratio means the share of the lifetime of the component present before the end of the path, and is to be used as a multiplier of the investment cost.
"""
function _capacity(p::Path{T}, cname::String, year::Int) where T
    if year < first(years(p.opt))
        # sum over previous initializations
        local val = zero(T)
        for (y, v) in p.opt.ini.capacities
            if y <= year
                for tech in v
                    if tech.cname == cname
                        val = addto!(val, tech.capacity)
                    end
                end
            end
        end
        return val
    elseif year <= lastyear(p)
        snap = getsnapshot(p, snapshotyear(p,year)) # fall back to previous snapshot is not a snapshot year
        # A technology may appear only in later pathway snapshots. In earlier
        # snapshots, absence means zero installed capacity, not a modeling error.
        hascomponent(snap, cname) || return zero(T)
        return Nosy.capacity(snap, cname)
    else #if p > lastyear(p)
        return zero(T)
    end
end

"""
    capacity(path, cname, year)

Return the installed capacity of component `cname` in `year`.

Before the first snapshot year, this is based on historical capacity. Between
snapshot years, EnergyPathway uses the latest previous snapshot. After the model
horizon, capacity is zero.
"""
capacity(p::Path, cname::String, year::Int) = _capacity(p, cname, year) # cleaner signature
