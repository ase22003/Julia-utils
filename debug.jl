printstyled("--- INITIATING DEBUG SYSTEM ---\n", color=:yellow)

Evaluable = Union{Expr, Symbol}

mutable struct Debug
	level::UInt16
end

for op ∈ (:+, :-)
	@eval Base.$op(d::Debug, n::Int) = Debug(Base.$op(d.level, n))
end

global DEBUG_LEVEL = Debug(0)
global DEBUG_DO_PRINT = true
const  DEBUG_LOG_FILE_NAME = ".julia_debug_log"

#{{{TEMPORARY
debug_file = open(DEBUG_LOG_FILE_NAME, "w")
write(debug_file, "")
close(debug_file)
#}}}

global DEBUG_CURRENT_CATEGORY::String = "default"
global DEBUG_ENABLED_CATEGORIES::Set{String} = Set(["default"])

macro START_OF_DEBUG_CATEGORY(name::String)
	#printstyled("--- NOW REGISTERING FUNCTIONS UNDER '$name' ---\n", color=:yellow)
	:(DEBUG_CURRENT_CATEGORY = $name) |> esc
end
macro END_OF_DEBUG_CATEGORY()
	#printstyled("--- NOW REGISTERING FUNCTIONS UNDER 'default' ---\n", color=:yellow)
	:(DEBUG_CURRENT_CATEGORY = "default") |> esc
end
macro ENABLE_DEBUG_CATEGORY(name::String)
	:(push!(DEBUG_ENABLED_CATEGORIES, $name))
end
macro DISABLE_DEBUG_CATEGORY(name::String)
	:(delete!(DEBUG_ENABLED_CATEGORIES, $name))
end

function _add_debug_category_check(log_expr::Expr)
	Expr(:if, Expr(:call, :∈, DEBUG_CURRENT_CATEGORY, :DEBUG_ENABLED_CATEGORIES), log_expr)
end

macro log(msg::String)
	Expr(:call, :_debug_log, "(LOG) «", msg, '»') → _add_debug_category_check
end
macro log(val::Evaluable, str::String)
	Expr(:call, :_debug_log, replace(string("($str) $val = "), r"#=(?s).*?=# " => ""), val)
end
macro log(var::Evaluable)
	:(@log $var "LOG")
end

macro ignore(arg) #used within @logged
	:(nothing)
end
macro logged(func)
	if func.head ∉ (:function, :macro)
		error("@logged used without a following function or macro definition")
	end

	     sig::Expr   = func.args[1]
	    body::Expr   = func.args[2]
	sig_expr::Expr   = _get_sig_expr(sig)
	    name::Symbol = sig_expr.args[1]

	args::Set{Symbol} = Set(sig_expr.args[2:end] .|> x -> typeof(x) == Symbol ? x : _get_sig_expr(x).args[1])

	#{{{register @ignore statements
	for stmt ∈ body.args
		if typeof(stmt) == Expr
			if stmt.head == :macrocall
				if stmt.args[1] == Symbol("@ignore")
					for arg ∈ stmt.args[2:end]
						if typeof(arg) == Symbol
							if arg ∉ args
								error("@ignore used on a non-existent or already ignored variable '$arg'")
							end
							_debug_log("Ignoring argument '$arg' in '$name'")
							delete!(args, arg)
						end
					end
				end
			end
		end
	end
	#}}}

	_add_category_checks_to_logs(body)

	_debug_replace_returns(body, name)

	prod =	Expr(:function, sig,
				Expr(:block,
					Expr(:call, :_debug_func_stack_call, QuoteNode(name)) → _add_debug_category_check,
					(args .|> x->(:(@log $x "ARG") → _add_debug_category_check))...,
					body
				)
			)

	_debug_log("Logged '$name' under '$DEBUG_CURRENT_CATEGORY'")
	return prod
end

function _get_sig_expr(e::Expr)::Expr
	if typeof(e.args[1]) == Symbol
		return e
	else
		return _get_sig_expr(e.args[1])
	end
end

function _add_category_checks_to_logs(code::Expr)
	for (i, expr) ∈ enumerate(code.args)
		if typeof(expr) == Expr
			if (expr.head == :macrocall) && (expr.args[1] == Symbol("@log"))
				code.args[i] = expr → _add_debug_category_check
			else
				_add_category_checks_to_logs(code.args[i])
			end
		end
	end
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
		push!(code.args, Expr(:call, :_debug_print_return_value, :_debug_return, QuoteNode(func_name)) → _add_debug_category_check)
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

# TODO:
# - add a way to toggle categories of logs, such as for files or between flags
