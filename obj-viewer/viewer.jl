using GLWindow, GLAbstraction, GLFW, ModernGL, ImmutableArrays, WavefrontObj, Gtk
using GLPlot #toopengl 

include("../include.jl")

function open_obj_dialog()
	return open_dialog("Select an .obj file!", filters=("*.obj",))
end

#objpath = "assets/models/Elephant/elephant.obj"
#objpath = "assets/models/cat/cat.obj"
#objpath = "assets/models/Butterfly/Butterfly.obj"
#objpath = "assets/models/airboat.obj"
objpath = open_obj_dialog()

obj = readObjFile(objpath, faceindextype=GLuint, vertextype=Float32, compute_normals = false, triangulate = false)
computeNormals!(obj, smooth_normals = true, override = false)
triangulate!(obj)

# load mtl files if present
materials = WavefrontMtlMaterial{Float32}[]

for mtllib in obj.mtllibs
	materials = [materials, readMtlFile( objpath[1:rsearchindex(objpath, "/")]*mtllib, colortype=Float32 )] 
end

(vs, nvs, uvs,  vs_material_id, fcs) = compile(obj)

# hack: invert normals for glabstraction
nvs = -nvs

window = createwindow("OBJ-Viewer", 1000, 1000, debugging = false)
cam = PerspectiveCamera(window.inputs, Vec3(2,2,0.5), Vec3(0))

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
  
  if in(341, window.inputs[:buttonspressed].value) &&  in(79, window.inputs[:buttonspressed].value)
  	# strg + o 
  end

  yield() # this is needed for react to work

  GLFW.SwapBuffers(window.glfwWindow)
  GLFW.PollEvents()
end

GLFW.Terminate()

