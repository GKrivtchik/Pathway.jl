function add_dispatch_system!(snap, demand; late=false)
    s = snap.sim
    carrier = EnergyCarrier(late ? "late_power" : "power", s)
    grid = Node(late ? "late_grid" : "grid", carrier)

    if !late
        load = Component("load", Demand(carrier, demand))
        connect!(snap, load, grid)
    end

    gen = Component(
        late ? "late_gen" : "gen",
        DispatchableSource(carrier),
        [
            VariableCapacity("output", energy),
            VariableDeployment("output", energy),
            VariableRetirement("output", energy),
            Lifetime(30),
            SingleCost(:capex, :deployment, "output", energy, 1.0, nothing),
        ],
    )
    connect!(snap, gen, grid)

    return snap
end

function add_fixed_dispatch_system!(snap, cname, demand, capacity_value; deployment_value=capacity_value, retirement_value=0.0, lifetime_years=10)
    carrier = EnergyCarrier("$(cname)_power", snap.sim)
    grid = Node("$(cname)_grid", carrier)
    load = Component("$(cname)_load", Demand(carrier, demand))
    gen = Component(
        cname,
        DispatchableSource(carrier),
        [
            FixedCapacity("output", energy, capacity_value),
            FixedDeployment("output", energy, deployment_value),
            FixedRetirement("output", energy, retirement_value),
            Lifetime(lifetime_years),
            SingleCost(:capex, :deployment, "output", energy, 4.0, Dict(-1 => 0.25, 0 => 0.75)),
        ],
    )
    connect!(snap, load, grid)
    connect!(snap, gen, grid)
    return gen
end

function optimized_dispatch_path(; endyear=2030)
    mesh2 = TimeMesh(fill(1 // 1, 2))
    opt = PathOpt(2020:10:2030; discountrate=0.05, endyear=endyear, mesh=mesh2)
    path = Path(HiGHS.Optimizer, opt)
    set_silent(model(path))
    add_dispatch_system!(path[2020], 10)
    add_dispatch_system!(path[2030], 20)
    add_dispatch_system!(path[2030], 0; late=true)
    optimize!(path, cost(path))
    return path
end
