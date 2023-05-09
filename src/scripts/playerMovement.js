// Import pointer lock controls
import { PointerLockControls } from "three/examples/jsm/controls/PointerLockControls.js"

const WALK_SPEED = 1.2 // Set the movement speed of the camera
const LOOK_SPEED = 0.7

const direction = {
  forward: false,
  backward: false,
  left: false,
  right: false,
}

export function setupFPS(camera, domElement) {
  const controls = new PointerLockControls(camera, domElement)
  controls.pointerSpeed = LOOK_SPEED

  // on mouse click, lock the pointer
  document.addEventListener("click", () => {
    controls.lock()
    document.body.style.cursor = "none"
  })

  document.addEventListener("pointerlockchange", (e) => {
    if (document.pointerLockElement === domElement) {
      return
    }
    document.body.style.cursor = "default"

    const pauseEvent = new Event("Pause", { bubbles: true, cancelable: false })
    document.dispatchEvent(pauseEvent)
  })

  // setup keypress events
  document.addEventListener(
    "keydown",
    (e) => {
      switch (e.key) {
        case "w":
        case "ArrowUp":
          direction.forward = true
          break
        case "a":
        case "ArrowLeft":
          direction.backward = true
          break
        case "s":
        case "ArrowDown":
          direction.left = true
          break
        case "d":
        case "ArrowRight":
          direction.right = true
          break
      }
    },
    false
  )
  // setup keyup events
  document.addEventListener(
    "keyup",
    (e) => {
      switch (e.key) {
        case "w":
        case "ArrowUp":
          direction.forward = false
          break
        case "a":
        case "ArrowLeft":
          direction.backward = false
          break
        case "s":
        case "ArrowDown":
          direction.left = false
          break
        case "d":
        case "ArrowRight":
          direction.right = false
          break
      }
    },
    false
  )

  return controls
}

export function updateFPS(controls) {
  if (direction.forward) {
    controls.moveForward(WALK_SPEED)
  }
  if (direction.left) {
    controls.moveForward(-WALK_SPEED)
  }
  if (direction.backward) {
    controls.moveRight(-WALK_SPEED)
  }
  if (direction.right) {
    controls.moveRight(WALK_SPEED)
  }
}
