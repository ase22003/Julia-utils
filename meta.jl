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
	#:(tokens[end] == $token) → esc
end
macro next()
	:(pop!(tokens)) → esc
end

tokenize(str::String)::Tokens = filter!(x -> x != "", split(str, ' ')) → reverse

#{{{old
#call_expr(str::String)::Expr = Expr(:call, [(s -> *((Tuple(s) .→ isnumeric)...) ? parse(Int, s) : Symbol(s))(token) for token ∈ tokenize(str)]...)
#call_expr(str::String)::Expr = Expr(:call, ((s -> *((Tuple(s) .→ isnumeric)...) ? parse(Int, s) : Symbol(s)).(tokenize(str)))...)

#=
@logged function scall(tokens::Tokens, token_index::Index)::Expr
	@token != "(" && error("call must begin with '('")
	@next
	name = Symbol(@token)
	args::Vector{Union{Symbol, Expr}} = []
	while true
		@next
		token_index = length(tokens) && break
		@token == ")" && break
		@token == "(" && push!(args, scall(tokens, token_index))
		push!(args, *((Tuple(@token) .→ isnumeric)...) ? parse(Int, @token) : Symbol(@token))
	end
	return Expr(:call, name, args...)
end
=#
#}}}

#function scall(tokens::Tokens)::Expr
@logged function call_expr(tokens#=::Tokens=#)#::Expr
	if length(tokens) == 0
		error("there are no tokens to parse")
	end
	#if !@tokenis "("
	#	error("expression must begin with '(' -- cannot begin with '", @token, '\'')
	#end
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
			#push!(args, *((Tuple(@token) .→ x->isnumeric(x) || x == '-')...) ? parse(Int64, @token) : Symbol(@token))
			#push!(args, ∀(x->isnumeric(x) || x == '-', Tuple(@token)) ? parse(Int64, @token) : Symbol(@token))
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

macro execute_string(s::Expr)
	(tokenize(eval(s)) → call_expr) → esc
end

# TODO:
# - make a better tokenizer that can split up expressions like: "(+ 3 4)"
