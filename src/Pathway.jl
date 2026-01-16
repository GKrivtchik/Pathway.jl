module Pathway

"""
Path model, based on Nosy.jl
"""

include("options/_includes.jl")
include("sim.jl")
include("snapshot.jl")

# include("capacity.jl")

include("path.jl")

include("behaviors/_includes.jl")

include("metrics/_includes.jl")
include("constraints/_includes.jl")

include("optimization/_includes.jl")

include("example.jl")

end # module Pathway
