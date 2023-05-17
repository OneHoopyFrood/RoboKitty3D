/**
 * This is the entry point for the game.
 * Its job is to:
 * 1. Setup all the game objects and resources
 * 2. Coordinate state
 * 3. Start the game loop
 *
 * Effectively, this module serves as a coordination point for everything in the game.
 */

import * as THREE from 'three'
import { applyMovementControls, setupPlayerMovement, syncBodyToCamera } from './playerMovement'

import '../styles/index.css'
import { setupAudio } from './audio'
import { detectCollision } from './interactions'
import {
  setupCrosshair,
  setupPlayerBody,
  setupPlayerFPCamera,
  setupPlayerTPCamera,
  setupRenderer,
  setupTopCamera,
} from './setup'
import { GameState } from './types/GameState'
import { adaptOnWindowResize, allowCameraChange, enableControlInversion, generateCubes } from './util'

export const GAME_WIDTH = window.innerWidth
export const GAME_HEIGHT = window.innerHeight

export const GRID_SIZE = 1000

export const PLAYER_HEIGHT = 0.8 // meters

export const CUBE_SIZE = 10

export const THIRD_PERSON_OFFSET = new THREE.Vector3(0, 15, 30)

function getReady(): GameState {
  // Prepare the components of the game
  const renderer = setupRenderer()
  const scene = new THREE.Scene()

  const grid = new THREE.GridHelper(GRID_SIZE, (GRID_SIZE / CUBE_SIZE) * 2)

  const crosshair = setupCrosshair()

  const ambientLight = new THREE.AmbientLight(0xffffff)

  const playerRenderBody = setupPlayerBody([0, 0])
  const playerFPCamera = setupPlayerFPCamera(playerRenderBody)
  const playerTPCamera = setupPlayerTPCamera(playerRenderBody)
  const topCamera = setupTopCamera()

  const audio = setupAudio(playerFPCamera)

  const cubes = generateCubes()

  // Now add everything to the game state object
  const game: GameState = {
    renderer,
    scene,
    lights: [ambientLight],
    topCamera,
    currentCamera: playerFPCamera,
    grid,
    player: {
      body: playerRenderBody,
      fpCam: playerFPCamera,
      tpCam: playerTPCamera,
      crosshair,
      controls: setupPlayerMovement(playerFPCamera, renderer.domElement),
    },
    cubes,
  }
  return game
}

function getSet(game: GameState) {
  // Grab only what we're interested in
  const { renderer, lights, scene, player, grid, cubes } = game

  // Add all the things! (to the scene)
  lights.forEach((light) => scene.add(light))
  scene.add(grid)
  cubes.forEach((cube) => scene.add(cube))
  scene.add(player.body)
  cubes.forEach((cube) => scene.add(cube))

  adaptOnWindowResize(game)
  allowCameraChange(game)

  // TODO: Remove this in the future when we have a menu
  enableControlInversion(game)
}

function go(game: GameState) {
  // Start the game loop
  function animate(game: GameState) {
    requestAnimationFrame(() => animate(game))

    game.renderer.render(game.scene, game.currentCamera)

    applyMovementControls(game, () => detectCollision(game.player, game.cubes))

    syncBodyToCamera(game)
  }
  animate(game)
}

function main() {
  const game: GameState = getReady()

  getSet(game)

  go(game)
}
main()
