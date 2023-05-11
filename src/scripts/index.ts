import * as THREE from 'three'
import { WebGLRenderer } from 'three'
import { AllowedSymbols, SYMBOLS, makeCube } from './makeCube'
import { setupPlayerMovement, updateCamera } from './playerMovement'

import '../styles/index.css'

const WIDTH = window.innerWidth
const HEIGHT = window.innerHeight

const CUBE_SIZE = 10
const GRID_SIZE = 500

function setupRenderer() {
  const renderer = new THREE.WebGLRenderer({ antialias: true })
  renderer.setSize(WIDTH, HEIGHT)
  renderer.setClearColor(0x222222, 1)
  renderer.domElement.id = 'game'
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
  window.addEventListener('resize', onWindowResize, false)

  return camera
}

function setupCrosshair() {
  const crosshair = document.createElement('div')
  crosshair.classList.add('crosshair')
  document.body.appendChild(crosshair)
}

function setup(): [WebGLRenderer, THREE.Scene, THREE.Camera] {
  const renderer = setupRenderer()

  const scene = new THREE.Scene()

  const ambientLight = new THREE.AmbientLight(0xffffff) // white light
  scene.add(ambientLight)

  const camera = setupCamera(renderer)

  scene.add(camera)

  // Create a GridHelper
  const gridHelper = new THREE.GridHelper(500, 100)
  scene.add(gridHelper)

  return [renderer, scene, camera]
}

/**
 * Generates a random THREE.Color
 * @returns A random color
 */
function genRandomColor() {
  const r = Math.random()
  const g = Math.random()
  const b = Math.random()
  return new THREE.Color(r, g, b)
}

/**
 * Generates a random position that will fall within the grid
 * @returns A random position between the grid bounds
 */
function genRandomPosition(mapSize: number, aproxObjectDiameter: number, alignToGrid: boolean = false): number {
  const halfMapSize = mapSize / 2 // ex: 500 / 2 = 250
  let randomPosition = Math.random() * (mapSize - aproxObjectDiameter) - halfMapSize // ex: 500 - 10 = 490, 490 * .842 = 412.18 - 250 = 162.18

  if (alignToGrid) {
    randomPosition = Math.round(randomPosition / aproxObjectDiameter) * aproxObjectDiameter // ex: 162.18 / 10 = 16.218 => 16 * 10 = 160
  }
  return randomPosition
}

function genRandomSymbol(): AllowedSymbols {
  const randomIndex = Math.floor(Math.random() * SYMBOLS.length)
  return SYMBOLS[randomIndex]
}

function generateCubes(numCubes = 100) {
  const cubes: THREE.Mesh<THREE.BoxGeometry, THREE.MeshBasicMaterial>[] = []
  // I'm using a for loop here because I want to be able to limit the number or
  // retries to something reasonable. Normally you'd use a while loop here, but
  // that TECHNICALLY has the potential to run forever.
  for (let i = 0; cubes.length < numCubes; i++) {
    if (i > numCubes * 3) {
      console.warn(`Could not generate enough cubes! Only ${cubes.length} cubes generated.`)
      break
    }

    const cube = makeCube(
      CUBE_SIZE,
      genRandomColor(),
      // Generate a random symbol within the available symbols
      genRandomSymbol(),
      genRandomPosition(GRID_SIZE, CUBE_SIZE),
      genRandomPosition(GRID_SIZE, CUBE_SIZE),
    )

    // Prevent cubes from spawning inside each other
    if (!cubes.some((c) => c.position.distanceTo(cube.position) < CUBE_SIZE * 2)) {
      cubes.push(cube)
    }
  }
  return cubes
}

function main() {
  const [renderer, scene, camera] = setup()

  // Setup player movement controls
  const cameraControls = setupPlayerMovement(camera, renderer.domElement)

  setupCrosshair()

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
