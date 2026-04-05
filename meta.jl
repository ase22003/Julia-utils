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

@logged function call_expr(tokens#=::Tokens=#, EXPR_BEGIN#=::String=#, EXPR_END#=::String=#)#::Expr
	if length(tokens) == 0
		error("there are no tokens to parse")
	end
	#if !@tokenis BEGIN
	#	error("expression must begin with '(' -- cannot begin with '", @token, '\'')
	#end
	if ==(@token, EXPR_BEGIN)
		@next
	end
	name = @token
	args::Vector{Union{Symbol, Int64, Float16, String, Char, Expr}} = []
	@log @token
	@log "arguments:"
	while true
		@next
		if length(tokens) == 0
			break
		elseif ==(@token, EXPR_END)
			break
		elseif ==(@token, EXPR_BEGIN)
			push!(args, call_expr(tokens, EXPR_BEGIN, EXPR_END))
		else
			@log @token
			push!(args, call_value(tokens))
		end
	end

	return Expr(:call, Symbol(name), args...)
end
function call_expr(tokens::Tokens)
	call_expr(tokens, "(", ")")
end

@logged function call_value(tokens)
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
