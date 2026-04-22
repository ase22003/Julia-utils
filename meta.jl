#needs "utils.jl" "debug.jl"

@START_OF_DEBUG_CATEGORY "meta"

Token = SubString{String}
Tokens = Vector{Token}
Index = UInt64
Evaluable = Union{Expr, Symbol}
Value = Union{Symbol, Int64, Float16, String, Char, Expr}

macro _token()
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
macro _next()
	:(pop!(tokens)) → esc
end

tokenize(str::String, str_filter::Function = x->replace(x, '\n'=>' '))::Tokens = filter!(x->x!="", split(str → str_filter, ' ')) → reverse

@logged function _meta_block(tokens::Tokens)::Expr
	@ignore tokens
	@ignore "begin"
	@ignore "end"
	if length(tokens) == 0
		return :(nothing)
	end
	if ==(@_token, "begin")
		@_next
	end
	statements::Vector{Expr} = []
	while true
		@log statements
		@log tokens
		if length(tokens) == 0
			break
		elseif ==(@_token, "begin")
			push!(statements, _meta_block(tokens))
		elseif ==(@_token, "end")
			@_next
			break
		elseif ==(@_token, "function")
			@log "FUNCTION"
			@_next
			sig   = _meta_expr(tokens)
			block = _meta_block(tokens)
			push!(statements, Expr(:function, sig, block))
		elseif ==(@_token, "return")
			@log "RETURN"
			@_next
			push!(statements, Expr(:return, _meta_expr(tokens)))
		elseif ==(@_token, "assign")
			@log "ASSIGNMENT"
			@_next
			if ==(@_token, "(")
				name = _meta_expr(tokens)
			else
				name = _meta_value(tokens)
				@_next
			end
			if ==(@_token, "(")
				value = _meta_expr(tokens)
			else
				value = _meta_value(tokens)
				@_next
			end
			push!(statements, Expr(:(=), name, value))
		#= problem with scope, UndefVarError
		elseif ==(@_token, "for")
			@log "'FOR' LOOP"
			@_next
			iter  = _meta_expr(tokens)
			block = _meta_block(tokens)
			push!(statements, Expr(:for, iter, block))
		=#
		elseif ==(@_token, "while")
			@log "'WHILE' LOOP"
			@_next
			cond  = _meta_expr(tokens)
			block = _meta_block(tokens)
			push!(statements, Expr(:while, cond, block))
		else
			@log "ASSUMING EXPR"
			push!(statements, _meta_expr(tokens))
		end
	end
	return Expr(:block, statements...)
end

@logged function _meta_expr(tokens::Tokens)::Expr
	@ignore tokens
	if length(tokens) == 0
		#error("there are no tokens to parse")
		return :(nothing)
	end
	if !=(@_token, "(")
		error("expression must begin with '(' -- cannot begin with '$(@_token)'")
	end
	@_next
	args::Vector{Value} = []
	while true
		@log @_token
		if     ==(@_token, "(")
			push!(args, _meta_expr(tokens))
		elseif ==(@_token, ")")
			@_next
			break
		else # token is a value
			push!(args, _meta_value(tokens))
			@_next
		end
	end

	if args[1] ∈ (:..., :->, :(::)) # non-call expressions
		@log "NON-CALL EXPRESSION"
		return Expr(args...)
	elseif args[1] == '@'
		@log "MACRO CALL"
		return Expr(:macrocall, args...)
	else
		return Expr(:call, args...)
	end
end

@logged function _meta_value(tokens::Tokens)::Value
	@ignore tokens
	@log @_token
	try
		r = parse(Int64, @_token)
		@log "integer"
		return r
	catch
	end
	try
		r = parse(Float16, @_token)
		@log "float"
		return r
	catch
	end
	try
		for d ∈ ('\'', '\"')
			if (@_token)[1] == d && (@_token)[end] == d
				if d == '\''
					r = (@_token)[2]
					@log "character"
					return r
				else
					r = String(split(@_token, d)[2])
					@log "string"
					return r
				end
			end
		end
	catch
	end
	@log "symbol"
	return Symbol(@_token)
end

macro run_meta_string(s::String)
	(tokenize(s) → _meta_block) → esc
end
macro run_meta_string(s::String, BEGIN::String, END::String)
	_meta_block(tokenize(s), BEGIN, END) → esc
end
macro run_meta_string(s::Evaluable)
	(tokenize(eval(s)) → _meta_block) → esc
	#:(@run__meta_string $(eval(s))) ????????????
end
macro run_meta_string(s::Evaluable, BEGIN::String, END::String)
	_meta_block(tokenize(eval(s)), BEGIN, END) → esc
end

@END_OF_DEBUG_CATEGORY

# TODO:
# - make a better tokenizer that can split up expressions like: "(+ 3 4)"
#   - one can model the state machine as a set of permutations -- for example 'a' -- which maps one state (modeled as integers) to another
# - implement loops, anonymous functions (->), ranges and so on
#   - generalize expressions so as to include non-calls, like anonymous functions
