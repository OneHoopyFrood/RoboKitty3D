// Import pointer lock controls
import * as THREE from 'three'
import { GameState, THIRD_PERSON_OFFSET } from '.'
import { PointerLockControls } from './PointerLockControls'

const WALK_SPEED = 1.2 // Set the movement speed of the camera
const LOOK_SPEED = 0.7

const movementKeys = {
  forward: false,
  backward: false,
  left: false,
  right: false,
  shift: false,
  control: false,
}

export function setupPlayerMovement(camera: THREE.PerspectiveCamera, domElement: HTMLElement) {
  const controls = new PointerLockControls(camera, domElement)
  controls.pointerSpeed = LOOK_SPEED

  // on mouse click, lock the pointer
  document.addEventListener('click', () => {
    controls.lock()
    document.body.style.cursor = 'none'
  })

  // On pointer unlock, show the cursor again and fire a pause event
  document.addEventListener('pointerlockchange', (e) => {
    if (document.pointerLockElement === domElement) {
      return
    }
    document.body.style.cursor = 'default'

    const pauseEvent = new Event('Pause', { bubbles: true, cancelable: false })
    document.dispatchEvent(pauseEvent)
  })

  // setup keypress events
  document.addEventListener(
    'keydown',
    (e) => {
      switch (e.key.toLowerCase()) {
        case 'w':
        case 'arrowup':
          movementKeys.forward = true
          break
        case 'a':
        case 'arrowleft':
          movementKeys.backward = true
          break
        case 's':
        case 'arrowdown':
          movementKeys.left = true
          break
        case 'd':
        case 'arrowright':
          movementKeys.right = true
          break
        // Shift to run
        case 'shift':
          movementKeys.shift = true
          break
        case 'control':
          movementKeys.control = true
          break
      }
    },
    false,
  )
  document.addEventListener(
    'keyup',
    (e) => {
      switch (e.key.toLowerCase()) {
        case 'w':
        case 'arrowup':
          movementKeys.forward = false
          break
        case 'a':
        case 'arrowleft':
          movementKeys.backward = false
          break
        case 's':
        case 'arrowdown':
          movementKeys.left = false
          break
        case 'd':
        case 'arrowright':
          movementKeys.right = false
          break
        case 'shift':
          movementKeys.shift = false
          break
        case 'control':
          movementKeys.control = false
      }
    },
    false,
  )

  return controls
}

export function applyMovementControls(game: GameState) {
  const { player } = game

  // Calculate the moveSpeed based on whether the shift key is pressed or not
  const currentMoveSpeed = movementKeys.shift ? 2 * WALK_SPEED : WALK_SPEED
  if (movementKeys.forward) {
    game.player.controls.moveForward(currentMoveSpeed)
  }
  if (movementKeys.left) {
    game.player.controls.moveForward(-currentMoveSpeed)
  }
  if (movementKeys.backward) {
    game.player.controls.moveRight(-currentMoveSpeed)
  }
  if (movementKeys.right) {
    game.player.controls.moveRight(currentMoveSpeed)
  }
}

export function syncBodyToCamera(game: GameState) {
  const { player } = game

  // Sync the player's body to the fpCam
  player.body.position.copy(player.fpCam.position)

  // Get the Y rotation from the fpCam's quaternion
  const cameraEuler = new THREE.Euler().setFromQuaternion(player.fpCam.quaternion)
  player.body.quaternion.setFromEuler(cameraEuler)

  // Sync the tpCam to the fpCam if it's active
  if (game.currentCamera === player.tpCam) {
    // This camera is is a bit more complicated. We want the camera to swing about
    // the player's position while maintaining a constant distance from the
    // player, as if flying around the player on a selfie-stick attached to
    // their back.
    // To accomplish this we'll first set the position of the camera directly
    // to the player's position, then we'll apply an offset to the camera.

    // Copy position of the fpCam
    player.tpCam.position.copy(player.fpCam.position)

    // Copy the rotation of the fpCam
    player.tpCam.quaternion.setFromEuler(cameraEuler)

    // Now fly out behind the player using the THIRD_PERSON_OFFSET
    player.tpCam.translateZ(THIRD_PERSON_OFFSET.z)
    player.tpCam.translateY(THIRD_PERSON_OFFSET.y)
    player.tpCam.translateX(THIRD_PERSON_OFFSET.x)

    // Look at the player's position
    player.tpCam.lookAt(player.body.position)
  }
}
