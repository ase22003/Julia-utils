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

tokenize(str::String, str_filter::Function = x->replace(x, '\n'=>' '))::Tokens = filter!(x->x!="", split(str → str_filter, ' ')) → reverse

@logged function _meta_block(tokens::Tokens)::Expr
	@ignore tokens
	@ignore "begin"
	@ignore "end"
	if length(tokens) == 0
		return :(nothing)
	end
	if ==(@token, "begin")
		@next
	end
	statements::Vector{Expr} = []
	while true
		@log statements
		@log tokens
		if length(tokens) == 0
			break
		elseif ==(@token, "begin")
			push!(statements, _meta_block(tokens))
		elseif ==(@token, "end")
			@next
			break
		elseif ==(@token, "function")
			@log "FUNCTION"
			@next
			sig   = _meta_expr(tokens)
			block = _meta_block(tokens)
			push!(statements, Expr(:function, sig, block))
		elseif ==(@token, "return")
			@log "RETURN"
			@next
			push!(statements, Expr(:return, _meta_expr(tokens)))
		elseif ==(@token, "assign")
			@log "ASSIGNMENT"
			@next
			if ==(@token, "(")
				name = _meta_expr(tokens)
			else
				name = _meta_value(tokens)
				@next
			end
			if ==(@token, "(")
				value = _meta_expr(tokens)
			else
				value = _meta_value(tokens)
				@next
			end
			push!(statements, Expr(:(=), name, value))
		#= problem with scope, UndefVarError
		elseif ==(@token, "for")
			@log "'FOR' LOOP"
			@next
			iter  = _meta_expr(tokens)
			block = _meta_block(tokens)
			push!(statements, Expr(:for, iter, block))
		=#
		elseif ==(@token, "while")
			@log "'WHILE' LOOP"
			@next
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
function _meta_block(tokens::Tokens)
	_meta_block(tokens, "begin", "end")
end

@logged function _meta_expr(tokens::Tokens)::Expr
	@ignore tokens
	if length(tokens) == 0
		#error("there are no tokens to parse")
		return :(nothing)
	end
	if !=(@token, "(")
		error("expression must begin with '(' -- cannot begin with '$(@token)'")
	end
	@next
	args::Vector{Value} = []
	while true
		@log @token
		if     ==(@token, "(")
			push!(args, _meta_expr(tokens))
		elseif ==(@token, ")")
			@next
			break
		else # token is a value
			push!(args, _meta_value(tokens))
			@next
		end
	end

	if args[1] ∈ (:..., :->, :(::)) # non-call expressions
		@log "NON-CALL EXPRESSION"
		return Expr(args...)
	else
		@log "ASSUMING CALL"
		return Expr(:call, args...)
	end
end

@logged function _meta_value(tokens::Tokens)::Value
	@ignore tokens
	@log @token
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


# TODO:
# - make a better tokenizer that can split up expressions like: "(+ 3 4)"
#   - one can model the state machine as a set of permutations -- for example 'a' -- which maps one state (modeled as integers) to another
# - implement loops, anonymous functions (->), ranges and so on
#   - generalize expressions so as to include non-calls, like anonymous functions
