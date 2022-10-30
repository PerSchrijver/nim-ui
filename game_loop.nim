#!/home/per/.nimble/bin/nim r
import sdl2
import sdl2/ttf

# import std/tables
# import std/sequtils
# import std/sugar
# import std/strutils

import sdl_stuff

import ui_objects
import globals

import os

proc draw(globals: Globals, renderer: RendererPtr, font: FontPtr, dt: float32) =
  # Background
  renderer.setDrawColor 8, 21, 27, 255 # dark cyaan
  renderer.clear()


proc handleInput(globals: var Globals, input: Input) =
  if input.kind == None:
    return
  if input.kind == InputKind.Keydown and input.is_ascii == false and input.mod_ctrl and input.scancode == Scancode.SDL_SCANCODE_C:
    globals.running = false
  echo $input


proc main =
  let WIDTH: cint = if existsEnv("WSL_INTEROP"): 2560 else: 1920
  let HEIGHT: cint = if existsEnv("WSL_INTEROP"): 1440 else: 1023
  var globals = Globals(running: true, width: WIDTH, height: HEIGHT)

  # SDL Stuff
  sdlFailIf(not sdl2.init(INIT_VIDEO or INIT_TIMER or INIT_EVENTS)):
    "SDL2 initialization failed"
  defer: sdl2.quit()

  let window = createWindow(
    title = "Gebruik de pijltjes",
    x = SDL_WINDOWPOS_CENTERED,
    y = SDL_WINDOWPOS_CENTERED,
    w = globals.width,
    h = globals.height,
    flags = SDL_WINDOW_SHOWN or SDL_WINDOW_MAXIMIZED or SDL_WINDOW_BORDERLESS or SDL_WINDOW_RESIZABLE
  )

  sdlFailIf window.isNil: "window could not be created"
  defer: window.destroy()

  let renderer = createRenderer(
    window = window,
    index = -1,
    flags = Renderer_Accelerated or Renderer_PresentVsync or Renderer_TargetTexture
  )
  sdlFailIf renderer.isNil: "renderer could not be created"
  defer: renderer.destroy()

  sdlFailIf(not ttfInit()): "SDL_TTF initialization failed"
  defer: ttfQuit()

  let myRoot = initMyRoot(globals, renderer)

  # Setup font
  let font = ttf.openFont("Hack Regular Nerd Font Complete.ttf", 16)
  sdlFailIf font.isNil: "font could not be created"

  # Gameloop variables
  var
    dt: float32

    counter: uint64
    previousCounter: uint64


  # Start gameloop
  counter = getPerformanceCounter()
  while globals.running:
    previousCounter = counter
    counter = getPerformanceCounter()

    dt = (counter - previousCounter).float / getPerformanceFrequency().float

    var event = defaultEvent

    while pollEvent(event):
      case event.kind
      of QuitEvent:
        globals.running = false
        break

      of TextInput:
        let c = event.evTextInput.text[0]
        echo "TextInput"
        globals.handleInput(toInput(c, getModState()))

      of EventType.KeyDown:
        echo "Keydown"
        globals.handleInput(toInput(event.evKeyboard.keysym.scancode, cast[
            Keymod](event.evKeyboard.keysym.modstate)))

      else:
        discard

    globals.draw(renderer, font, dt)
    myRoot.draw(globals, Pos(x: 0, y: 0), renderer)
    renderer.present()

main()
