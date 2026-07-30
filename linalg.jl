@START_OF_DEBUG_CATEGORY "linalg"

using LinearAlgebra
using Symbolics

_LA_Val = Union{Symbol, Real}

@logged function LA_translation_matrix(x::_LA_Val, y::_LA_Val, z::_LA_Val)::Matrix{Num}
	for var ∈ (x, y, z)
		if typeof(var) ∈ (Symbol, Num)
			run_meta_string("( @variables $var )")
		end
	end

	return quote
		[
			1 0 0 $x
			0 1 0 $y
			0 0 1 $z
			0 0 0 1
		]
	end → eval
end

@logged function LA_rotation_matrix_x(θ::Real)::Matrix{Real}
	c = cosd(θ)
	s = sind(θ)

	return [
		1 0  0 0
		0 c -s 0
		0 s  c 0
		0 0  0 1
	]
end

@logged function LA_rotation_matrix_y(θ::Real)::Matrix{Real}
	c = cosd(θ)
	s = sind(θ)

	return [
		 c 0 s 0
		 0 1 0 0
		-s 0 c 0
		 0 0 0 1
	]
end

@logged function LA_rotation_matrix_z(θ::Real)::Matrix{Real}
	c = cosd(θ)
	s = sind(θ)

	return [
		c -s 0 0
		s  c 0 0
		0  0 1 0
		0  0 0 1
	]
end

@logged function LA_rotation_matrix_x(θ::Symbol)::Matrix{Num}
	run_meta_string("( @variables $θ )")

	return quote
		[
			1 0         0        0
			0 cosd($θ) -sind($θ) 0
			0 sind($θ)  cosd($θ) 0
			0 0         0        1
		]
	end → eval
end

function LA_rotation_matrix_y(θ::Symbol)::Matrix{Num}
	run_meta_string("( @variables $θ )")

	return quote
		[
			 cosd($θ) 0 sind($θ) 0
			 0        1 0        0
			-sind($θ) 0 cosd($θ) 0
			 0        0 0        1
		]
	end → eval
end

function LA_rotation_matrix_z(θ::Symbol)::Matrix{Num}
	run_meta_string("( @variables $θ )")

	return quote
		[
			cosd($θ) -sind($θ) 0 0
			sind($θ)  cosd($θ) 0 0
			0         0        1 0
			0         0        0 1
		]
	end → eval
end

function LA_rotation_matrix(x::_LA_Val, y::_LA_Val, z::_LA_Val)::Matrix{Num}
	LA_rotation_matrix_z(z) * LA_rotation_matrix_y(y) * LA_rotation_matrix_x(x)
end

@END_OF_DEBUG_CATEGORY
