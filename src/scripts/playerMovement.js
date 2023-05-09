// Import pointer lock controls
import { PointerLockControls } from "three/examples/jsm/controls/PointerLockControls.js"

const WALK_SPEED = 1.2 // Set the movement speed of the camera
const LOOK_SPEED = 0.7

const movementKeys = {
  forward: false,
  backward: false,
  left: false,
  right: false,
  shift: false,
  control: false,
}

export function setupPlayerMovement(camera, domElement) {
  const controls = new PointerLockControls(camera, domElement)
  controls.pointerSpeed = LOOK_SPEED

  // on mouse click, lock the pointer
  document.addEventListener("click", () => {
    controls.lock()
    document.body.style.cursor = "none"
  })

  // On pointer unlock, show the cursor again and fire a pause event
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
      switch (e.key.toLowerCase()) {
        case "w":
        case "arrowup":
          movementKeys.forward = true
          break
        case "a":
        case "arrowleft":
          movementKeys.backward = true
          break
        case "s":
        case "arrowdown":
          movementKeys.left = true
          break
        case "d":
        case "arrowright":
          movementKeys.right = true
          break
        // Shift to run
        case "shift":
          movementKeys.shift = true
          break
        case "control":
          movementKeys.control = true
          break
      }
    },
    false
  )
  document.addEventListener(
    "keyup",
    (e) => {
      switch (e.key.toLowerCase()) {
        case "w":
        case "arrowup":
          movementKeys.forward = false
          break
        case "a":
        case "arrowleft":
          movementKeys.backward = false
          break
        case "s":
        case "arrowdown":
          movementKeys.left = false
          break
        case "d":
        case "arrowright":
          movementKeys.right = false
          break
        case "shift":
          movementKeys.shift = false
          break
        case "control":
          movementKeys.control = false
      }
    },
    false
  )

  return controls
}

let originalY = null

export function updateCamera(controls, camera) {
  // Calculate the moveSpeed based on whether the shift key is pressed or not
  const currentMoveSpeed = movementKeys.shift ? 2 * WALK_SPEED : WALK_SPEED
  if (originalY === null) originalY = camera.position.y

  if (movementKeys.forward) {
    controls.moveForward(currentMoveSpeed)
  }
  if (movementKeys.left) {
    controls.moveForward(-currentMoveSpeed)
  }
  if (movementKeys.backward) {
    controls.moveRight(-currentMoveSpeed)
  }
  if (movementKeys.right) {
    controls.moveRight(currentMoveSpeed)
  }
  if (movementKeys.control) {
    camera.position.y = (originalY || camera.position.y) / 2
  } else if (camera.position.y !== originalY) {
    camera.position.y = originalY
  }
}
