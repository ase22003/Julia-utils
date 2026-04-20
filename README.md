# Adrian's Julia Utilities

Herein are found implementations of various tools, the common purpose of whom is to aid in the writing process of Julia programs. These are intended to be used by me in future personal projects.

These tools include:

- debugging macros for tracing program flow;

- widely useful functions, such as ∀ and ∃;

- a string → syntax-tree compiler for easy metaprogramming;

- a generative grammar system.

## `debug.jl`: Debugging Macros

Add a `@logged` macro before your function definition to monitor its calls, provided arguments, returns and return values.

The log is both saved in a file called `.julia_debug_log` and printed directly in the terminal -- controlled by a boolean variable named `DEBUG_DO_PRINT`. Note that `return` must be explicity stated within the function for it to work with this macro. A connected macro -- `@ignore` -- makes the system not write out a specified argument in the log. It is written inside the function as a statement, with the variable as an argument.

Lastly, `@log` can add a custom message in the log. This can be either a string, or an expression -- such as the value of a variable one needs to monitor.

### Example

```
julia> @logged function MUL(a, b)
           @ignore a
           if b == 0
               return 0
           else
               @log "adding a"
               @log a
               return MUL(a, b - 1) + a
           end
       end
LOGGED: MUL
MUL (generic function with 1 method)

julia> MUL(3, 2)
(CALL) MUL
	(ARG) b = 2
	(LOG) «adding a»
	(LOG) a = 3
	(CALL) MUL
		(ARG) b = 1
		(LOG) «adding a»
		(LOG) a = 3
		(CALL) MUL
			(ARG) b = 0
		(RET) MUL: 0
	(RET) MUL: 3
(RET) MUL: 6
6
```

## `utils.jl`: Basic Utilities

...

## `meta.jl`: Metaprogramming

...

## `gen.jl`: Generative Grammar

...
