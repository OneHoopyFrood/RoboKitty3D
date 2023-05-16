import * as CANNON from 'cannon-es'
import * as THREE from 'three'
import { CUBE_SIZE, GRID_SIZE, GameState, GridPosition } from '.'
import { AllowedSymbols, SYMBOLS, makeCube } from './makeCube'

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
export function generateCubes(numCubes = 100): [THREE.Mesh<THREE.BoxGeometry, THREE.MeshBasicMaterial>, CANNON.Body][] {
  const cubes: [THREE.Mesh<THREE.BoxGeometry, THREE.MeshBasicMaterial>, CANNON.Body][] = []
  // I'm using a for loop here because I want to be able to limit the number or
  // retries to something reasonable. Normally you'd use a while loop here, but
  // that TECHNICALLY has the potential to run forever.
  for (let i = 0; cubes.length < numCubes; i++) {
    if (i > numCubes * 3) {
      console.warn(`Could not generate enough cubes! Only ${cubes.length} cubes generated.`)
      break
    }

    const gridPosition = genRandomPosition(GRID_SIZE, CUBE_SIZE, true)

    const cubeRenderBody = makeCube(
      CUBE_SIZE,
      genRandomColor(),
      // Generate a random symbol within the available symbols
      genRandomSymbol(),
      gridPosition[0],
      gridPosition[1],
    )

    // Prevent cubes from spawning inside each other
    if (cubes.some(([renderBody]) => renderBody.position.distanceTo(cubeRenderBody.position) < CUBE_SIZE * 2)) {
      continue
    }

    // Now setup the physics body
    const cubePhysicsBody = new CANNON.Body({
      mass: 1,
      position: new CANNON.Vec3(cubeRenderBody.position.x, cubeRenderBody.position.y, cubeRenderBody.position.z),
      // Cannon uses half extents
      shape: new CANNON.Box(new CANNON.Vec3(CUBE_SIZE / 2, CUBE_SIZE / 2, CUBE_SIZE / 2)),
    })

    cubes.push([cubeRenderBody, cubePhysicsBody])
  }
  return cubes
}

export function adaptOnWindowResize(game: GameState) {
  window.addEventListener(
    'resize',
    () => {
      game.player.fpCam.aspect = window.innerWidth / window.innerHeight
      game.player.fpCam.updateProjectionMatrix()
      game.renderer.setSize(window.innerWidth, window.innerHeight)
    },
    false,
  )
}

export function CannonVec3ToThreeVector3(cannonVec3: CANNON.Vec3): THREE.Vector3 {
  return new THREE.Vector3(cannonVec3.x, cannonVec3.y, cannonVec3.z)
}

export function CannonQuaternionToThreeQuaternion(cannonQuaternion: CANNON.Quaternion): THREE.Quaternion {
  return new THREE.Quaternion(cannonQuaternion.x, cannonQuaternion.y, cannonQuaternion.z, cannonQuaternion.w)
}

export function ThreeVector3ToCannonVec3(threeVector3: THREE.Vector3): CANNON.Vec3 {
  return new CANNON.Vec3(threeVector3.x, threeVector3.y, threeVector3.z)
}

export function ThreeQuaternionToCannonQuaternion(threeQuaternion: THREE.Quaternion): CANNON.Quaternion {
  return new CANNON.Quaternion(threeQuaternion.x, threeQuaternion.y, threeQuaternion.z, threeQuaternion.w)
}
