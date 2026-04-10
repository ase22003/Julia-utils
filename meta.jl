include("debug.jl")
include("utils.jl")

Token = SubString{String}
Tokens = Vector{Token}
Index = UInt64
Evaluable = Union{Expr, Symbol}
Value = Union{Symbol, Int64, Float16, String, Char, Expr}

macro token()
	quote
		(x -> begin
				if length(tokens) == 0
					error("ran out of tokens")
				end
				return tokens[end]
			end
		)(nothing)
	end → esc
end
macro next()
	:(pop!(tokens)) → esc
end

tokenize(str::String)::Tokens = filter!(x -> x != "", split(str, ' ')) → reverse

@logged function call_block(tokens::Tokens, BLOCK_BEGIN::String, BLOCK_END::String)::Expr
	if length(tokens) == 0
		return :(nothing)
	end
	if ==(@token, BLOCK_BEGIN)
		@next
	end
	statements::Vector{Expr} = []
	while true
		@log statements
		@log tokens
		if length(tokens) == 0
			break
		elseif ==(@token, BLOCK_BEGIN)
			push!(statements, call_block(tokens, BLOCK_BEGIN, BLOCK_END))
		elseif ==(@token, BLOCK_END)
			@next
			break
		elseif ==(@token, "function")
			@log "FUNCTION"
			@next
			sig  = call_expr(tokens)
			code = call_block(tokens)
			push!(statements, Expr(:function, sig, code))
		elseif ==(@token, "return")
			@log "RETURN"
			@next
			push!(statements, Expr(:return, call_expr(tokens))) # ARG!!!!!
		else
			@log "EXPRESSION"
			push!(statements, call_expr(tokens)) # ARG!!!!!
		end
	end
	return Expr(:block, statements...)
end
function call_block(tokens::Tokens)
	call_block(tokens, "begin", "end")
end

@logged function call_expr(tokens::Tokens, EXPR_BEGIN::String, EXPR_END::String)::Expr
	if length(tokens) == 0
		#error("there are no tokens to parse")
		return :(nothing)
	end
	if !=(@token, EXPR_BEGIN)
		error("expression must begin with '(' -- cannot begin with '", @token, '\'')
	end
	@next
	#if ==(@token, EXPR_BEGIN)
	#	@next
	#end
	name = @token
	@log name
	@next
	args::Vector{Value} = []
	while true
		@log @token
		if     ==(@token, EXPR_BEGIN)
			push!(args, call_expr(tokens, EXPR_BEGIN, EXPR_END))
		elseif ==(@token, EXPR_END)
			@next
			break
		else #token is a value
			push!(args, call_value(tokens))
			@next
		end
	end

	return Expr(:call, Symbol(name), args...)
end
function call_expr(tokens::Tokens)
	call_expr(tokens, "(", ")")
end

@logged function call_value(tokens::Tokens)::Value
	try
		r = parse(Int64, @token)
		@log "integer"
		return r
	catch
	end
	try
		r = parse(Float16, @token)
		@log "float"
		return r
	catch
	end
	try
		for d ∈ ('\'', '\"')
			if (@token)[1] == d && (@token)[end] == d
				if d == '\''
					r = (@token)[2]
					@log "character"
					return r
				else
					r = String(split(@token, d)[2])
					@log "string"
					return r
				end
			end
		end
	catch
	end
	@log "symbol"
	return Symbol(@token)
end

macro run_call_string(s::String)
	(tokenize(s) → call_expr) → esc
end
macro run_call_string(s::String, BEGIN::String, END::String)
	call_expr(tokenize(s), BEGIN, END) → esc
end
macro run_call_string(s::Evaluable)
	(tokenize(eval(s)) → call_expr) → esc
	#:(@run_call_string $(eval(s))) ????????????
end
macro run_call_string(s::Evaluable, BEGIN::String, END::String)
	call_expr(tokenize(eval(s)), BEGIN, END) → esc
end


# TODO:
# - make a better tokenizer that can split up expressions like: "(+ 3 4)"
# - loops, assignments, anonymous functions (->) and so on
# - replace func(tokens, "begin", "("...) with a single dictionary of sybols func(tokens, sym_map), where sym_map = {EXPR_BEGIN => "("...}
