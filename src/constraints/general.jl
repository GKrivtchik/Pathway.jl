"""
All dynamic constraints for Pathway simulations.
"""

function apply_dynamic_constraints!(p::Path)
    add_dynamic_constraint_capacity!(p)

    add_dynamic_constraint_lifetime!(p) # to be implemented
end