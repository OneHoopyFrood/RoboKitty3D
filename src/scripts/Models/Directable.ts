/**
 * A base class for objects that can be directed by the user.
 */

import * as CANNON from 'cannon-es'

export class DirectableBody extends CANNON.Body {
  moveForward(magnitude: number) {
    this.velocity.z += magnitude
  }
  moveBackward(magnitude: number) {
    this.velocity.z -= magnitude
  }
  strafeLeft(magnitude: number) {
    this.velocity.x -= magnitude
  }
  strafeRight(magnitude: number) {
    this.velocity.x += magnitude
  }

  // lookUp: (magnitude: number) => void
  // lookDown: (magnitude: number) => void
  // lookLeft: (magnitude: number) => void
  // lookRight: (magnitude: number) => void
}
