import { Observable, fromEvent, merge } from 'rxjs'
import { map } from 'rxjs/operators'

export class PointerLockControls {
  private _domElement: HTMLElement

  // Observable for movement events
  movement$: Observable<{ movementX: number; movementY: number }>

  // Observable for lock and unlock events
  lockChange$: Observable<boolean>

  // Observable that combines movement and lock/unlock events
  combined$: Observable<any>

  constructor(domElement: HTMLElement) {
    this._domElement = domElement

    // Create the movement Observable
    this.movement$ = fromEvent<MouseEvent>(document, 'mousemove').pipe(
      map((event) => ({ movementX: event.movementX, movementY: event.movementY })),
    )

    // Create the lock/unlock Observable
    this.lockChange$ = merge(
      fromEvent(document, 'pointerlockchange').pipe(map(() => this.isLocked())),
      fromEvent(document, 'pointerlockerror').pipe(map(() => false)),
    )

    // Combine the movement and lock/unlock Observables
    this.combined$ = merge(this.movement$, this.lockChange$)
  }

  // Check if pointer is currently locked
  isLocked(): boolean {
    return document.pointerLockElement === this._domElement
  }

  // Request to lock the pointer
  lock() {
    this._domElement.requestPointerLock()
  }

  // Request to unlock the pointer
  unlock() {
    document.exitPointerLock()
  }
}
