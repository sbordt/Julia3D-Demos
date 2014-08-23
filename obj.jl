
function importOBJ(fn::String; vertextype=Float64, faceindextype=Int)
    str = open(fn,"r")
    mesh = importOBJ(str, vertextype=vertextype, faceindextype=faceindextype)
    close(str)
    return mesh
end

type Face{T}
    vertices::Vector{T}
    texture_coords::Vector{T}
    normals::Vector{T}
end

function importOBJ(io::IO; vertextype=Float64, faceindextype=Int)
    vertexconvertfunc = vertextype == Float64 ? float64 : (vertextype == Float32 ? float32 : error("Vertex type: ", vertextype, " not supported"))
    faceconvertfunc = faceindextype == Int ? int : (
        faceindextype == Int32 ? int32 : (
            faceindextype == Uint64 ? uint64 : faceindextype == Uint32 ? uint32 : error("Faceindex type: ", faceindextype, " not supported")))   

    vs 	= Vector3{vertextype}[]
    nvs = Vector3{vertextype}[]
    uvs = Vector3{vertextype}[]
    fcs = Face{faceindextype}[]

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
                face = Face{faceindextype}([],[],[])

                # two slashes indicate #//#
                if (contains(line[2], "//"))    
                    for i=2:length(line)
                        v = split(line[i], "//")
                        assert(length(v) == 2)
                        push!(face.vertices, vertexRef(v[1]))
                        push!(face.normals, normalRef(v[2]))
                    end
                else
                    v = split(line[2], "/")

                    if length(v) == 1
                        for i=2:length(line)
                            push!(face.vertices, vertexRef(line[i]))
                        end
                    elseif length(v) == 2
                        for i=2:length(line)
                            v = split(line[i], "/")
                            assert(length(v) == 2)
                            push!(face.vertices, vertexRef(v[1]))
                            push!(face.texture_coords, textureRef(v[2]))
                        end
                    elseif length(v) == 3
                        for i=2:length(line)
                            v = split(line[i], "/") 
                            assert(length(v) == 3)
                            push!(face.vertices, vertexRef(v[1]))
                            push!(face.texture_coords, textureRef(v[2]))
                            push!(face.normals, normalRef(v[3]))
                        end
                    else
                        println("WARNING: Illegal line while parsing wavefront .obj: '$txt' (line $lineNumber)")
                        continue
                    end

                end
                push!(fcs, face)

                # add face to material, if present
                if current_material != ""
                    push!(materials[current_material], length(fcs))
                end
            # groups
            elseif line[1] == "g"
            # smoothing groups
            elseif line[1] == "s" 
            # set a new material
            elseif line[1] == "usemtl"
                current_material = line[2];
                materials[current_material] = Int[];
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

        if length(face.vertices) > 3
            triangle = Face{faceindextype}(face.vertices[1:3],[],[])
            splice!(face.vertices, 2)

            if !isempty(face.texture_coords)
                triangle.texture_coords = face.texture_coords[1:3]
                splice!(face.texture_coords, 2)
            end
            if !isempty(face.normals)
                triangle.normals = face.normals[1:3]
                splice!(face.normals, 2)
            end

            push!(fcs, triangle)
            continue
        end

        i += 1
    end

    # compile OBJ
    vs_compiled  = Vector3{vertextype}[]
    nvs_compiled = Vector3{vertextype}[]
    uvs_compiled = Vector3{vertextype}[]
    fcs_compiled = Vector3{faceindextype}[]

    i = 0
    for face in fcs
        push!(vs_compiled, vs[face.vertices[1]])
        push!(vs_compiled, vs[face.vertices[2]])
        push!(vs_compiled, vs[face.vertices[3]])

        if isempty(face.normals)
            println("WARNING: No normals!!!")
            push!(uvs_compiled, Vector3{vertextype}(0))
            push!(uvs_compiled, Vector3{vertextype}(0))
            push!(uvs_compiled, Vector3{vertextype}(0))
        else 
            push!(nvs_compiled, -nvs[face.normals[1]])
            push!(nvs_compiled, -nvs[face.normals[2]])
            push!(nvs_compiled, -nvs[face.normals[3]])
        end

        if isempty(face.texture_coords)
            push!(uvs_compiled, Vector3{vertextype}(0))
            push!(uvs_compiled, Vector3{vertextype}(0))
            push!(uvs_compiled, Vector3{vertextype}(0))
        else 
            push!(uvs_compiled, uvs[face.texture_coords[1]])
            push!(uvs_compiled, uvs[face.texture_coords[2]])
            push!(uvs_compiled, uvs[face.texture_coords[3]])
        end

        push!(fcs_compiled, Vector3{faceindextype}(faceconvertfunc(i), faceconvertfunc(i+1), faceconvertfunc(i+2)))
        i += 3
    end

    return (vs_compiled, nvs_compiled, uvs_compiled, fcs_compiled)
end

type WavefrontMTLMaterial{T}
    name::String
    Ka::Vector3{T}
end

function WavefrontMTLMaterial{T}()
    return WavefrontMTLMaterial{T}("", Vector3{T}(0))
end

function importMTL(fn::String; colortype=Float64)
    str = open(fn,"r")
    mesh = importMTL(str, colortype=colortype)
    close(str)
    return mesh
end

function importMTL(io::IO; colortype=Float64)
    materials = WavefrontMTLMaterial{colortype}[]

    lineNumber = 1
    while !eof(io)
        # read a line, remove newline and leading/trailing whitespaces
        txt = strip(chomp(readline(io)))
        assert(is_valid_ascii(txt))

        if !beginswith(txt, "#") && !isempty(txt) && !iscntrl(txt) #ignore comments
            line = split(txt)
            #vertex, 3 components only
            if line[1] == "newmtl" 
                push!(materials, WavefrontMTLMaterial{colortype}())
                materials[end].name = line[2]
            elseif line[1] == "Ka"
            elseif line[1] == "Kd"
            elseif line[1] == "Ks"
            elseif line[1] == "Tf"
            # unknown line
            else 
                println("WARNING: Unknown line while parsing wavefront .mtl: '$txt' (line $lineNumber)")
            end
        end

        # read next line
        lineNumber += 1
    end
end