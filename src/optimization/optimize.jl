"""
Path optimization.
"""

using JuMP: set_objective

import JuMP: optimize!

function optimize!(p::Path{T}, obj::T) where T
    
    finalize!(p)
    
    set_objective(p.sim.model, MIN_SENSE, obj)
    optimize!(p.sim.model)
end