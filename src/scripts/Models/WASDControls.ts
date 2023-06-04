/**
 * A class that handles the WASD control input and issues events in the form of
 * rxjs Observables.
 */

import { Observable, distinctUntilChanged, filter, fromEvent, groupBy, map, merge, mergeAll } from 'rxjs'

export enum MovementValues {
  FORWARD = 'forward',
  BACKWARD = 'backward',
  LEFT = 'left',
  RIGHT = 'right',
  RUN = 'run',
  // CROUCH = 'crouch',
  // JUMP = 'jump',
}

type MovementCommand = [MovementValues, boolean]

export type MovementCommandState = {
  [key in MovementValues]: boolean
}

const movementKeys = {
  w: MovementValues.FORWARD,
  a: MovementValues.LEFT,
  s: MovementValues.BACKWARD,
  d: MovementValues.RIGHT,
  arrowup: MovementValues.FORWARD,
  arrowleft: MovementValues.LEFT,
  arrowdown: MovementValues.BACKWARD,
  arrowright: MovementValues.RIGHT,
  shift: MovementValues.RUN,
  // control: MovementValues.CROUCH,
  // space: MovementValues.JUMP,
}

export class WASDControls {
  constructor() {
    this.movementKeysObservable.subscribe(([movement, direction]) => {
      this._movementCommandsState = {
        ...this._movementCommandsState,
        [movement]: direction,
      }
    })
  }

  // Sets all the movement commands to false on initialization (driven by the enum)
  private _movementCommandsState: MovementCommandState = Object.values(MovementValues).reduce(
    (accumulator, command) => {
      accumulator[command] = false
      return accumulator
    },
    {} as MovementCommandState,
  )

  public get movementCommandsState(): MovementCommandState {
    return this._movementCommandsState
  }

  public get movementKeysObservable(): Observable<MovementCommand> {
    const keyDowns = fromEvent<KeyboardEvent>(document, 'keydown')
    const keyUps = fromEvent<KeyboardEvent>(document, 'keyup')

    const keyPresses = merge(keyUps, keyDowns).pipe(
      filter((e) => {
        const key = e.key.toLowerCase()
        return Object.keys(movementKeys).includes(key)
      }),
      groupBy((e) => e.key.toLowerCase()),
      map((group) => group.pipe(distinctUntilChanged((prev, curr) => prev.type === curr.type))),
      mergeAll(),
      map((e) => {
        const key = e.key.toLowerCase() as keyof typeof movementKeys
        const commandAndDirection = [movementKeys[key], e.type === 'keydown'] as MovementCommand
        return commandAndDirection
      }),
    )

    return keyPresses
  }
}
