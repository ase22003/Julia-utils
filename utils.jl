#needs "debug.jl"

@START_OF_DEBUG_CATEGORY "utils"

#{{{TYPES
SET_TYPES = [
	Set,
	Dict,
	Tuple,
	Vector,
	UnitRange,
	String,
	Matrix,
	AbstractRange,
	AbstractUnitRange,
	AbstractString,
	AbstractVector,
	AbstractSet,
	AbstractMatrix,
	AbstractDict,
	AbstractVecOrMat
]
#}}}
#{{{alias
→ = |>
#}}}
#{{{UI
@logged function input(prompt::String = "")::String
	print(prompt)
	return readline()
end
#}}}
#{{{∃
for type ∈ SET_TYPES
	eval(quote
			@logged function ∃(cond::Function, S::$type)::Bool
				for e ∈ S
					cond(e) && return true
				end
				return false
			end
		end)
end

macro ∃(elem, cond, S)
	return :((x -> (for $elem in x; $cond && return true; end; return false;))($S))
end
#}}}
#{{{∀
for type ∈ SET_TYPES
	eval(:(@logged function ∀(cond::Function, S::$type); return !∃(!cond, S); end))
end

@logged macro ∀(elem, cond, S)
	return :(!(@∃ $elem !($cond) $S))
end
#}}}
#{{{○
function ○(f::Function, n::Int)::Function
	∘([f for i in 1:n]...)
end
#}}}
#{{{strings
#+(a::String, b::String)::String = string(a, b)
#+=
macro strcat(a, b)
	:(string($a, $b))
end
macro strapp(a, b)
	:($a = string($a, $b))
end
#}}}
#{{{minus
Base.:-(α::Tuple, β::Tuple)::Vector = collect(α) - collect(β)
#}}}
#{{{modified vector copies
@logged function mcopy(vect::Vector, indicies::Vector{<:Int}, modifier::Function)::Vector
	mvect = copy(vect)
	return [
		mvect[i] = modifier(mvect[i])
		for i in indicies
	]
end

@logged function mcopy(vect::Vector, index::Int, modifier::Function)::Vector
	mvect = copy(vect)
	mvect[index] = modifier(mvect[index])
	return mvect
end
#}}}

@END_OF_DEBUG_CATEGORY
