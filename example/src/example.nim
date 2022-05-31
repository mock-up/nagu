# This is just an example to get you started. A typical binary package
# uses this file as the main entry point of the application.

when isMainModule:
  import nagu

  let naguContext = setup(1000, 1000, "default")

  var tex1 = Texture.init(100'u, 100'u)

  tex1.use do (texture: var BindedTexture):
    texture.wrapS = tRepeat
    texture.wrapT = tRepeat

  echo tex1[]

  naguContext.update:
    discard
