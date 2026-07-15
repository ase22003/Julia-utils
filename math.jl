@START_OF_DEBUG_CATEGORY "math"

@logged function jacobian(f::Function, x::Vector{Float64}, δ::Float64=sqrt(eps(Float64)))::Matrix{Float64}
	fx = f(x)
	return [
		(f(mcopy(x, i, x->x+δ)) - fx) / δ
		for i ∈ 1:length(x)
	] → v->reduce(hcat, v)
end

#e(f::Function, x::Vector{Float64}, target::Vector{Float64})::Vector{Float64} = target - f(x)
@logged function error_vector(f::Function, x::Vector{Float64}, target::Vector{Float64})::Vector{Float64}
	return f(x) - target
end

@logged function levenberg_marquardt_step(f::Function, x::Vector{Float64}, λ::Float64=1e-3)::Vector{Float64}
	r = f(x)
	J = jacobian(f, x)
	A = J'*J + λ*I
	b = -J'*r
	Δx = A \ b
	return x + Δx
end

@logged function optimize(f::Function, params::Vector{Float64}, aggression::Float64=0.1, δ::Float64=0.01, good_enough::Float64=0.0, max_time::Float64=1.0)::Vector{Float64}
	@log "START"
	start_time = time()

	N = length(params)
	#1:N = 1:N

	aggressions = homo_vector(aggression, N)

	calc_der(params::Vector{Float64}, val::Float64)::Vector{Float64} = [
		(f(mcopy(params, i, x->x+δ)) - val) / (2δ)
		for i ∈ 1:N
	]

	prev_params = params
	@log params
	val = prev_val = f(params)
	@log val
	derivatives = prev_der = calc_der(params, val)
	@log derivatives

	skip = false
	while val > good_enough && ∃(x->abs(x)>0, derivatives)
		@log "LOOP"

		if !skip
			aggressions = [
				sign(derivatives[i]) != sign(prev_der[i]) ? aggression/2 : aggression
				for i ∈ 1:N
			]
			@log aggressions
		end
		skip = false

		prev_params = params
		params = [
			params[i] - aggressions[i]*derivatives[i]
			for i ∈ 1:N
		]
		@log params

		prev_val = val
		val = f(params)
		@log val

		if prev_val < val
			params = prev_params
			aggressions = aggressions .→ x->x/2
			@log aggressions
			skip = true
			@log "REVERSE"
			continue
		end


		prev_der = derivatives
		@log prev_der
		derivatives = calc_der(par		if time() - start_time >= max_time
			@log  "time limit reached"
			@warn "time limit reached"
			break
		end
ams, val)
		@log derivatives

		if time() - start_time >= max_time
			@log  "time limit reached"
			@warn "time limit reached"
			break
		end
	end

	return val < prev_val ? params : prev_params
end

@END_OF_DEBUG_CATEGORY

