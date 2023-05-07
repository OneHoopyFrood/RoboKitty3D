import * as THREE from "three"
import { makeCube } from "./makeCube"
import {
  setup as setupPlayerMovement,
  updateCameraPosition,
} from "./playerMovement"

const WIDTH = window.innerWidth
const HEIGHT = window.innerHeight

function setupRenderer() {
  const renderer = new THREE.WebGLRenderer({ antialias: true })
  renderer.setSize(WIDTH, HEIGHT)
  renderer.setClearColor(0x222222, 1)
  document.body.appendChild(renderer.domElement)
  renderer.setPixelRatio(window.devicePixelRatio)
  renderer.setSize(window.innerWidth, window.innerHeight)

  return renderer
}

function setupCamera() {
  const camera = new THREE.PerspectiveCamera(70, WIDTH / HEIGHT)
  camera.position.z = 50
  camera.position.y = 10
  camera.near = 0.1 // Set the near property to a higher value
  camera.far = 1000 // Set the far property to a higher value

  return camera
}

function setup() {
  const renderer = setupRenderer()

  const scene = new THREE.Scene()

  const camera = setupCamera()

  scene.add(camera)

  // Create a GridHelper
  const gridHelper = new THREE.GridHelper(500, 100)
  scene.add(gridHelper)

  return [renderer, scene, camera]
}

function genRandomColor() {
  const r = Math.random()
  const g = Math.random()
  const b = Math.random()
  return new THREE.Color(r, g, b)
}

function generateCubes(numCubes = 100) {
  const cubes = []
  for (let i = 0; i < numCubes; i++) {
    const cube = makeCube(
      10,
      genRandomColor(),
      Math.random() * 500 - 5 - 250,
      Math.random() * 500 - 5 - 250
    )
    cubes.push(cube)
  }
  return cubes
}

function main() {
  const [renderer, scene, camera] = setup()

  setupPlayerMovement()

  const cubes = generateCubes(30)
  cubes.forEach((cube) => scene.add(cube))

  function render(renderer, scene, camera) {
    requestAnimationFrame(() => render(renderer, scene, camera))

    updateCameraPosition(camera)

    renderer.render(scene, camera)
  }
  render(renderer, scene, camera)
}
main()
