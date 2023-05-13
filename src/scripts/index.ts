/**
 * This is the entry point for the game.
 * Its job is to:
 * 1. Setup all the game objects and resources
 * 2. Coordinate state
 * 3. Start the game loop
 *
 * Effectively, this module serves as a coordination point for everything in the game.
 */

import * as CANNON from 'cannon-es'
import CannonDebugRenderer from 'cannon-es-debugger'
import * as THREE from 'three'
import { WebGLRenderer } from 'three'
import { setupPlayerMovement, updatePlayerPosition } from './playerMovement'

import { PointerLockControls } from 'three/examples/jsm/controls/PointerLockControls'
import '../styles/index.css'
import { makePlayer } from './makePlayer'
import { adaptOnWindowResize, generateCubes, setupCamera, setupCrosshair, setupRenderer, setupTopCamera } from './util'

export const WIDTH = window.innerWidth
export const HEIGHT = window.innerHeight

export const PLAYER_HEIGHT = 0.8 // meters

export const CUBE_SIZE = 10
export const GRID_SIZE = 1000

export type GridPosition = [number, number]

// Create an interface type to contain the game state
export interface GameState {
  renderer: WebGLRenderer
  scene: THREE.Scene
  physicsWorld: CANNON.World
  lights: THREE.Light[]
  topCamera: THREE.PerspectiveCamera
  grid: THREE.GridHelper
  ground: CANNON.Body
  player: {
    body: THREE.Mesh
    physicsBody: CANNON.Body
    camera: THREE.PerspectiveCamera
    position: GridPosition
    crosshair: HTMLElement
    controls: PointerLockControls
  }
  cubes: ReturnType<typeof generateCubes>
}

function getReady(): GameState {
  const renderer = setupRenderer()
  const camera = setupCamera()
  const topCamera = setupTopCamera()
  const scene = new THREE.Scene()
  const ambientLight = new THREE.AmbientLight(0xffffff) // white light
  const grid = new THREE.GridHelper(GRID_SIZE, (GRID_SIZE / CUBE_SIZE) * 2)
  const crosshair = setupCrosshair()
  const cubes = generateCubes()
  const playerBody = makePlayer([camera.position.x, camera.position.z])

  const cameraControls = setupPlayerMovement(camera, renderer.domElement)

  const game: GameState = {
    renderer,
    scene,
    physicsWorld: new CANNON.World({ gravity: new CANNON.Vec3(0, -9.82, 0) }),
    lights: [ambientLight],
    topCamera,
    grid,
    ground: new CANNON.Body({
      type: CANNON.Body.STATIC,
      shape: new CANNON.Plane(),
    }),
    player: {
      body: playerBody,
      physicsBody: new CANNON.Body({
        mass: 70,
        shape: new CANNON.Box(
          new CANNON.Vec3(
            playerBody.geometry.parameters.width,
            playerBody.geometry.parameters.height,
            playerBody.geometry.parameters.depth,
          ).scale(0.5),
        ),
      }),
      camera,
      position: [0, 0],
      crosshair,
      controls: cameraControls,
    },
    cubes,
  }

  // Rotate the ground so it's flat
  game.ground.quaternion.setFromAxisAngle(new CANNON.Vec3(1, 0, 0), -Math.PI / 2)

  // Only allow the player to rotate on the Y axis
  game.player.physicsBody.inertia.set(Infinity, 1, Infinity)
  game.player.physicsBody.invInertia.set(0, 1, 0)

  return game
}

function getSet(game: GameState) {
  // Add all the things! (to the scene)
  game.lights.forEach((light) => game.scene.add(light))
  game.scene.add(game.grid)
  game.cubes.forEach((cube) => game.scene.add(cube[0]))
  game.scene.add(game.player.body)
  game.cubes.forEach((cube) => game.scene.add(cube[0]))

  // Add all the things! Again! (to the physics scene)
  game.cubes.forEach((cube) => game.physicsWorld.addBody(cube[1]))
  game.physicsWorld.addBody(game.player.physicsBody)
  game.physicsWorld.addBody(game.ground)

  adaptOnWindowResize(game)
}

function go(game: GameState) {
  let currentCamera = game.player.camera

  document.addEventListener('keyup', (event) => {
    if (event.key === 'F2') {
      currentCamera = currentCamera === game.player.camera ? game.topCamera : game.player.camera
    }
  })

  // @ts-ignore
  const cannonDebugRenderer = new CannonDebugRenderer(game.scene, game.physicsWorld)

  // Start the game loop
  function animate(game: GameState) {
    requestAnimationFrame(() => animate(game))

    game.physicsWorld.step(1 / 60)

    game.renderer.render(game.scene, currentCamera)
    cannonDebugRenderer.update()

    updatePlayerPosition(game)
  }
  animate(game)
}

function main() {
  const game: GameState = getReady()

  getSet(game)

  go(game)
}
main()
