using GLWindow, GLAbstraction, GLFW, ModernGL, ImmutableArrays, WavefrontObj
using GLPlot #toopengl 

include("../../include.jl")

window = createwindow("Mesh Display", 1000, 1000, debugging = false)
cam = PerspectiveCamera(window.inputs, Vec3(2,2,0.5), Vec3(0))

@time obj = readObjFile("assets/models/Butterfly/Butterfly.obj", faceindextype=GLuint, vertextype=Float32)
#@time obj = importOBJ("assets/models/Biff.obj", faceindextype=GLuint, vertextype=Float32)

computeNormals!(obj, override = true)
(vs, nvs, uvs,  vs_material_id, fcs) = compile(obj)

# hack: invert normals for glabstraction
nvs = -nvs

materials = readMtlFile("assets/models/Butterfly/Butterfly.mtl")
for mtl in materials
	println(mtl)
end 

shader = TemplateProgram("assets/shaders/standard.vert", "assets/shaders/phongblinn.frag")

data = [
	:vertex 		=> GLBuffer(unitGeometry(vs)),
	:normal			=> GLBuffer(nvs),
	:uv				=> GLBuffer(uvs),
	:material_id	=> GLBuffer(vs_material_id, 1),
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

