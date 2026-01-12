struct Path{T}
    opt::PathOpt
    sim::PathSim
    snap::LittleDict{Int64,MetaSnapshot{T}}
    function Path(opt::PathOpt, sim::PathSim, snap::AbstractDict{Int64,MetaSnapshot{T}}) where T
        @argcheck years(opt) == sort(collect(keys(snap))) "snapshot years do not match PathOpt years"
        new{T}(opt, sim, sort(snap)) # invariant: years are sorted at constructor
    end
end

function Path(opt::PathOpt)
    psim = PathSim(opt)
    dsnap = LittleDict([y => MetaSnapshot(y,Snapshot(psim.dsim[y])) for y in years(opt)])
    return Path(opt,psim,dsnap)
end

# key-value iteration over Path
Base.iterate(d::Path, st...) = iterate(pairs(d.snap), st...)