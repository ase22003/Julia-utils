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
			sig   = call_expr(tokens) # ARG!!!!!
			block = call_block(tokens) # ARG!!!!!
			push!(statements, Expr(:function, sig, block))
		elseif ==(@token, "return")
			@log "RETURN"
			@next
			push!(statements, Expr(:return, call_expr(tokens))) # ARG!!!!!
		elseif ==(@token, "assign")
			@log "ASSIGNMENT"
			@next
			if ==(@token, "(") # !!!!!
				name = call_expr(tokens) # ARG!!!!!
			else
				name = call_value(tokens)
				@next
			end
			if ==(@token, "(") # !!!!!
				value = call_expr(tokens) # ARG!!!!!
			else
				value = call_value(tokens)
				@next
			end
			push!(statements, Expr(:(=), name, value))
		#= problem with scope, UndefVarError
		elseif ==(@token, "for")
			@log "'FOR' LOOP"
			@next
			iter  = call_expr(tokens) # ARG!!!!!
			block = call_block(tokens) # ARG!!!!!
			push!(statements, Expr(:for, iter, block))
		=#
		elseif ==(@token, "while")
			@log "'WHILE' LOOP"
			@next
			cond  = call_expr(tokens) # ARG!!!!!
			block = call_block(tokens) # ARG!!!!!
			push!(statements, Expr(:while, cond, block))
		#= anonymous functions must be part of expressions -- they're not statements
		elseif ==(@token, "anon")
			@log "ANONYMOUS FUNCTION"
			@next
			arg   = call_value(tokens)
			@next
			if typeof(arg) != Symbol
				error("name of anonymous function must be a symbol. '$arg' is of type $(typeof(arg))")
			end
			block = call_block(tokens) # ARG!!!!!
			push!(statements, Expr(:(->), arg, block))
		=#
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
	(tokenize(s) → call_block) → esc
end
macro run_call_string(s::String, BEGIN::String, END::String)
	call_block(tokenize(s), BEGIN, END) → esc
end
macro run_call_string(s::Evaluable)
	(tokenize(eval(s)) → call_block) → esc
	#:(@run_call_string $(eval(s))) ????????????
end
macro run_call_string(s::Evaluable, BEGIN::String, END::String)
	call_block(tokenize(eval(s)), BEGIN, END) → esc
end


# TODO:
# - make a better tokenizer that can split up expressions like: "(+ 3 4)"
#   - one can model the state machine as a set of permutations -- for example 'a' -- which maps one state (modeled as integers) to another
# - implement loops, anonymous functions (->), ranges and so on
#   - generalize expressions so as to include non-calls, like anonymous functions
# - replace func(tokens, "begin", "("...) with a single dictionary of sybols func(tokens, sym_map), where sym_map = {EXPR_BEGIN => "("...}
# - rename call_X function names
