using GLWindow, GLAbstraction, GLFW, ModernGL, ImmutableArrays
using GLPlot #toopengl 

include("../../include.jl")

window = createwindow("Mesh Display", 1000, 1000, debugging = false)
cam = PerspectiveCamera(window.inputs, Vec3(2,2,0.5), Vec3(0))

@time a = importOBJ("assets/models/airboat.obj", faceindextype=GLuint, vertextype=Float32)

#@time mtl = importMTL("assets/models/Butterfly/Butterfly.mtl", colortype=Float32)
#println(length(mtl))

shader = TemplateProgram("assets/shaders/standard.vert", "assets/shaders/phongblinn.frag")

data = [
	:vertex 		=> GLBuffer(unitGeometry(a[1])),
#b	:normal			=> GLBuffer(a[2]),
	:indexes		=> indexbuffer(a[4]),

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

