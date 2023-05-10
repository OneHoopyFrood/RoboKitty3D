import * as THREE from "three"
import { WebGLRenderer } from "three"
import { makeCube } from "./makeCube"
import { setupPlayerMovement, updateCamera } from "./playerMovement"

import "../styles/index.css"

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

function setupCamera(renderer: WebGLRenderer) {
  const camera = new THREE.PerspectiveCamera(70, WIDTH / HEIGHT)
  camera.position.z = 50
  camera.position.y = 10
  camera.near = 0.1
  camera.far = 1000

  function onWindowResize() {
    camera.aspect = window.innerWidth / window.innerHeight
    camera.updateProjectionMatrix()
    renderer.setSize(window.innerWidth, window.innerHeight)
  }
  window.addEventListener("resize", onWindowResize, false)

  return camera
}

function setup(): [WebGLRenderer, THREE.Scene, THREE.Camera] {
  const renderer = setupRenderer()

  const scene = new THREE.Scene()

  const camera = setupCamera(renderer)

  scene.add(camera)

  // Create a GridHelper
  const gridHelper = new THREE.GridHelper(500, 100)
  scene.add(gridHelper)

  return [renderer, scene, camera ]
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

  // Setup player movement controls
  const cameraControls = setupPlayerMovement(camera, renderer.domElement)

  // Populate some cubes, yo
  const cubes = generateCubes(30)
  cubes.forEach((cube) => scene.add(cube))

  function render(renderer: THREE.WebGLRenderer, scene: THREE.Scene, camera: THREE.Camera) {
    requestAnimationFrame(() => render(renderer, scene, camera))

    renderer.render(scene, camera)
    updateCamera(cameraControls, camera)
  }
  render(renderer, scene, camera)
}
main()