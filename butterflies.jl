using Meshes, ModernGL, GLAbstraction, GLWindow, ImmutableArrays, GLPlot
global const window = createwindow("Mesh Display", 1000, 1000, debugging = false) # debugging just works on linux and windows
const cam = PerspectiveCamera(window.inputs, Vec3(2,2,0.5), Vec3(0.5,0.5,0))


a = importOBJ("Butterfly.obj", faceindextype=GLuint, vertextype=Float32)
println(length(a[4]) / 3)
data = [
	:vertex 		=> GLBuffer(a[1]),
	:normal_vector	=> GLBuffer(a[2]),
	:offset         => Vec2(0),
	:indexes		=> indexbuffer(a[4]),
	:drawingmode    => GL_TRIANGLES,
	:zscale         => 0.05f0,
	:xscale         => 0.05f0,
	:yscale         => 0.05f0,
    :z              => 0f0,
]



function zdata(x1, y1, factor)
    x = (x1 - 0.5) * 15
    y = (y1 - 0.5) * 15
    R = sqrt(x^2 + y^2)
    Z = sin(R)/R
    Vec1(Z)
end

N = 30
texdata = [zdata(i/N, j/N, 5) for i=1:N, j=1:N]

#obj = toopengl(texdata) # This is the base case, where the Matrix is simply mapped as a surface, with white color
color = Texture(Pkg.dir()*"/GLPlot/docs/julia.png")
obj = toopengl(texdata,:z, primitive=data, color=color, xrange=(-3,3), yrange=(-3,3), camera=cam) # Color can be any matrix or a Vec3

glClearColor(1,1,1,0)
glDisable(GL_CULL_FACE)
glEnable(GL_DEPTH_TEST)


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