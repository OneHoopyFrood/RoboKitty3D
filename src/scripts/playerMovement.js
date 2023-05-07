import * as THREE from "three"

// Define the keyboard state object and set initial values
const keyboard = {}
keyboard.w = false
keyboard.a = false
keyboard.s = false
keyboard.d = false
keyboard.q = false
keyboard.e = false

// This is just for optimization to prevent the needless creation of a new vector every frame
const dir = new THREE.Vector3()

const SPEED = 0.7 // Set the movement speed of the camera
const TURN_SPEED = 0.02

// Add event listeners to detect key presses and releases
export function setup() {
  document.addEventListener("keydown", (event) => {
    if (event.code === "KeyW") keyboard.w = true
    if (event.code === "KeyA") keyboard.a = true
    if (event.code === "KeyS") keyboard.s = true
    if (event.code === "KeyD") keyboard.d = true
    if (event.code === "KeyQ") keyboard.q = true
    if (event.code === "KeyE") keyboard.e = true
  })
  document.addEventListener("keyup", (event) => {
    if (event.code === "KeyW") keyboard.w = false
    if (event.code === "KeyA") keyboard.a = false
    if (event.code === "KeyS") keyboard.s = false
    if (event.code === "KeyD") keyboard.d = false
    if (event.code === "KeyQ") keyboard.q = false
    if (event.code === "KeyE") keyboard.e = false
  })
}

// Define a function to update the camera position
export function updateCameraPosition(camera) {
  if (keyboard.w) {
    // Forward
    camera.getWorldDirection(dir)
    camera.position.addScaledVector(dir, SPEED)
  }
  if (keyboard.s) {
    // Back
    camera.getWorldDirection(dir)
    camera.position.addScaledVector(dir.negate(), SPEED)
  }
  if (keyboard.a) {
    // Rotate left
    camera.rotation.y += TURN_SPEED
  }
  if (keyboard.d) {
    // Rotate right
    camera.rotation.y -= TURN_SPEED
  }
  if (keyboard.q) {
    // Strafe left
    camera.getWorldDirection(dir)
    const left = new THREE.Vector3()
    left.crossVectors(dir, camera.up).negate()
    camera.position.addScaledVector(left, SPEED)
  }
  if (keyboard.e) {
    // Strafe right
    camera.getWorldDirection(dir)
    const right = new THREE.Vector3()
    right.crossVectors(dir, camera.up)
    camera.position.addScaledVector(right, SPEED)
  }
}
