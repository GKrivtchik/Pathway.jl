using Nosy: Snapshot

# snapshot with some metadata
struct MetaSnapshot{T}
    year::Int64
    snap::Snapshot{T}
end