"""
Dynamic retiring constraints.
"""

using Nosy: getcomponent, hasbehavior, uniquebehavior

function add_dynamic_constraint_lifetime!(p::Path)
    for cname in alltech(p; cwith=[:capacity], cwithout=Symbol[], nwith=Symbol[], nwithout=Symbol[])
        add_dynamic_constraint_lifetime!(p, String(cname))
    end
end

function add_dynamic_constraint_lifetime!(p::Path{T}, cname::String) where T   
    for y in snapshotyears(p)
        # sum until now of capacity (initialized + deployed)

        local dep = zero(T)
        # initialization
        for (_y, v) in p.opt.ini.capacities
            for ini in v
                if ini.cname == cname && _y + ini.lifetime <= y
                    dep += ini.capacity
                end
            end
        end

        for _y in snapshotyears(p)
            if _y < y
                c = getcomponent(getsnapshot(p, _y), cname)
                if hasbehavior(c, LifetimeBehavior{T})
                    _l = Nosy.uniquebehavior(c, LifetimeBehavior{T})
                    if _y + _lifetime(_l) <= y
                        dep += deployment(p, cname, _y) # can be zero if no deployment
                    end

                end
            end
        end

        # constraint: sum of retirement until y is superior or equal to sum of [capacity deployed until now for which y is after lifetime]
        if !iszero(dep)
            # retired until y
            ret = sum(retirement(p, cname, _y) for _y in snapshotyears(p) if _y <= y)
            @constraint(p.sim.model,
                ret >= dep
            )
        end

    end
end