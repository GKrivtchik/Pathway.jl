using Nosy: AbstractElement, Snapshot

# snapshot with some metadata
"""
    MetaSnapshot(year, snap)

A Nosy `Snapshot` tagged with its pathway year.
"""
struct MetaSnapshot{T} <: AbstractElement{T}
    year::Int64
    snap::Snapshot{T}
end