include("debug.jl")
include("utils.jl")

Token = SubString{String}
Tokens = Vector{Token}
Index = UInt64
Evaluable = Union{Expr, Symbol}

macro token()
	:(tokens[end]) → esc
end
macro next()
	:(pop!(tokens)) → esc
end

tokenize(str::String)::Tokens = filter!(x -> x != "", split(str, ' ')) → reverse

@logged function call_expr(tokens#=::Tokens=#, BEGIN_STRING#=::String=#, END_STRING#=::String=#)#::Expr
	if length(tokens) == 0
		error("there are no tokens to parse")
	end
	if ==(@token, BEGIN_STRING)
		@next
	end
	name = Symbol(@token)
	args::Vector{Union{Symbol, Int64, Expr}} = []
	@log @token
	@log "arguments:"
	while true
		@next
		if length(tokens) == 0
			break
		elseif ==(@token, END_STRING)
			break
		elseif ==(@token, BEGIN_STRING)
			push!(args, call_expr(tokens, BEGIN_STRING, END_STRING))
		else
			@log @token
			elem = (x -> (
				try
					return parse(Int64, x)
				catch
					return Symbol(x)
				end
			))(@token)
			push!(args, elem)
		end
	end

	return Expr(:call, name, args...)
end
function call_expr(tokens::Tokens)
	call_expr(tokens, "(", ")")
end

macro run_call_string(s::String)
	(tokenize(s) → call_expr) → esc
end
macro run_call_string(s::String, BEGIN::String, END::String)
	call_expr(tokenize(s), BEGIN, END) → esc
end
macro run_call_string(s::Evaluable)
	(tokenize(eval(s)) → call_expr) → esc
end
macro run_call_string(s::Evaluable, BEGIN::String, END::String)
	call_expr(tokenize(eval(s)), BEGIN, END) → esc
end


# TODO:
# - make a better tokenizer that can split up expressions like: "(+ 3 4)"
