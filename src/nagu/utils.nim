template debugOpenGLStatement* (body: untyped): untyped =
  when defined(debuggingOpenGL):
    body