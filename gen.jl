include("utils.jl")
include("debug.jl")

using Random: shuffle

#{{{AI GENERATED CODE
function weighted_sample(items::Tuple, f::Function) #AI GENERATED
	@ignore f
	# Calculate weights based on the function
	weights = map(f, items)
	total_weight = sum(weights)
	
	# Pick a random threshold
	r = rand() * total_weight
	
	# Iterate and subtract until we hit the threshold
	current_sum = 0.0
	for (i, w) in enumerate(weights)
		current_sum += w
		if r <= current_sum
			 return items[i]
		end
	end
	return items[end] # Fallback for rounding issues
end
#}}}

@logged function ϟ(Φ::Dict, σ::Tuple)::Tuple
	if length(σ) == 0
		return σ
	end

	new = []
	for token ∈ σ
		if token ∈ keys(Φ)
			push!(new, rand(Φ[token])...)
		else
			push!(new, token)
		end
	end

	return tuple(new...)
end


@logged function ϟ_inference(Φ::Dict, σ::Tuple, depth::Float64)::Tuple
	if length(σ) == 0
		return σ
	end

	new = []
	for token ∈ σ
		if token ∈ keys(Φ)
			push!(new, weighted_sample(Φ[token], x->MathConstants.e^(length(x)*depth))...)
		else
			push!(new, token)
		end
	end

	return tuple(new...)
end

@logged function ϟ(Φ::Dict, σ::Tuple, depth::Float64, breadth::Float64, decay::Function)::Tuple
		if length(σ) == 0
			return σ
		end

		new = []
		for token ∈ σ
			if token ∈ keys(Φ)
				#push!(new, (ϟ(Φ, weighted_sample(Φ[token], x->MathConstants.e^(length(intersect(x, keys(Φ)))*depth)), decay(depth), breadth, decay))...)
				push!(new, (ϟ(Φ, weighted_sample(Φ[token], x->MathConstants.e^(length(filter!(t->t∈ keys(Φ), collect(x)))*depth)), decay(depth), breadth, decay))...)
				depth += breadth
			else
				push!(new, token)
			end
		end

		return tuple(new...)
end

function legs(Φ::Dict, σ::Tuple)::Int64
	@ignore Φ
	return length(filter!(t->t ∈ keys(Φ), collect(σ)))
end
@logged function ϟ_bread(Φ::Dict, σ::Tuple, depth_breadth::Float64)::Tuple
	@ignore Φ
	if length(σ) == 0
		return σ
	end

	if depth_breadth == 0.0
		error("depth_breadth ought not to equal zero, lest the function run forever")
	end

	new = []
	breadth::Int64 = 0
	for token ∈ σ
		if token ∈ keys(Φ)
			push!(new,
				db->(
					ϟ_bread(
						Φ,
						weighted_sample(
							Φ[token],
							x->db^(legs(Φ, x))
							#MathConstants.e^(length(filter!(t->t∈ keys(Φ), collect(x)))*db)
						),
						db
					)
				)
			)
			breadth += 1
		else
			push!(new, token)
		end
	end

	new2 = []
	for (i, item) ∈ enumerate(new)
		if typeof(item) <: Function
			push!(new2, item(depth_breadth/(breadth))...)
		else
			push!(new2, item)
		end
	end

	return tuple(new2...)
end

#{{{EXAMPLES
mx = Dict(
	'x' => (
		#('t'," + ",'x'),
		('x'," + ",'x'),
		('t',)
	),
	't' => (
		#('f'," * ",'t'),
		('t'," × ",'t'),
		('f',)
	),
	'f' => (
		('(','x',')'),
		('n',)
	),
	'n' => (
		('-', 'v'),
		('v',)
	),
	'v' => (
		('V',),
		('N',)
	),
	'V' => tuple((split("αβγδεζηθικλμξοπρστυφχψω","") .|> x->x[1] .|> tuple)...),
	'N' => (
		('N','N'),
		("digit",)
	),
	"digit" => tuple(((0:9) .|> string .|> x->x[1] .|> tuple)...)
)

mx2 = Dict(
	'x' => (
		('x'," + ",'x'),
		('x'," × ",'x'),
		('(','x',')'),
		('-', 'v'),
		('v',)
	),
	'v' => (
		('V',),
		('N',)
	),
	'V' => tuple((split("αβγδεζηθικλμξοπρστυφχψω","") .|> x->x[1] .|> tuple)...),
	'N' => (
		('N','N'),
		("digit",)
	),
	"digit" => tuple(((0:9) .|> string .|> x->x[1] .|> tuple)...)
)

språk = Dict(
	"mening" => (
		("mening", ' ', "konnektiv", ' ', "mening"),
		("sats",)
	),
	"konnektiv" => (
		("och",),
		("eller",),
		("medan",),
		("om",),
		#("om, och endast om",)
	),
	"sats" => (
		("objekt", ' ', "verb", ' ', "objekt"),
	),
	"verb" => (
		("verb",' ', "adverb"),
		("kör",),
		("äger",),
		("säljer",),
		("köper",),
		("målar",),
		("är",)
	),
	"objekt" => (
		("min ", "person"),
		("en ", "substantiv")
	),
	"substantiv" => (
		("egenskap", ' ', "substantiv"),
		("bil",),
		("dator",),
		("katt",),
		("hund",),
		("bok",),
	),
	"adverb" => (
		("snabbt",),
		("långsamt",),
		("hårt",),
		("mjukt",),
	),
	"adjektiv" => (
		("mycket",),
		("lite",),
		("lagom",),
		("extremt",),
		("inte",),
	),
	"person" => (
		("egenskap", " ", "person"),
		("familjemedlem","s ", "person"),
		("bekant","s ", "person"),
		("familjemedlem",),
		("bekant",),
	),
	"familjemedlem" => (
		("mor",),
		("far",),
		("fru",),
		("make",),
		("dotter",),
		("son",),
		("syster",),
		("broder",)
	),
	"bekant" => (
		("vän",),
		("skolkamrat",),
		("lärare",),
		("läkare",),
		("fiende",),
		("kollega",),
		("flickvän",),
		("pojkvän",),
	),
	"egenskap" => (
		("smarta",),
		("snälla",),
		("korkade",),
		("galna",),
		("coola",),
		("elaka",)
	),
)
#}}}



#mönstermatchning? -- med regex? med syntax? med godtycklig regel!?
