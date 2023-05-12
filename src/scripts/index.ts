import * as THREE from 'three'
import { WebGLRenderer } from 'three'
import { setupPlayerMovement, updateCamera } from './playerMovement'

import { PointerLockControls } from 'three/examples/jsm/controls/PointerLockControls'
import '../styles/index.css'
import { generateCubes, setupCamera, setupCrosshair, setupRenderer } from './util'

export const WIDTH = window.innerWidth
export const HEIGHT = window.innerHeight

export const CUBE_SIZE = 10
export const GRID_SIZE = 1000

export type GridPosition = [number, number]

// Create an interface type to contain the game state
export interface GameState {
  renderer: WebGLRenderer
  scene: THREE.Scene
  lights: THREE.Light[]
  grid: THREE.GridHelper
  player: {
    // body: THREE.Mesh
    camera: THREE.PerspectiveCamera
    position: GridPosition
    crosshair: HTMLElement
    controls: PointerLockControls
  }
  cubes: THREE.Mesh[]
}

function getReady(): GameState {
  const renderer = setupRenderer()
  const camera = setupCamera(renderer)
  const scene = new THREE.Scene()
  const ambientLight = new THREE.AmbientLight(0xffffff) // white light
  const grid = new THREE.GridHelper(GRID_SIZE, GRID_SIZE / CUBE_SIZE)
  const crosshair = setupCrosshair()
  const cubes = generateCubes()

  const cameraControls = setupPlayerMovement(camera, renderer.domElement)

  const game: GameState = {
    renderer,
    scene,
    lights: [ambientLight],
    grid,
    player: {
      // body: makePlayer(),
      camera,
      position: [0, 0],
      crosshair,
      controls: cameraControls,
    },
    cubes,
  }
  return game
}

function getSet(game: GameState) {
  // Add all the things! (to the scene)
  game.lights.forEach((light) => game.scene.add(light))
  game.scene.add(game.grid)
  game.cubes.forEach((cube) => game.scene.add(cube))
  // TODO: Give the player corporeal form 🧙🏻‍♂️
  // game.scene.add(game.player.body)

  // Adapt to window resizing
  window.addEventListener(
    'resize',
    () => {
      game.player.camera.aspect = window.innerWidth / window.innerHeight
      game.player.camera.updateProjectionMatrix()
      game.renderer.setSize(window.innerWidth, window.innerHeight)
    },
    false,
  )

  // Setup player movement controls

  game.cubes.forEach((cube) => game.scene.add(cube))
}

function go(game: GameState) {
  // Start the game loop
  function animate(game: GameState) {
    requestAnimationFrame(() => animate(game))

    game.renderer.render(game.scene, game.player.camera)
    updateCamera(game.player.controls, game.player.camera)
  }
  animate(game)
}

function main() {
  const game: GameState = getReady()

  getSet(game)

  go(game)
}
main()
