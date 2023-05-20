/**
 * @file interactions.ts
 * @description Interaction functions for the game
 */

import { Vector3 } from 'three'
import { Player } from '../Models/Player'

export type CollisionDetectorFunction = typeof detectCollision

function calculateMinimumTranslationVector(playerBox: THREE.Box3, objBox: THREE.Box3): THREE.Vector3 {
  const overlap = new Vector3(
    Math.max(0, Math.min(playerBox.max.x, objBox.max.x) - Math.max(playerBox.min.x, objBox.min.x)),
    Math.max(0, Math.min(playerBox.max.y, objBox.max.y) - Math.max(playerBox.min.y, objBox.min.y)),
    Math.max(0, Math.min(playerBox.max.z, objBox.max.z) - Math.max(playerBox.min.z, objBox.min.z)),
  )

  let minAxis: 'x' | 'y' | 'z' = 'x'
  let minOverlap = overlap.x

  if (overlap.y < minOverlap) {
    minAxis = 'y'
    minOverlap = overlap.y
  }

  if (overlap.z < minOverlap) {
    minAxis = 'z'
    minOverlap = overlap.z
  }

  const direction = playerBox.getCenter(new Vector3())[minAxis] < objBox.getCenter(new Vector3())[minAxis] ? -1 : 1

  const result = new Vector3()
  result[minAxis] = minOverlap * direction

  return result
}

export function detectCollision(player: Player, possibleCollisionObjects: THREE.Mesh[]): THREE.Vector3 | null {
  // Check for collision
  player.body.geometry.computeBoundingBox()
  const playerBox = player.body.geometry.boundingBox!.clone().applyMatrix4(player.body.matrixWorld)

  for (const obj of possibleCollisionObjects) {
    obj.geometry.computeBoundingBox()
    const objBox = obj.geometry.boundingBox!.clone().applyMatrix4(obj.matrixWorld)

    if (playerBox.intersectsBox(objBox)) {
      return calculateMinimumTranslationVector(playerBox, objBox)
    }
  }

  return null
}
