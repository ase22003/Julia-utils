@START_OF_DEBUG_CATEGORY "math"

using LinearAlgebra

@logged function jacobian(f::Function, x::Vector{Float64}, δ::Float64=sqrt(eps(Float64)))::Tuple{Matrix{Float64}, Vector{Float64}}
	fx = f(x)
	return (
		[
			(f(mcopy(x, i, x->x+δ)) - fx) / δ
			for i ∈ 1:length(x)
		] → v->reduce(hcat, v),
		fx
	)
end

#e(f::Function, x::Vector{Float64}, target::Vector{Float64})::Vector{Float64} = target - f(x)
function error_vector(f::Function, x::Vector{Float64}, target::Vector{Float64})::Vector{Float64}
	return f(x) - target
end

@logged function basic_cost(error_vect::Vector{Float64})::Float64
	return sum(abs2, error_vect)
end

@logged function levenberg_marquardt_step(f::Function, x::Vector{Float64}, λ::Float64=1e-3)::Vector{Float64}
	J, r = jacobian(f, x)
	A = Symmetric(J' * J)
	A += λ * I
	b = -J'*r
	Δx = A \ b
	return x + Δx
end

@logged function levenberg_marquardt(error_fun::Function, x::Vector{Float64}, goal::Real, max_time::Real=Inf, cost_fun::Function=basic_cost, λ::Float64=1e-3)::Vector{Float64}
	cost = x->cost_fun(error_fun(x))
	start_time = time()
	val = cost(x)
	while true
		if val <= goal
			break
		end

		if time() - start_time >= max_time
			@log  "reached time limit before satisfying goal"
			@warn "reached time limit before satisfying goal"
			break
		end

		new_x = levenberg_marquardt_step(error_fun, x, λ)
		new_val = cost(new_x)
		@log x
		@log new_x
		@log val
		@log new_val
		@log new_val < val
		if new_val < val
			@log "NEW BEST"
			x = new_x
			val = new_val
			λ /= 2
		else
			λ *= 2
		end
		λ = clamp(λ, 1e-12, 1e12)

		@log λ
	end
	return x
end

@END_OF_DEBUG_CATEGORY

