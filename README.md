## Example

```
julia> include("meta.jl")
LOGGED: call_expr
LOGGED: call_value
@run_call_string (macro with 4 methods)

julia> numbers = (3, 14, 15, 92, 65, 35) 
(3, 14, 15, 92, 65, 35)

julia> condition = isodd
iseven (generic function with 5 methods)

julia> result = @run_call_string "∃ $condition ( broadcast + 1 numbers )"
(CALL) call_expr
	(LOG) @token = ∃
	(LOG) «arguments:»
	(LOG) @token = isodd
	(CALL) call_value
		(LOG) «symbol»
	(RET) call_value: isodd
	(CALL) call_expr
		(LOG) @token = broadcast
		(LOG) «arguments:»
		(LOG) @token = +
		(CALL) call_value
			(LOG) «symbol»
		(RET) call_value: +
		(LOG) @token = 1
		(CALL) call_value
			(LOG) «integer»
		(RET) call_value: 1
		(LOG) @token = numbers
		(CALL) call_value
			(LOG) «symbol»
		(RET) call_value: numbers
	(RET) call_expr: broadcast(+, 1, numbers)
(RET) call_expr: ∃(isodd, broadcast(+, 1, numbers))
true
```
