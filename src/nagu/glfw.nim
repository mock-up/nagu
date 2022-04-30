import nimgl/glfw
from nimgl/opengl import glInit, glEnable, GL_TEXTURE_2D

proc initGlfw =
  doAssert glfw.glfwInit()
  glfw.glfwWindowHint(glfw.GLFWContextVersionMajor, 3)
  glfw.glfwWindowHint(glfw.GLFWContextVersionMinor, 3)
  glfw.glfwWindowHint(glfw.GLFWOpenglForwardCompat, glfw.GLFW_TRUE)
  glfw.glfwWindowHint(glfw.GLFWOpenglProfile, glfw.GLFW_OPENGL_CORE_PROFILE)
  glfw.glfwWindowHint(glfw.GLFWResizable, glfw.GLFW_FALSE)

proc keyProc(window: glfw.GLFWWindow, key: int32, scancode: int32, action: int32, mods: int32): void {.cdecl.} =
  if key == GLFWKey(Escape) and action == glfw.GLFWPress:
    glfw.setWindowShouldClose(window, true)

proc setup* (width, height: int32, title: string): glfw.GLFWWindow =
  ## Initializes OpenGL context and gets GLFW Window.
  initGlfw()
  result = glfw.glfwCreateWindow(width, height, title, nil, nil)
  doAssert result != nil
  discard result.setKeyCallback(keyProc)
  result.makeContextCurrent()
  doAssert glInit()
  glEnable(GL_TEXTURE_2D)

template update* (window: glfw.GLFWWindow, body: untyped) =
  ## The main-loop in GLFW Window.
  while not window.windowShouldClose:
    body
    glfwPollEvents()
    window.swapBuffers()
  window.destroyWindow()
  glfwTerminate()

export glfw
