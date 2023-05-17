import * as THREE from 'three'
import { GAME_HEIGHT, GAME_WIDTH, GRID_SIZE, PLAYER_HEIGHT } from '.'
import { GridPosition } from './types/GridPosition'

export function setupRenderer() {
  const renderer = new THREE.WebGLRenderer({ antialias: true })
  renderer.setSize(GAME_WIDTH, GAME_HEIGHT)
  renderer.setClearColor(0x222222, 1)
  renderer.domElement.id = 'game'
  document.body.appendChild(renderer.domElement)
  renderer.setPixelRatio(window.devicePixelRatio)
  renderer.setSize(window.innerWidth, window.innerHeight)

  return renderer
}
export function setupPlayerFPCamera(playerBody: THREE.Mesh) {
  const camera = new THREE.PerspectiveCamera(70, GAME_WIDTH / GAME_HEIGHT)
  camera.position.copy(playerBody.position)
  // Adjust the camera to be at the player's head
  playerBody.geometry.computeBoundingBox()
  const playerBoundingBox = playerBody.geometry.boundingBox
  if (playerBoundingBox == null) throw new Error('Player body has no bounding box')
  camera.position.y = playerBoundingBox.getSize(new THREE.Vector3()).y * 0.85
  camera.near = 0.1
  camera.far = 1000
  return camera
}

// Setup the player's third-person camera
export function setupPlayerTPCamera(playerBody: THREE.Mesh) {
  const camera = new THREE.PerspectiveCamera(70, GAME_WIDTH / GAME_HEIGHT)
  camera.position.copy(playerBody.position)
  camera.position.y = 100
  camera.position.z = -50
  camera.near = 0.1
  camera.far = 1000

  camera.lookAt(playerBody.position)

  return camera
}

export function setupTopCamera() {
  const topCamera = new THREE.OrthographicCamera(-GRID_SIZE / 2, GRID_SIZE / 2, GRID_SIZE / 2, -GRID_SIZE / 2)
  topCamera.position.y = 1000
  topCamera.position.z = 0
  topCamera.rotation.x = -Math.PI / 2
  topCamera.near = 0.1
  topCamera.far = 1000
  return topCamera
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

export function setupPlayerBody(position: GridPosition) {
  // Just a tall box for now
  const geometry = new THREE.BoxGeometry(5, PLAYER_HEIGHT * 10, 5)
  const material = new THREE.MeshBasicMaterial({ color: 0x00ff00 })
  const cube = new THREE.Mesh(geometry, material)
  cube.position.x = position[0]
  cube.position.y = (PLAYER_HEIGHT * 10) / 2
  cube.position.z = position[1]

  return cube
}
