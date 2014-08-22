using Meshes, ModernGL, GLAbstraction, GLWindow, ImmutableArrays, GLPlot
global const window = createwindow("Mesh Display", 1000, 1000, debugging = false) # debugging just works on linux and windows
const cam = PerspectiveCamera(window.inputs, Vec3(2,2,0.5), Vec3(0.5,0.5,0))
function importOBJ(fn::String; topology=false, vertextype=Float64, faceindextype=Int)
    str = open(fn,"r")
    mesh = importOBJ(str, topology=topology, vertextype=vertextype, faceindextype=faceindextype)
    close(str)
    return mesh
end


function importOBJ(io::IO; topology=false, vertextype=Float64, faceindextype=Int)
    vs 	= Vector3{vertextype}[]
    nvs = Vector3{vertextype}[]
    uvs = Vector3{vertextype}[]
    fcs = Vector3{faceindextype}[]
    

    vertexconvertfunc = vertextype == Float64 ? float64 : (vertextype == Float32 ? float32 : error("Vertex type: ", vertextype, " not supported"))
    faceconvertfunc = faceindextype == Int ? int : (
        faceindextype == Int32 ? int32 : (
            faceindextype == Uint64 ? uint64 : faceindextype == Uint32 ? uint32 : error("Faceindex type: ", faceindextype, " not supported")))

    nV = 0
    nF = 0
    middle = Vector3{vertextype}(0)

    maxvx = -typemax(vertextype)
    maxvy = -typemax(vertextype)
    maxvz = -typemax(vertextype)

    minvx = typemax(vertextype)
    minvy = typemax(vertextype)
    minvz = typemax(vertextype)

    while !eof(io)
        txt = readline(io)
        if !beginswith(txt, "#") && !isempty(txt) && !iscntrl(txt)
            line = split(txt)
            if line[1] == "v" #vertex
                push!(vs, Vertex{vertextype}(vertexconvertfunc(line[2]),
                                  vertexconvertfunc(line[3]),
                                  vertexconvertfunc(line[4])))
                cvec = last(vs)
                middle = middle + cvec
                if cvec[1] > maxvx
                	maxvx = cvec[1]
                end
                if cvec[2] > maxvy
                	maxvy = cvec[2]
                end
                if cvec[3] > maxvz
                	maxvz = cvec[3]
                end

                if cvec[1] < minvx
                	minvx = cvec[1]
                end
                if cvec[2] < minvy
                	minvy = cvec[2]
                end
                if cvec[3] < minvz
                	minvz = cvec[3]
                end

            elseif line[1] == "f" #face
                #get verts
                verts = faceindextype[faceconvertfunc(split(line[i], "/")[1]) - one(faceindextype) for i = 2:length(line)]
                for i = 3:length(verts) #triangulate
                    push!(fcs, Vector3{faceindextype}(verts[1], verts[i-1], verts[i]))
                end
           	elseif line[1] == "vt" #UV coordinates
                push!(uvs, Vector3{vertextype}(vertexconvertfunc(line[2]),
                                  vertexconvertfunc(line[3]),
                                  vertexconvertfunc(line[4])))
            elseif line[1] == "vn" #Normals
                push!(nvs, Vector3{vertextype}(-vertexconvertfunc(line[2]),
                                  -vertexconvertfunc(line[3]),
                                  - vertexconvertfunc(line[4])))
            end
        end
    end
    

    middle = (middle / length(vs))
    maxv = Vector3(maxvx, maxvy, maxvz) - middle
    minv = Vector3(minvx, minvy, minvz) - middle
    return (map(x-> (x - middle) ./ maxv, vs), nvs, uvs, fcs)
end


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