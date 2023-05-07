import * as THREE from "three"

const WIDTH = window.innerWidth
const HEIGHT = window.innerHeight

const renderer = new THREE.WebGLRenderer({ antialias: true })
renderer.setSize(WIDTH, HEIGHT)
renderer.setClearColor(0xdddddd, 1)
document.body.appendChild(renderer.domElement)
renderer.setPixelRatio(window.devicePixelRatio)
renderer.setSize(window.innerWidth, window.innerHeight)

const scene = new THREE.Scene()

const camera = new THREE.PerspectiveCamera(70, WIDTH / HEIGHT)
camera.position.z = 50
camera.near = 0.1 // Set the near property to a higher value
camera.far = 1000 // Set the far property to a higher value
scene.add(camera)

// Create a stage
const planeGeometry = new THREE.PlaneGeometry(100, 100)
const planeMaterial = new THREE.MeshBasicMaterial({ color: "#CCC" })
const plane = new THREE.Mesh(planeGeometry, planeMaterial)

plane.rotation.x = -Math.PI / 2 // Rotate the plane so it lies flat on the ground
plane.position.y = -1 // Move the plane down 1 unit so it sits on the ground

scene.add(plane) // Add the plane to the scene

// Cube
const cubeGeometry = new THREE.BoxGeometry(1, 1, 1) // Create a cube geometry with dimensions of 1x1x1 units
const cubeMaterial = new THREE.MeshBasicMaterial({
  color: 0xff0000,
}) // Set the material to be red
const cube = new THREE.Mesh(cubeGeometry, cubeMaterial) // Create a mesh using the cube geometry and material

scene.add(cube) // Add the cube to the scene

// Define the keyboard state object and set initial values
const keyboard = {}
keyboard.w = false
keyboard.a = false
keyboard.s = false
keyboard.d = false
keyboard.q = false
keyboard.e = false

// Add event listeners to detect key presses and releases
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

const dir = new THREE.Vector3()

// Define a function to update the camera position
// Define a function to update the camera position
function updateCameraPosition() {
  const speed = 0.1 // Set the movement speed of the camera
  const angularSpeed = 0.008

  if (keyboard.w) {
    camera.getWorldDirection(dir)
    camera.position.addScaledVector(dir, speed)
  }
  if (keyboard.s) {
    camera.getWorldDirection(dir)
    camera.position.addScaledVector(dir.negate(), speed)
  }
  if (keyboard.a) {
    camera.rotation.y += angularSpeed // Rotate left
  }
  if (keyboard.d) {
    camera.rotation.y -= angularSpeed // Rotate right
  }
  if (keyboard.q) {
    camera.getWorldDirection(dir)
    const left = new THREE.Vector3()
    left.crossVectors(dir, camera.up).negate()
    camera.position.addScaledVector(left, speed)
  }
  if (keyboard.e) {
    camera.getWorldDirection(dir)
    const right = new THREE.Vector3()
    right.crossVectors(dir, camera.up)
    camera.position.addScaledVector(right, speed)
  }
}

function render() {
  requestAnimationFrame(render)

  updateCameraPosition()

  renderer.render(scene, camera)
}
render()
