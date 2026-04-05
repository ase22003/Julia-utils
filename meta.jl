include("debug.jl")
include("utils.jl")

Token = SubString{String}
Tokens = Vector{Token}
Index = UInt64

macro token()
	:(tokens[end]) → esc
end
macro tokenis(token)
	:(==(@token, $token)) → esc
end
macro next()
	:(pop!(tokens)) → esc
end

tokenize(str::String)::Tokens = filter!(x -> x != "", split(str, ' ')) → reverse

@logged function call_expr(tokens#=::Tokens=#)#::Expr
	if length(tokens) == 0
		error("there are no tokens to parse")
	end
	if @tokenis "("
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
		elseif @tokenis ")"
			break
		elseif @tokenis "("
			push!(args, call_expr(tokens))
		else
			@log @token
			push!(args, (x -> (
					try
						return parse(Int64, x)
					catch
						return Symbol(x)
					end
				))(@token)
			)
		end
	end

	return Expr(:call, name, args...)
end

macro execute_string(s::Expr)
	(tokenize(eval(s)) → call_expr) → esc
end

# TODO:
# - make a better tokenizer that can split up expressions like: "(+ 3 4)"
