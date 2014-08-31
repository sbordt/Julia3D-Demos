using ImmutableArrays

include("include.jl")

@time obj = importOBJ("nvidia-examples/InstancedTessellation/assets/models/Butterfly/Butterfly.obj")




computeNormals!(obj)
compile(obj)

println(obj.mtllibs)
println(collect(keys(obj.materials)))
println(collect(keys(obj.groups)))
println(collect(keys(obj.smoothing_groups)))
println(obj.faces[1])

mtls = importMTL("nvidia-examples/InstancedTessellation/assets/models/Butterfly/Butterfly.mtl")
for mtl in mtls
	println(mtl)
end 