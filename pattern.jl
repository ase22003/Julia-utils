@START_OF_DEBUG_CATEGORY "pattern"

#=
struct WeightedPerm
	perm::Permutation
	weight::UInt64 #steps away from generators (atoms)
end
=#

PermWeights = Dict{Any, UInt64}

PermΦ = Dict{Permutation, Any}

@logged function add_obs(Φ::PermΦ, generators::Vector{Permutation}, sequence::Vector{Permutation}, result::Permutation)::Nothing
	if result ∈  generators
		return nothing
	end
	if result ∈ keys(Φ)
		push!(Φ[result], sequence)
	else
		Φ[result] = Set([sequence])
	end
	return nothing
end

@logged function explore(Φ::PermΦ, generators::Vector{Permutation}, weights::PermWeights, seq::Vector{Permutation})::Nothing
	prod = compose_perms(seq)
	@log prod

	weight::UInt64 = 0
	for perm ∈ seq
		if perm ∈ keys(weights)
			weight += weights[perm]
		end
	end

	@log weight
	if prod ∈ keys(weights)
		weights[prod] = min(weight, weights[prod])
	else
		weights[prod] = weight
	end

	add_obs(Φ, generators, seq, prod)
	return nothing
end

@logged function register_generators(Φ::PermΦ, weights::PermWeights, generators::Vector{Permutation}, names::Vector{String} = (65:90 .→ Char ) .→ string)::Nothing
	for (i, perm) ∈ enumerate(generators)
		weights[perm] = UInt64(1)
		weights[names[i]] = UInt64(1)
		Φ[perm] = names[i]
	end
	return nothing
end

@logged function choose_seq(seqs::Any, weights::PermWeights, generators::Vector{Permutation})::Vector{Any}
	if typeof(seqs) != Set{Vector{Permutation}}
		return [seqs]
	end
	s = collect(seqs)
	return s[findmin(x->sum([weights[perm] for perm ∈ x]), s)[2]]
end

#TESTING
G = PermΦ()
w = PermWeights()

generators = [[[1,2]], [[2,3]]]
register_generators(G, w, generators)

for i in 1:20; explore(G, generators, w, [rand(keys(G)), rand(keys(G))]); display(G); display(w); end

ϟ(G, ([[1,2,3]],), x->choose_seq(x,w,generators))

@END_OF_DEBUG_CATEGORY
