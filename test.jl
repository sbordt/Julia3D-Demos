using ImmutableArrays

include("include.jl")

@time obj = importOBJ("nvidia-examples/InstancedTessellation/assets/models/Butterfly/Butterfly.obj")
@time computeNormals!(obj)
@time compile(obj)

println(obj.mtllibs)
println(collect(keys(obj.materials)))
println(collect(keys(obj.groups)))
println(collect(keys(obj.smoothing_groups)))

println(obj.faces[1])