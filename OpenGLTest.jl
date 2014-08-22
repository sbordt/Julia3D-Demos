using GLWindow, GLAbstraction, GLFW, ModernGL
include("obj.jl")

# Create a window and its OpenGL context
#window2 = GLFW.CreateWindow(640, 480, "GLFW.jl")

# Make the window's context current
#GLFW.MakeContextCurrent(window)

window = createwindow("Mesh Display", 1000, 1000, debugging = false)

a = importOBJ("Butterfly.obj", faceindextype=GLuint, vertextype=Float32)

# OpenGL setup
glClearColor(1,1,1,0)

# Loop until the user closes the window
while !GLFW.WindowShouldClose(window.glfwWindow)

    # Render here
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)


    yield() # this is needed for react to work

    # Swap front and back buffers
    GLFW.SwapBuffers(window.glfwWindow)

    # Poll for and process events
    GLFW.PollEvents()
end

GLFW.Terminate()

