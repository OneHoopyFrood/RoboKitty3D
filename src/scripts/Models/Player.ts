import THREE, { Mesh, PerspectiveCamera } from 'three'
import { LOOK_SPEED, THIRD_PERSON_OFFSET, WALK_SPEED } from '../misc/constants'
import { Game } from './Game'
import { PointerLockControls } from './PointerLockControls'

export class Player {
  body: Mesh
  camera: PerspectiveCamera

  private _fpCam: PerspectiveCamera
  private _tpCam: PerspectiveCamera
  private _hud: {
    crosshair: HTMLElement
  }
  private _movementKeys = {
    forward: false,
    backward: false,
    left: false,
    right: false,
    shift: false,
    control: false,
  }
  private _controls: PointerLockControls

  constructor(domElement: HTMLElement) {
    this.body = this._setupPlayerBody()

    this._fpCam = this._setupFPCamera()
    this._tpCam = this._setupTPCamera()
    this.camera = this._fpCam

    this._hud = {
      crosshair: this._setupCrosshair(domElement),
    }

    this._controls = this._setupMovementControls(domElement)
  }

  public update(collisionDetector: Parameters<typeof this._updateMovement>[0]) {
    this._syncBodyAndCameras()
    this._updateMovement(collisionDetector)
  }

  private _updateMovement(collisionDetector: (player: Player) => THREE.Vector3 | null) {
    // Calculate the moveSpeed based on whether the shift key is pressed or not
    const movementKeys = this._movementKeys

    // Run
    const currentMoveSpeed = movementKeys.shift ? 2 * WALK_SPEED : WALK_SPEED

    if (movementKeys.forward) {
      this._controls.moveForward(currentMoveSpeed)
    }
    if (movementKeys.backward) {
      this._controls.moveForward(-currentMoveSpeed)
    }
    if (movementKeys.left) {
      this._controls.moveRight(-currentMoveSpeed)
    }
    if (movementKeys.right) {
      this._controls.moveRight(currentMoveSpeed)
    }

    const collisionTranslation = collisionDetector(this)
    if (collisionTranslation) {
      this._fpCam.position.add(collisionTranslation)
    }
  }

  private _syncBodyAndCameras() {
    if (this.body == null) throw new Error('Player body must be initialized before syncing')
    if (this._fpCam == null) throw new Error('Player fpCam must be initialized before syncing')
    if (this._tpCam == null) throw new Error('Player tpCam must be initialized before syncing')
    const playerBody = this.body
    const fpCam = this._fpCam
    const tpCam = this._tpCam

    // Sync the player's body to the fpCam
    playerBody.position.copy(fpCam.position)

    // Get the Y rotation from the fpCam's quaternion
    const cameraEuler = new THREE.Euler().setFromQuaternion(fpCam.quaternion)
    playerBody.quaternion.setFromEuler(cameraEuler)

    // Sync the tpCam only if it's active to save on performance
    if (this.camera === tpCam) {
      // This is a bit of trickery to avoid doing complicated maths.
      // Rather than recalculating the camera position as a swing around the
      // player based on the body's rotation, we just bring the camera to the
      // player's position, rotate it there, then back it up along it's local z
      // axis! The result is the same, but the code is much simpler.
      tpCam.position.copy(fpCam.position)
      tpCam.quaternion.setFromEuler(cameraEuler)
      tpCam.translateZ(THIRD_PERSON_OFFSET.z)
      tpCam.translateY(THIRD_PERSON_OFFSET.y)
      tpCam.translateX(THIRD_PERSON_OFFSET.x)
      tpCam.lookAt(playerBody.position)
    }
  }

  public switchCamera() {
    if (this.camera === this._fpCam) {
      this.camera = this._tpCam
      this._controls.lockPitchToHorizon = true
      this._hud.crosshair.style.display = 'none'
    } else {
      this.camera = this._fpCam
      this._controls.lockPitchToHorizon = false
      this._hud.crosshair.style.display = 'block'
    }
  }

  public set cameraAspect(aspect: number) {
    this._fpCam.aspect = aspect
    this._tpCam.aspect = aspect
  }

  public updateCameraProjectionMatrix() {
    this._fpCam.updateProjectionMatrix()
    this._tpCam.updateProjectionMatrix()
  }

  public get position() {
    return this._fpCam.position
  }

  public get rotation() {
    return this._fpCam.rotation
  }

  private _setupPlayerBody() {
    const geometry = new THREE.BoxGeometry(5, 10, 5)
    const material = new THREE.MeshBasicMaterial({ color: 0x00ff00 })
    const playerBody = new THREE.Mesh(geometry, material)
    playerBody.position.x = 0
    playerBody.position.y = 0
    playerBody.position.z = 0
    return playerBody
  }

  private _setupFPCamera() {
    if (this.body == null) throw new Error('Player body must be initialized before setting up camera')
    const playerBody = this.body
    const camera = new THREE.PerspectiveCamera(70, window.innerWidth / window.innerHeight)

    camera.position.copy(playerBody.position)
    // Adjust the camera to be at the player's head
    playerBody.geometry.computeBoundingBox()
    const playerBoundingBox = playerBody.geometry.boundingBox
    if (playerBoundingBox == null) throw new Error('Player body has no bounding box') // Shouldn't be possible
    camera.position.y = playerBoundingBox.getSize(new THREE.Vector3()).y * 0.85

    camera.near = 0.1
    camera.far = 1000
    return camera
  }

  private _setupTPCamera() {
    const camera = new THREE.PerspectiveCamera(70, window.innerWidth / window.innerHeight)
    camera.near = 0.1
    camera.far = 1000
    // Position doesn't matter right now since the default is the FP camera. This'll be synced later.
    return camera
  }

  /**
   * Sets up the crosshair in the center of the screen (uses html/css)
   */
  private _setupCrosshair(domObject: HTMLElement): HTMLElement {
    const crosshair = document.createElement('div')
    crosshair.classList.add('crosshair')
    domObject.appendChild(crosshair)
    return crosshair
  }

  private _setupMovementControls(domElement: HTMLElement) {
    const controls = new PointerLockControls(this._fpCam, domElement)
    controls.invertPitch = Game.settings.get('invertPitchControl')
    // Update the settings when the user changes them
    Game.settings.onChange('invertPitchControl', (value) => (controls.invertPitch = value))
    controls.pointerSpeed = LOOK_SPEED

    const movementKeys = this._movementKeys

    domElement.addEventListener('click', () => {
      controls.lock()
      domElement.style.cursor = 'none'
    })

    // On pointer unlock, show the cursor again and fire a pause event
    document.addEventListener('pointerlockchange', (e) => {
      if (document.pointerLockElement === domElement) {
        return
      }
      domElement.style.cursor = 'default'

      const pauseEvent = new Event('Pause', { bubbles: true, cancelable: false })
      domElement.dispatchEvent(pauseEvent)
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
            movementKeys.left = true
            break
          case 's':
          case 'arrowdown':
            movementKeys.backward = true
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
            movementKeys.left = false
            break
          case 's':
          case 'arrowdown':
            movementKeys.backward = false
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
}
