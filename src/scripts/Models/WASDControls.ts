/**
 * A class that handles the WASD control input and issues events in the form of
 * rxjs Observables.
 */

import { Observable, fromEvent, map, merge } from 'rxjs'

export type MovementCommands = {
  forward: boolean
  backward: boolean
  left: boolean
  right: boolean
  run: boolean
  crouch: boolean
}

export class WASDControls {
  private _movementCommands: MovementCommands = {
    forward: false,
    backward: false,
    left: false,
    right: false,
    run: false,
    crouch: false,
  }

  public get movementCommands(): MovementCommands {
    return this._movementCommands
  }

  public get movementKeysObservable(): Observable<MovementCommands> {
    return merge(fromEvent<KeyboardEvent>(document, 'keydown'), fromEvent<KeyboardEvent>(document, 'keyup')).pipe(
      map((event) => {
        switch (event.key.toLowerCase()) {
          case 'w':
          case 'arrowup':
            this._movementCommands.forward = event.type === 'keydown'
            break
          case 'a':
          case 'arrowleft':
            this._movementCommands.left = event.type === 'keydown'
            break
          case 's':
          case 'arrowdown':
            this._movementCommands.backward = event.type === 'keydown'
            break
          case 'd':
          case 'arrowright':
            this._movementCommands.right = event.type === 'keydown'
            break
          case 'shift':
            this._movementCommands.run = event.type === 'keydown'
            break
          case 'control':
            this._movementCommands.crouch = event.type === 'keydown'
        }
        return this._movementCommands
      }),
    )
  }
}
