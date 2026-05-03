#include("include.jl")

@START_OF_DEBUG_CATEGORY "pattern"

struct WeightedPerm
	perm::Permutation
	weight::UInt64 #steps away from generators (atoms)
end

function add_obs(Φ, sequence::Vector, result)::Nothing
	if result ∈ keys(Φ)
		push!(Φ[result], sequence)
	else
		Φ[result] = Set([sequence])
	end
	nothing
end

@END_OF_DEBUG_CATEGORY
