import * as THREE from 'three'
import { WebGLRenderer } from 'three'
import { PointerLockControls } from '../PointerLockControls'
import { generateCubes } from '../util'

// Create an interface type to contain the game state

export interface GameState {
  renderer: WebGLRenderer
  scene: THREE.Scene
  lights: THREE.Light[]
  currentCamera: THREE.Camera
  topCamera: THREE.OrthographicCamera
  grid: THREE.GridHelper
  player: {
    body: THREE.Mesh
    fpCam: THREE.PerspectiveCamera
    tpCam: THREE.PerspectiveCamera
    crosshair: HTMLElement
    controls: PointerLockControls
  }
  cubes: ReturnType<typeof generateCubes>
}
