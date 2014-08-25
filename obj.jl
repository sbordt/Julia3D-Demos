
# f 
type WavefrontOBJFace{T}
    ivertices::Vector{T}
    itexture_coords::Vector{T}
    inormals::Vector{T}

    material::String
    groups::Vector{String}
    smoothing_group::Int
end

# type for obj file data
type WavefrontOBJ{T,V}
    vertices::Vector{Vector3{T}}
    normals::Vector{Vector3{T}}
    tex_coords::Vector{Vector3{T}}
    
    faces::Vector{WavefrontOBJFace{V}}

    groups::Dict{String, Array{Int}}
    smoothing_groups::Dict{Int, Array{Int}}

    mtllibs::Vector{String}
    materials::Dict{String, Array{Int}}
end 

function importOBJ(fn::String; vertextype=Float64, faceindextype=Int)
    str = open(fn,"r")
    mesh = importOBJ(str, vertextype=vertextype, faceindextype=faceindextype)
    close(str)
    return mesh
end

# smoothing groups: "off" goes to smoothing group 0, so each face has a unique smoothing group
function importOBJ(io::IO; vertextype=Float64, faceindextype=Int)
    vertexconvertfunc = vertextype == Float64 ? float64 : (vertextype == Float32 ? float32 : error("Vertex type: ", vertextype, " not supported"))
    faceconvertfunc = faceindextype == Int ? int : (
        faceindextype == Int32 ? int32 : (
            faceindextype == Uint64 ? uint64 : faceindextype == Uint32 ? uint32 : error("Faceindex type: ", faceindextype, " not supported")))   

    vs 	= Vector3{vertextype}[]
    nvs = Vector3{vertextype}[]
    uvs = Vector3{vertextype}[]
    fcs = WavefrontOBJFace{faceindextype}[]

    groups = Dict()
    current_groups = String[]
    smoothing_groups = [0 => Int[]]
    current_smoothing_group = 0

    mtllibs = String[]
    materials = Dict() # map material names to array with indieces of faces
    current_material = ""
    
    # face indices are allowed to be negative, these three methods handle that
    function vertexRef(s::String)
        i = int(s)
        if i < 0
            return faceconvertfunc(length(vs) + i +1)
        end
        return faceconvertfunc(i)
    end

    function normalRef(s::String)
        i = int(s)
        if i < 0
            return faceconvertfunc(length(nvs) + i +1)
        end
        return faceconvertfunc(i)
    end

    function textureRef(s::String)
        i = int(s)
        if i < 0
            return faceconvertfunc(length(uvs) + i +1)
        end
        return faceconvertfunc(i)
    end

    lineNumber = 1
    while !eof(io)
        # read a line, remove newline and leading/trailing whitespaces
        txt = strip(chomp(readline(io)))
        assert(is_valid_ascii(txt))

        if !beginswith(txt, "#") && !isempty(txt) && !iscntrl(txt) #ignore comments
            line = split(txt)
            #vertex, 3 components only
            if line[1] == "v" 
                push!(vs, Vector3{vertextype}(vertexconvertfunc(line[2]),
                                  vertexconvertfunc(line[3]),
                                  vertexconvertfunc(line[4])))         
            #texture coordinates, w is optional and defaults to 0
            elseif line[1] == "vt" 
                if length(line) == 4
                    push!(uvs, Vector3{vertextype}(vertexconvertfunc(line[2]),
                                    vertexconvertfunc(line[3]),
                                    vertexconvertfunc(line[4])))
                else
                    push!(uvs, Vector3{vertextype}(vertexconvertfunc(line[2]),
                                    vertexconvertfunc(line[3]),
                                    vertexconvertfunc("0")))                    
                end
            #normals, 3 components
            elseif line[1] == "vn" 
                push!(nvs, Vector3{vertextype}(vertexconvertfunc(line[2]),
                                  vertexconvertfunc(line[3]),
                                  vertexconvertfunc(line[4])))

            # faces: #/# or #/#/# or #//#. The first entrly determines the type for all following entries
            elseif line[1] == "f" 
                assert(length(line) >= 4)
                face = WavefrontOBJFace{faceindextype}([],[],[],"",[],0)

                # two slashes indicate #//#
                if (contains(line[2], "//"))    
                    for i=2:length(line)
                        v = split(line[i], "//")
                        assert(length(v) == 2)
                        push!(face.ivertices, vertexRef(v[1]))
                        push!(face.inormals, normalRef(v[2]))
                    end
                else
                    v = split(line[2], "/")

                    if length(v) == 1
                        for i=2:length(line)
                            push!(face.ivertices, vertexRef(line[i]))
                        end
                    elseif length(v) == 2
                        for i=2:length(line)
                            v = split(line[i], "/")
                            assert(length(v) == 2)
                            push!(face.ivertices, vertexRef(v[1]))
                            push!(face.itexture_coords, textureRef(v[2]))
                        end
                    elseif length(v) == 3
                        for i=2:length(line)
                            v = split(line[i], "/") 
                            assert(length(v) == 3)
                            push!(face.ivertices, vertexRef(v[1]))
                            push!(face.itexture_coords, textureRef(v[2]))
                            push!(face.inormals, normalRef(v[3]))
                        end
                    else
                        println("WARNING: Illegal line while parsing wavefront .obj: '$txt' (line $lineNumber)")
                        continue
                    end

                end
                
                # add face to groups, smoothing_groups, material
                for group in current_groups
                    push!(groups[group], length(fcs)+1) 
                    push!(face.groups, group)
                end

                if current_material != ""
                    push!(materials[current_material], length(fcs)+1)
                    face.material = current_material
                end

                push!(smoothing_groups[current_smoothing_group], length(fcs)+1)
                face.smoothing_group = current_smoothing_group

                push!(fcs, face)

            # groups
            elseif line[1] == "g"
                current_groups = String[];

                if length(line) >= 2
                    for i=2:length(line)
                        push!(current_groups, line[i]) 
                        if !haskey(groups, line[i])
                            groups[line[i]] = Int[]
                        end
                    end
                else
                    current_groups = ["default"];
                    if !haskey(groups, "default")
                        groups["default"] = Int[]
                    end
                end

            # set the smoothing group, 0 and off have the same meaning
            elseif line[1] == "s" 
                if line[2] == "off" 
                    current_smoothing_group = 0
                else
                    current_smoothing_group = int(line[2])
                end

                if !haskey(smoothing_groups, current_smoothing_group)
                    smoothing_groups[current_smoothing_group] = Int[]
                end

            # material lib reference
            elseif line[1] == "mtllib"
                for i=2:length(line)
                    push!(mtllibs, line[i])
                end

            # set a new material
            elseif line[1] == "usemtl"
                current_material = line[2];

                if !haskey(materials, current_material)
                    materials[current_material] = Int[]
                end

            # unknown line
            else 
                println("WARNING: Unknown line while parsing wavefront .obj: '$txt' (line $lineNumber)")
            end
        end

        # read next line
        lineNumber += 1
    end

    # triangulate polygons
    i = 1
    while i <= length(fcs)
        face = fcs[i]

        if length(face.ivertices) > 3
            triangle = WavefrontOBJFace{faceindextype}(face.ivertices[1:3], [], [], face.material, copy(face.groups), copy(face.smoothing_group))
            splice!(face.ivertices, 2)

            if !isempty(face.itexture_coords)
                triangle.itexture_coords = face.itexture_coords[1:3]
                splice!(face.texture_coords, 2)
            end
            if !isempty(face.inormals)
                triangle.inormals = face.inormals[1:3]
                splice!(face.inormals, 2)
            end

            # add face to groups, smoothing_groups, material


            #for group in triangle.groups
            #    push!(groups[group], length(fcs)+1) 
            #end
#TODO material
          #  if current_material != ""
         #      push!(materials[current_material], length(fcs)+1)
           # end

            push!(smoothing_groups[triangle.smoothing_group], length(fcs)+1)

            push!(fcs, triangle)
            continue
        end

        i += 1
    end

    return WavefrontOBJ{vertextype,faceindextype}(vs, nvs, uvs, fcs, groups, smoothing_groups, mtllibs, materials)
end

function computeNormals!{vertextype,faceindextype}(obj::WavefrontOBJ{vertextype,faceindextype}, override::Bool = false)
    #= in the first step, duplicate vertices that belong to more than one smoothing group
    vertex_smoothing_groups = zeros[Int, length(obj.vertices)]

    for face in obj.faces # for each face
        for i=1:3 # for each vertex that belongs to the face
            ivertex = face.vertices[i]

            if vertex_smoothing_groups[ivertex] != face.smoothing_group # does the vertex already belong to a different smoothing group than that of the face given?
                push!(obj.vertices, copy(obj.vertices[ivertex]))
                face.vertices[i] 
            end
        end        
    end =#

    # compute normals per smoothing group
    for sgroup in obj.smoothing_groups
        ifaces = sgroup[2]

        # compute normal for each face
        face_normals = Array(Vector3{vertextype},length(ifaces))

        for (i, elem) in enumerate(ifaces)
            face = obj.faces[elem]
            e1 = obj.vertices[face.ivertices[2]] - obj.vertices[face.ivertices[1]]
            e2 = obj.vertices[face.ivertices[3]] - obj.vertices[face.ivertices[2]]

            n = unit(cross(e1,e2))
            face_normals[i] = n

            push!(obj.normals, n)
            face.inormals = [length(obj.normals),length(obj.normals),length(obj.normals)]
        end 

        # for each vertex, have an array of faces it belongs to
        #= vertex_faces = Dict()

        for i in faces
            face = faces[i]


            push!(collection, items...) -> collectio)
        end =#


        # for each vertex, take the average value over all faces

    end
end

# compile OBJ
function compile{vertextype,faceindextype}(obj::WavefrontOBJ{vertextype,faceindextype})
    # change this copy&paste
    faceconvertfunc = faceindextype == Int ? int : (
        faceindextype == Int32 ? int32 : (
            faceindextype == Uint64 ? uint64 : faceindextype == Uint32 ? uint32 : error("Faceindex type: ", faceindextype, " not supported")))

    vs_compiled  = Vector3{vertextype}[]
    nvs_compiled = Vector3{vertextype}[]
    uvs_compiled = Vector3{vertextype}[]
    vs_material_id = Float32[]
    fcs_compiled = Vector3{faceindextype}[]

    i = 0
    for face in obj.faces
        push!(vs_compiled, obj.vertices[face.ivertices[1]])
        push!(vs_compiled, obj.vertices[face.ivertices[2]])
        push!(vs_compiled, obj.vertices[face.ivertices[3]])
        push!(vs_material_id, float32(findfirst(collect(keys(obj.materials)), face.material)))
        push!(vs_material_id, float32(findfirst(collect(keys(obj.materials)), face.material)))
        push!(vs_material_id, float32(findfirst(collect(keys(obj.materials)), face.material)))

        if isempty(face.inormals)
            println("WARNING: No normals!!!")
            push!(uvs_compiled, Vector3{vertextype}(0.0,0.0,0.0))
            push!(uvs_compiled, Vector3{vertextype}(0.0,0.0,0.0))
            push!(uvs_compiled, Vector3{vertextype}(0.0,0.0,0.0))
        else 
            push!(nvs_compiled, -obj.normals[face.inormals[1]])
            push!(nvs_compiled, -obj.normals[face.inormals[2]])
            push!(nvs_compiled, -obj.normals[face.inormals[3]])
        end

        if isempty(face.itexture_coords)
            push!(uvs_compiled, Vector3{vertextype}(0.0,0.0,0.0))
            push!(uvs_compiled, Vector3{vertextype}(0.0,0.0,0.0))
            push!(uvs_compiled, Vector3{vertextype}(0.0,0.0,0.0))
        else 
            push!(uvs_compiled, obj.tex_coords[face.itexture_coords[1]])
            push!(uvs_compiled, obj.tex_coords[face.itexture_coords[2]])
            push!(uvs_compiled, obj.tex_coords[face.itexture_coords[3]])
        end

        push!(fcs_compiled, Vector3{faceindextype}(faceconvertfunc(i), faceconvertfunc(i+1), faceconvertfunc(i+2)))
        i += 3
    end

    return (vs_compiled, nvs_compiled, uvs_compiled, vs_material_id, fcs_compiled)
end


##############################
#
# Read MTL-Files
#
##############################

type WavefrontMTLMaterial{T}
    name::String
    ambient:Vector3{T}
    specular:Vector3{T}
    diffuse:Vector3{T}
end

function WavefrontMTLMaterial()
    return WavefrontMTLMaterial{T}("", Vector3{T}(0))
end

function importMTL(fn::String; colortype=Float64)
    str = open(fn,"r")
    mesh = importMTL(str, colortype=colortype)
    close(str)
    return mesh
end

function importMTL(io::IO; colortype=Float64)
    colorconv = convert(colortype)

    materials = WavefrontMTLMaterial{colortype}[]

    lineNumber = 1
    while !eof(io)
        # read a line, remove newline and leading/trailing whitespaces
        txt = strip(chomp(readline(io)))
        assert(is_valid_ascii(txt))

        if !beginswith(txt, "#") && !isempty(txt) && !iscntrl(txt) #ignore comments
            line = split(txt)
            # new material
            if line[1] == "newmtl" 
                push!(materials, WavefrontMTLMaterial{colortype}())
                materials[end].name = line[2]
            # abmient 
            elseif line[1] == "Ka"
            # diffuse
            elseif line[1] == "Kd"
            # specular
            elseif line[1] == "Ks"
            #
            elseif line[1] == "Tf"
            # ???
            elseif line[1] == "illum"
            # ???
            elseif line[1] == "d"
            # ???
            elseif line[1] == "Ns"
            # ???
            elseif line[1] == "sharpness"
            # ???
            elseif line[1] == "Ni"
            # ???
            elseif line[1] == "map_Ka"
            # ???
            elseif line[1] == "map_Kd"
            # ???
            elseif line[1] == "map_Ks"
            # ???
            elseif line[1] == "map_Ns"
            # ???
            elseif line[1] == "map_d"
            # ???
            elseif line[1] == "disp"
            # ???
            elseif line[1] == "decal"
            # ???
            elseif line[1] == "bump"
            # ???
            elseif line[1] == "refl"
            # unknown line
            else 
                println("WARNING: Unknown line while parsing wavefront .mtl: '$txt' (line $lineNumber)")
            end
        end

        # read next line
        lineNumber += 1
    end
end