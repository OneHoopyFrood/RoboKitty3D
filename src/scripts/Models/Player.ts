import THREE, { Mesh, PerspectiveCamera } from 'three'
import { LOOK_SPEED, THIRD_PERSON_OFFSET, WALK_SPEED } from '../misc/constants'
import { Game } from './Game'
import { PointerLockControls } from './PointerLockControls'

// These are the potential kinds of movement a player can make
enum Movement {
  forward,
  backward,
  left,
  right,
  sprint,
  turnLeft,
  turnRight,
  // crouch,
  // jump,
}

type MovementStates = { [K in Movement]: boolean }

export class Player {
  body: Mesh
  camera: PerspectiveCamera

  private _controls: PointerLockControls
  private _fpCam: PerspectiveCamera
  private _tpCam: PerspectiveCamera
  private _hud: {
    crosshair: HTMLElement
  }

  // The movement indicator reflects which movement keys are currently pressed
  // This object is generated from the Movement enum where each key is paired
  // with a boolean false as the default value.
  private _movementIndicators: MovementStates = Object.fromEntries(
    Object.values(Movement).map((key) => [key, false]),
  ) as MovementStates

  private static readonly KEY_MAP: Record<string, Movement> = {
    // WASD
    w: Movement.forward,
    a: Movement.left,
    s: Movement.backward,
    d: Movement.right,
    q: Movement.turnLeft,
    e: Movement.turnRight,
    shift: Movement.sprint,

    // ARROWS
    arrowup: Movement.forward,
    arrowleft: Movement.left,
    arrowdown: Movement.backward,
    arrowright: Movement.right,
  }

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
    const movementIndicators = this._movementIndicators

    // Sprint
    const currentMoveSpeed = movementIndicators[Movement.sprint] ? 2 * WALK_SPEED : WALK_SPEED

    if (movementIndicators[Movement.forward]) {
      this._controls.moveForward(currentMoveSpeed)
    }
    if (movementIndicators[Movement.backward]) {
      this._controls.moveForward(-currentMoveSpeed)
    }
    if (movementIndicators[Movement.left]) {
      this._controls.moveRight(-currentMoveSpeed)
    }
    if (movementIndicators[Movement.right]) {
      this._controls.moveRight(currentMoveSpeed)
    }

    const turnSpeed = currentMoveSpeed * 5
    if (movementIndicators[Movement.turnLeft]) {
      this._controls.rotateH(-turnSpeed)
    }
    if (movementIndicators[Movement.turnRight]) {
      this._controls.rotateH(turnSpeed)
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
    const material = new THREE.MeshBasicMaterial({ color: 0x409883, dithering: true })
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

    // When the user clicks the window, lock the pointer into controlling the camera
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

    // Keyboard movement is based on the constants at the top of this file
    // the following code sets up key handlers to modify the movement indicators
    // when the keys are pressed
    const keyMap = Player.KEY_MAP

    const keyHandler = (event: KeyboardEvent) => {
      const key = event.key.toLowerCase()
      if (key in keyMap) {
        const action = keyMap[key]
        const value = event.type === 'keydown'
        this._movementIndicators[action] = value
      }
    }

    document.addEventListener('keydown', keyHandler, false)
    document.addEventListener('keyup', keyHandler, false)
    return controls
  }
}
