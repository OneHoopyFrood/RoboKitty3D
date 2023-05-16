import { Euler, EventDispatcher, Object3D, PerspectiveCamera, Vector3 } from 'three'

const _euler = new Euler(0, 0, 0, 'YXZ')
const _vector = new Vector3()

const _changeEvent = { type: 'change' }
const _lockEvent = { type: 'lock' }
const _unlockEvent = { type: 'unlock' }

const _PI_2 = Math.PI / 2

class PointerLockControls extends EventDispatcher {
  camera: PerspectiveCamera
  domElement: HTMLElement
  additionalPivotObjects?: Object3D[]
  isLocked: boolean
  minPolarAngle: number
  maxPolarAngle: number
  pointerSpeed: number
  lockPitchToHorizon: boolean
  _onMouseMove: (event: MouseEvent) => void
  _onPointerlockChange: (event: Event) => void
  _onPointerlockError: (event: Event) => void

  constructor(camera: PerspectiveCamera, domElement: HTMLElement, additionalPivotObjects?: Object3D[]) {
    super()

    this.camera = camera
    this.domElement = domElement

    this.additionalPivotObjects = additionalPivotObjects

    this.isLocked = false

    this.minPolarAngle = 0
    this.maxPolarAngle = Math.PI

    this.pointerSpeed = 1.0

    this.lockPitchToHorizon = false

    this._onMouseMove = onMouseMove.bind(this)
    this._onPointerlockChange = onPointerlockChange.bind(this)
    this._onPointerlockError = onPointerlockError.bind(this)

    this.connect()
  }

  connect() {
    this.domElement.ownerDocument.addEventListener('mousemove', this._onMouseMove)
    this.domElement.ownerDocument.addEventListener('pointerlockchange', this._onPointerlockChange)
    this.domElement.ownerDocument.addEventListener('pointerlockerror', this._onPointerlockError)
  }

  disconnect() {
    this.domElement.ownerDocument.removeEventListener('mousemove', this._onMouseMove)
    this.domElement.ownerDocument.removeEventListener('pointerlockchange', this._onPointerlockChange)
    this.domElement.ownerDocument.removeEventListener('pointerlockerror', this._onPointerlockError)
  }

  dispose() {
    this.disconnect()
  }

  getObject(): Object3D {
    return this.camera
  }

  getDirection(v: Vector3): Vector3 {
    return v.set(0, 0, -1).applyQuaternion(this.camera.quaternion)
  }

  moveForward(distance: number) {
    const camera = this.camera

    // The camera matrix is not updated if the camera isn't being rendered.
    // To solve issues with syncing other Object3Ds to the camera position, we
    // manually update the matrix here.
    camera.updateMatrix()

    _vector.setFromMatrixColumn(camera.matrix, 0)

    _vector.crossVectors(camera.up, _vector)

    camera.position.addScaledVector(_vector, distance)

    if (this.additionalPivotObjects && this.additionalPivotObjects.length > 0) {
      this.additionalPivotObjects.forEach((obj) => {
        obj.position.addScaledVector(_vector, distance)
      })
    }
  }

  moveRight(distance: number) {
    const camera = this.camera

    // See comment above in moveForward()
    camera.updateMatrix()

    _vector.setFromMatrixColumn(camera.matrix, 0)

    camera.position.addScaledVector(_vector, distance)

    if (this.additionalPivotObjects && this.additionalPivotObjects.length > 0) {
      this.additionalPivotObjects.forEach((obj) => {
        obj.position.addScaledVector(_vector, distance)
      })
    }
  }

  lock() {
    this.domElement.requestPointerLock()
  }

  unlock() {
    this.domElement.ownerDocument.exitPointerLock()
  }
}

function onMouseMove(this: PointerLockControls, event: MouseEvent) {
  if (this.isLocked === false) return

  const movementX = event.movementX || 0
  const movementY = this.lockPitchToHorizon ? 0 : event.movementY || 0

  _euler.setFromQuaternion(this.camera.quaternion)

  if (this.lockPitchToHorizon && _euler.x !== 0) _euler.x = 0

  _euler.y -= movementX * 0.002 * this.pointerSpeed
  if (!this.lockPitchToHorizon) {
    _euler.x -= movementY * 0.002 * this.pointerSpeed

    _euler.x = Math.max(_PI_2 - this.maxPolarAngle, Math.min(_PI_2 - this.minPolarAngle, _euler.x))
  }

  this.camera.quaternion.setFromEuler(_euler)

  if (this.additionalPivotObjects && this.additionalPivotObjects.length > 0) {
    const pivot = this.additionalPivotObjects[0]
    pivot.quaternion.setFromEuler(_euler)
  }

  this.dispatchEvent(_changeEvent)
}

function onPointerlockChange(this: PointerLockControls) {
  if (this.domElement.ownerDocument.pointerLockElement === this.domElement) {
    this.dispatchEvent(_lockEvent)

    this.isLocked = true
  } else {
    this.dispatchEvent(_unlockEvent)

    this.isLocked = false
  }
}

function onPointerlockError() {
  console.error('THREE.PointerLockControls: Unable to use Pointer Lock API')
}

export { PointerLockControls }
