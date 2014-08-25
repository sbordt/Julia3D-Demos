using GLWindow, GLAbstraction, GLFW, ModernGL, ImmutableArrays
using GLPlot #toopengl 

include("../include.jl")

window = createwindow("OBJ-Viewer", 1000, 1000, debugging = false)
cam = PerspectiveCamera(window.inputs, Vec3(2,2,0.5), Vec3(0))

#@time obj = importOBJ("assets/models/buddha.obj", faceindextype=GLuint, vertextype=Float32)
@time obj = importOBJ("assets/models/Elephant/elephant.obj", faceindextype=GLuint, vertextype=Float32)

println(obj.mtllibs)
println(collect(keys(obj.materials)))
println(collect(keys(obj.groups)))
println(collect(keys(obj.smoothing_groups)))

@time computeNormals!(obj)
@time (vs, nvs, uvs,  vs_material_id, fcs) = compile(obj)

# compute index buffer for GL_LINES rendering
lines = Vector2{GLuint}[]

for face in fcs
	push!(lines, Vector2{GLuint}(face[1], face[2]))
	push!(lines, Vector2{GLuint}(face[2], face[3]))
	push!(lines, Vector2{GLuint}(face[1], face[3]))
end

shader = TemplateProgram("assets/shaders/standard.vert", "assets/shaders/phongblinn.frag")

data = [
	:vertex 		=> GLBuffer(unitGeometry(vs)),
	:normal			=> GLBuffer(nvs),
	:indexes		=> indexbuffer(fcs),
#	:indexes		=> indexbuffer(lines),

	:view 			=> cam.view,
	:projection 	=> cam.projection,
	:normalmatrix	=> cam.normalmatrix,
	:model 			=> eye(Mat4),

	:material_ambient 	=> Vec3(1,1,1),
	:material_specular 	=> Vec3(1,1,1),
	:material_diffuse 	=> Vec3(1,1,1),

	:light_position => Vec3(-1,-1,-1),
	:light_ambient 	=> Vec3(0.1,0.1,0.1),
	:light_specular => Vec3(0,0,0),
	:light_diffuse 	=> Vec3(0.7,0.7,0.7)
]

obj = RenderObject(data, shader)

postrender!(obj, render, obj.vertexarray)
#postrender!(obj, render, obj.vertexarray, GL_LINES)

# OpenGL setup
glClearColor(0.2,0.2,0.2,1)
glDisable(GL_CULL_FACE)
glEnable(GL_DEPTH_TEST)

# Loop until the user closes the window
while !GLFW.WindowShouldClose(window.glfwWindow)

  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)

  render(obj)

  yield() # this is needed for react to work

  GLFW.SwapBuffers(window.glfwWindow)
  GLFW.PollEvents()
end

GLFW.Terminate()

