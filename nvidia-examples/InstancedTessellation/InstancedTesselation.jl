using GLWindow, GLAbstraction, GLFW, ModernGL, ImmutableArrays
using GLPlot #toopengl 

include("../../include.jl")

window = createwindow("Mesh Display", 1000, 1000, debugging = false)
cam = PerspectiveCamera(window.inputs, Vec3(2,2,0.5), Vec3(0))

@time obj = importOBJ("assets/models/Butterfly/Butterfly.obj", faceindextype=GLuint, vertextype=Float32)
#@time obj = importOBJ("assets/models/Biff.obj", faceindextype=GLuint, vertextype=Float32)

println(obj.mtllibs)
println(collect(keys(obj.materials)))
println(collect(keys(obj.groups)))
println(collect(keys(obj.smoothing_groups)))

@time computeNormals!(obj)
@time (vs, nvs, uvs,  vs_material_id, fcs) = compile(obj)

materials = importMTL("assets/models/Butterfly/Butterfly.mtl")
for mtl in materials
	println(mtl)
end 

shader = TemplateProgram("assets/shaders/standard.vert", "assets/shaders/phongblinn.frag")
println(minimum(vs_material_id))
println(maximum(vs_material_id))
matid = GLBuffer(vs_material_id, 1)
println(eltype(matid))

data = [
	:vertex 		=> GLBuffer(unitGeometry(vs)),
	:normal			=> GLBuffer(nvs),
	:uv				=> GLBuffer(uvs),
	:material_id	=> matid,
	:indexes		=> indexbuffer(fcs),

	:tex1 			=> Texture("assets/models/Butterfly/BUTTBODY.JPG"),
	:tex2 			=> Texture("assets/models/Butterfly/BUTTFACE.JPG"),
	:tex3 			=> Texture("assets/models/Butterfly/BUTTWIBA.JPG"),
	:tex4 			=> Texture("assets/models/Butterfly/BUTTWIFR.JPG"),

	:view 			=> cam.view,
	:projection 	=> cam.projection,
	:normalmatrix	=> cam.normalmatrix,
	:model 			=> eye(Mat4),

	:color 			=> Vec4(0,1,0,1),
	:light_position => Vec3(1,1,1)
]

obj = RenderObject(data, shader)
postrender!(obj, render, obj.vertexarray)

# OpenGL setup
glClearColor(1,1,1,0)
glDisable(GL_CULL_FACE)
glEnable(GL_DEPTH_TEST)

# Loop until the user closes the window
while !GLFW.WindowShouldClose(window.glfwWindow)

  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
  #push!(grid_size, Vec3(sin(runner) * 30.0))

  render(obj)

  #timeseries(window.inputs[:window_size].value)

  yield() # this is needed for react to work

  GLFW.SwapBuffers(window.glfwWindow)
  GLFW.PollEvents()

end

GLFW.Terminate()

