import * as THREE from 'three'
import { CUBE_SIZE, GRID_SIZE } from '.'
import { AllowedSymbols, SYMBOLS, makeCube } from './makeCube'
import { GameState } from './types/GameState'
import { GridPosition } from './types/GridPosition'

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
export function generateCubes(numCubes = 100): THREE.Mesh<THREE.BoxGeometry, THREE.MeshBasicMaterial>[] {
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

    const cubeRenderBody = makeCube(
      CUBE_SIZE,
      genRandomColor(),
      // Generate a random symbol within the available symbols
      genRandomSymbol(),
      gridPosition[0],
      gridPosition[1],
    )

    // Prevent cubes from spawning inside each other
    if (cubes.some((renderBody) => renderBody.position.distanceTo(cubeRenderBody.position) < CUBE_SIZE * 2)) {
      continue
    }

    cubes.push(cubeRenderBody)
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

export function allowCameraChange(game: GameState) {
  document.addEventListener('keyup', (event) => {
    if (event.key === 'F2') {
      game.currentCamera = game.topCamera
    }
    if (event.key === 'F3') {
      game.currentCamera = game.currentCamera !== game.player.fpCam ? game.player.fpCam : game.player.tpCam
    }

    // Prevent the player from looking up or down when not in first person
    if (game.currentCamera !== game.player.fpCam && game.player.controls.lockPitchToHorizon === false) {
      game.player.controls.lockPitchToHorizon = true
    } else if (game.currentCamera === game.player.fpCam && game.player.controls.lockPitchToHorizon === true) {
      game.player.controls.lockPitchToHorizon = false
    }
  })
}

// TEMPORARY
export function enableControlInversion(game: GameState) {
  // Load the setting from local storage
  try {
    const invertPitch: boolean = localStorage.getItem('invertPitch') === 'true' || false
    game.player.controls.invertPitch = invertPitch
  } catch (error) {
    console.warn('Something went wrong while loading the invertPitch setting from local storage.')
    localStorage.setItem('invertPitch', 'false')
  }

  document.addEventListener('keyup', (event) => {
    if (event.key === 'F4') {
      game.player.controls.invertPitch = !game.player.controls.invertPitch
      // Save this setting to local storage
      localStorage.setItem('invertPitch', game.player.controls.invertPitch.toString())
    }
  })
}
