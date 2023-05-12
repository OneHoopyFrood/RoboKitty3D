import * as THREE from 'three'
import { WebGLRenderer } from 'three'
import { CUBE_SIZE, GRID_SIZE, GridPosition, HEIGHT, WIDTH } from '.'
import { AllowedSymbols, SYMBOLS, makeCube } from './makeCube'

export function setupRenderer() {
  const renderer = new THREE.WebGLRenderer({ antialias: true })
  renderer.setSize(WIDTH, HEIGHT)
  renderer.setClearColor(0x222222, 1)
  renderer.domElement.id = 'game'
  document.body.appendChild(renderer.domElement)
  renderer.setPixelRatio(window.devicePixelRatio)
  renderer.setSize(window.innerWidth, window.innerHeight)

  return renderer
}
export function setupCamera(renderer: WebGLRenderer) {
  const camera = new THREE.PerspectiveCamera(70, WIDTH / HEIGHT)
  camera.position.z = 50
  camera.position.y = 10
  camera.near = 0.1
  camera.far = 1000
  return camera
}
/**
 * Sets up the crosshair in the center of the screen (uses html/css)
 */
export function setupCrosshair(): HTMLElement {
  const crosshair = document.createElement('div')
  crosshair.classList.add('crosshair')
  document.body.appendChild(crosshair)
  return crosshair
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
function genRandomPosition(mapSize: number, aproxObjectDiameter: number, alignToGrid: boolean = false): GridPosition {
  const halfMapSize = mapSize / 2 // ex: 500 / 2 = 250
  let randomPosition = []
  for (let i = 0; i < 2; i++) {
    randomPosition[i] = Math.random() * (mapSize - aproxObjectDiameter) - halfMapSize // ex: 500 - 10 = 490, 490 * .842 = 412.18 - 250 = 162.18

    if (alignToGrid) {
      randomPosition[i] = Math.round(randomPosition[i] / aproxObjectDiameter) * aproxObjectDiameter // ex: 162.18 / 10 = 16.218 => 16 * 10 = 160
    }
  }
  // Cast should be safe so long as the above loop isn't changed
  return randomPosition as GridPosition
}
function genRandomSymbol(): AllowedSymbols {
  const randomIndex = Math.floor(Math.random() * SYMBOLS.length)
  return SYMBOLS[randomIndex]
}
export function generateCubes(numCubes = 100) {
  const cubes: THREE.Mesh<THREE.BoxGeometry, THREE.MeshBasicMaterial>[] = []
  // I'm using a for loop here because I want to be able to limit the number or
  // retries to something reasonable. Normally you'd use a while loop here, but
  // that TECHNICALLY has the potential to run forever.
  for (let i = 0; cubes.length < numCubes; i++) {
    if (i > numCubes * 3) {
      console.warn(`Could not generate enough cubes! Only ${cubes.length} cubes generated.`)
      break
    }

    const gridPosition = genRandomPosition(GRID_SIZE, CUBE_SIZE, true)

    const cube = makeCube(
      CUBE_SIZE,
      genRandomColor(),
      // Generate a random symbol within the available symbols
      genRandomSymbol(),
      gridPosition[0],
      gridPosition[1],
    )

    // Prevent cubes from spawning inside each other
    if (!cubes.some((c) => c.position.distanceTo(cube.position) < CUBE_SIZE * 2)) {
      cubes.push(cube)
    }
  }
  return cubes
}
// Make a robot body
function makePlayer(): THREE.Mesh<THREE.BoxGeometry, THREE.MeshBasicMaterial> {
  throw new Error('Not implemented')
}
