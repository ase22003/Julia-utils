#needs "debug.jl"

@START_OF_DEBUG_CATEGORY "utils"

#{{{SET_TYPES
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

@END_OF_DEBUG_CATEGORY
