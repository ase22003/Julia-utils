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
input(prompt::String)::String = begin
	print(prompt)
	readline()
end
input()::String = readline()
#}}}
#{{{∃
for type ∈ SET_TYPES
	eval(quote
			function ∃(cond::Function, S::$type)
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
	eval(:(∀(cond::Function, S::$type) = !∃(!cond, S)))
end

macro ∀(elem, cond, S)
	return :(!(@∃ $elem !($cond) $S))
end
#}}}
