when isMainModule:
  import nagu
  import pnm
  import nimgl/opengl

  var naguContext = setup(1000, 1000, "default")

  var tex1 = Texture.make("assets/vertex/id.glsl", "assets/fragment/id.glsl")

  var img = pnm.readPPMFile("assets/sea.ppm")

  tex1.use do (texture: var BindedTexture):
    texture.pixels = (data: img.data, width: img.col, height: img.row)

  glClearColor(1.0f, 1.0f, 1.0f, 1.0f)
  naguContext.update:
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)
    tex1.use do (texture: var BindedTexture):
      texture.draw()
