#{{{AI GENERATED CODE
"""
    value_to_expr(x) -> Expr

Konverterar ett Julia-värde till ett Expr som representerar värdet.
Hanterar cykler, immutables, mutables, arrays, tuples och dictionaries.
"""
function value_to_expr(x)
    seen = IdDict()
    return _value_to_expr(x, seen)
end

function _value_to_expr(x, seen)
    # Primitiva typer
    if x === nothing || x isa Number || x isa String || x isa Symbol || x isa Bool
        return x
    end

    # Cykelkontroll
    if haskey(seen, x)
        return Expr(:ref, seen[x])
    end

    # Tupler
    if x isa Tuple
        args = [_value_to_expr(a, seen) for a in x]
        return Expr(:tuple, args...)
    end

    # Arrays
    if x isa AbstractArray
        id = gensym(:arr)
        seen[x] = id
        elements = [_value_to_expr(e, seen) for e in x]
        return Expr(:call, :vcat, elements...)
    end

    # Dictionaries
    if x isa AbstractDict
        id = gensym(:dict)
        seen[x] = id
        pairs_expr = [Expr(:call, :(=>),
                           _value_to_expr(k, seen),
                           _value_to_expr(v, seen)) for (k, v) in x]
        return Expr(:call, :Dict, pairs_expr...)
    end

    # Strukturer (mutable + immutable)
    T = typeof(x)
    id = gensym(Symbol(nameof(T)))
    seen[x] = id

    fields = fieldnames(T)
    args = [_value_to_expr(getfield(x, f), seen) for f in fields]

    return Expr(:call, T, args...)
end
#}}}

@logged function expr_to_meta_syntax(expr)::String
	if typeof(expr) == LineNumberNode
		@log "LineNumberNode"
		return ""
	end
	if typeof(expr) != Expr
		@log "value"
		return "$expr "
	end
	if expr.head == :(=)
		@log "assignment"
		return "assign $((expr.args .→ to_meta_syntax)...)"
	end
	if expr.head == :block
		@log "block"
		return "\nbegin\n$(((expr.args .→ to_meta_syntax) .→ x->string(x, '\n'))...)\nend\n"
	end
	if expr.head == :function
		@log "function"
		return "function $(expr.args[1] → to_meta_syntax) $((expr.args[2:end] .→ to_meta_syntax)...)"
	end
	if expr.head ∈ (:return, :for, :while)
		@log "other"
		return "$(expr.head) $((expr.args .→ to_meta_syntax)...)"
	end
	@log "call"
	return "( $((expr.args .→ to_meta_syntax)...)) "
end
