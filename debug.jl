mutable struct Debug
	level::UInt16
end

for op ∈ (:+, :-)
	@eval Base.$op(d::Debug, n::Int) = Debug(Base.$op(d.level, n))
end

global DEBUG_LEVEL = Debug(0)
const DEBUG_DO_PRINT = true
const DEBUG_LOG_FILE_NAME = ".julia_debug_log"

#{{{TEMPORARY
debug_file = open(DEBUG_LOG_FILE_NAME, "w")
write(debug_file, "")
close(debug_file)
#}}}

macro log(var)
	if typeof(var) == String
		return Expr(:call, :_debug_log, "(LOG) «", var, '»')
	end
	Expr(:call, :_debug_log, replace(string("(LOG) ", var, " = "), r"#=(?s).*?=# " => ""), var)
end

macro logged(func)
	if func.head != :function
		error("@logged used without a following function definition")
	end

	sig  = func.args[1]
	name =  sig.args[1]
	body = func.args[2]

	_debug_replace_returns(body, name)

	prod =	Expr(:function, sig,
				Expr(:block,
					 Expr(:call, :_debug_func_stack_call, QuoteNode(name)),
					body
				)
			)

	_debug_log("LOGGED: $name")
	return prod
end

function _debug_replace_returns(code::Expr, func_name::Symbol)
	if code.head == :->
		return
	end
	if code.head == :return
		ret_stmt = copy(code)
		new_asgn = :(_debug_return = $(ret_stmt.args[1]))
		code.head = :block
		code.args[1] = new_asgn
		push!(code.args, Expr(:call, :_debug_print_return_value, :_debug_return, QuoteNode(func_name)))
		push!(code.args, :(return _debug_return))
	else
		for arg in code.args
			if typeof(arg) == Expr
				_debug_replace_returns(arg, func_name)
			end
		end
	end
end

function _debug_func_stack_call(name::Symbol)
	_debug_log("(CALL) ", name)
	global DEBUG_LEVEL += 1
end

function _debug_print_return_value(value, name::Symbol)
	global DEBUG_LEVEL -= 1
	_debug_log("(RET) ", name, ": ", value)
end

function _debug_log(msgs...)
	msg = string(repeat('\t', DEBUG_LEVEL.level), msgs...)
	if DEBUG_DO_PRINT
		printstyled(msg, '\n', color = :blue)
	end
	#{{{TEMPORARY
	debug_file = open(DEBUG_LOG_FILE_NAME, "a")
	write(debug_file, string(msg, '\n'))
	close(debug_file)
	#}}}
end
