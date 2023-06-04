import * as CANNON from 'cannon-es'
import THREE, { Mesh, PerspectiveCamera, Vector3 } from 'three'
import { PLAYER_MASS, THIRD_PERSON_OFFSET, WALK_SPEED } from '../misc/constants'
import { CannonQuaternionToThreeQuaternion, Vec3toVector3, Vector3toVec3 } from '../misc/util'
import { DirectableBody } from './Directable'
import { PointerLockControls } from './PointerLockControls'
import { MovementCommandState, WASDControls } from './WASDControls'

export class Player {
  camera: PerspectiveCamera

  public get renderBody() {
    return this._renderBody
  }

  public get physicsBody() {
    return this._physicsBody
  }

  public get controls() {
    return {
      mouse: this._mouse,
      wasd: this._wasd,
    }
  }

  private _physicsBody: DirectableBody
  private _renderBody: Mesh
  private _fpCam: PerspectiveCamera
  private _tpCam: PerspectiveCamera
  private _hud: {
    crosshair: HTMLElement
  }

  private _wasd: WASDControls
  private _mouse: PointerLockControls

  constructor(domElement: HTMLElement, initialPosition: Vector3 = new Vector3(0, 0, 0)) {
    this._physicsBody = this._setupPhysicsBody(initialPosition)
    this._renderBody = this._setupRenderBody(initialPosition)

    this._fpCam = this._setupFPCamera(initialPosition)
    this._tpCam = this._setupTPCamera() // Follows the _fpCam
    this._positionTPCamera()

    this.camera = this._fpCam

    // Controls
    this._wasd = new WASDControls()
    this._mouse = new PointerLockControls(domElement)

    this._hud = {
      crosshair: this._setupCrosshair(domElement),
    }
  }

  public update() {
    this._applyMovement(this._wasd.movementCommandsState)
    this._syncRepresentations()
  }

  public switchCamera() {
    if (this.camera === this._fpCam) {
      this.camera = this._tpCam
      // this._controls.lockPitchToHorizon = true
      this._hud.crosshair.style.display = 'none'
    } else {
      this.camera = this._fpCam
      // this._controls.lockPitchToHorizon = false
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

  private _applyMovement(movementCommands: MovementCommandState) {
    const currentMoveSpeed = (movementCommands.run ? 2 * WALK_SPEED : WALK_SPEED) * 25

    // Apply force to the player's physics body based on the movement keys
    this._physicsBody.velocity.setZero()
    if (movementCommands.forward) {
      this._physicsBody.velocity.z -= currentMoveSpeed
      console.log('forward')
    }
    if (movementCommands.backward) {
      this._physicsBody.velocity.z += currentMoveSpeed
      console.log('backward')
    }
    if (movementCommands.left) {
      this._physicsBody.velocity.x -= currentMoveSpeed
      console.log('left')
    }
    if (movementCommands.right) {
      this._physicsBody.velocity.x += currentMoveSpeed
      console.log('right')
    }
  }

  private _syncRepresentations() {
    if (this._renderBody == null) throw new Error('Player renderBody must be initialized before syncing')
    if (this._physicsBody == null) throw new Error('Player physicsBody must be initialized before syncing')
    if (this._fpCam == null) throw new Error('Player _fpCam must be initialized before syncing')
    if (this._tpCam == null) throw new Error('Player _tpCam must be initialized before syncing')

    // Get the Y rotation from the _fpCam's quaternion
    // const cameraEuler = new THREE.Euler().setFromQuaternion(this._fpCam.quaternion)
    // this._renderBody.quaternion.setFromEuler(new THREE.Euler(0, cameraEuler.y, 0))

    this._renderBody.position.copy(Vec3toVector3(this._physicsBody.position))
    this._renderBody.quaternion.copy(CannonQuaternionToThreeQuaternion(this._physicsBody.quaternion))
    this._fpCam.position.copy(this._renderBody.position)
    this._positionTPCamera()
  }

  // SETUP FUNCTIONS

  private _setupPhysicsBody(initialPosition: Vector3): DirectableBody {
    const physicsRepresentation = new CANNON.Cylinder(0.5, 0.5, 10)
    const body = new DirectableBody({
      mass: PLAYER_MASS,
      position: Vector3toVec3(initialPosition),
      shape: physicsRepresentation,
    })
    // Make it kinematic so that it doesn't fall over
    body.type = CANNON.Body.KINEMATIC
    return body
  }

  private _setupRenderBody(initialPosition: Vector3) {
    const geometry = new THREE.CylinderGeometry(0.5, 0.5, 10)
    const material = new THREE.MeshBasicMaterial({ color: 0x00ff00 })
    const playerBodyRepresentation = new THREE.Mesh(geometry, material)
    playerBodyRepresentation.position.copy(initialPosition)
    return playerBodyRepresentation
  }

  private _setupFPCamera(initialPosition: Vector3) {
    if (this._renderBody == null) throw new Error('Player body must be initialized before setting up camera')
    const playerBody = this._renderBody
    const camera = new THREE.PerspectiveCamera(70, window.innerWidth / window.innerHeight)

    camera.position.copy(initialPosition)
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

  private _positionTPCamera() {
    if (this._renderBody == null) throw new Error('Player body must be initialized before setting up camera')
    if (this._tpCam == null) throw new Error('Player _tpCam must be initialized before syncing')

    const _tpCam = this._tpCam

    // This is a bit of trickery to avoid doing complicated maths.
    // Rather than recalculating the camera position as a swing around the
    // player based on the body's rotation, we just bring the camera to the
    // player's position, rotate it there, then back it up along it's local z
    // axis! The result is the same, but the code is much simpler.
    _tpCam.position.copy(this._fpCam.position)
    _tpCam.quaternion.copy(this._fpCam.quaternion)
    _tpCam.translateZ(THIRD_PERSON_OFFSET.z)
    _tpCam.translateY(THIRD_PERSON_OFFSET.y)
    _tpCam.translateX(THIRD_PERSON_OFFSET.x)
    _tpCam.lookAt(this.renderBody.position)
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
}
