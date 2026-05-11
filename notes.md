# Notes

- In order to observe observations, we must be able to compare dictionaries/expressions/programs -- like finding differences in string representations thereof. In order to do so, the program must operate on string representations of programs in which things like dictionaries and other rules are defined -- not on dictionary datatypes directly. If I could get an `Expr` from a variable, like with `dump`, I could convert it to a string in my `meta.jl` syntax, operate thereon, and then evaluate it back into executable code with the same library. Perhaps Julia's metaprogramming isn't powerful enough for that, and I'll have to use my own language.

- Numbers is a concept that should probably be given to the system -- and will accelerate learning drastically.
