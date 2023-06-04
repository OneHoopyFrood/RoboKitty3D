import { Quaternion as CannonQuaternion, Vec3 } from 'cannon-es'
import { Quaternion as ThreeQuaternion, Vector3 } from 'three'
import { HexColorString } from '../types/HexColorString'

/**
 * Generates a random position that will fall within the grid
 * @param mapSize The size of the grid
 * @returns A random position between the grid bounds
 */
export function genRandomPosition(mapSize: number, aproxObjectDiameter: number, alignToGrid: boolean = false): Vector3 {
  const halfMapSize = mapSize / 2 // ex: 500 / 2 = 250

  // Generates a random number across both the positive and negative axis but
  // stays within the bounds of the grid
  const randomNumberOnGrid = () => Math.random() * (mapSize - aproxObjectDiameter) - halfMapSize

  let randomPosition = [null, null].map(() => randomNumberOnGrid())

  if (alignToGrid) {
    randomPosition = randomPosition.map(
      // Align the lower left corner of the object to the grid
      (x) => Math.round(x / aproxObjectDiameter) * aproxObjectDiameter - aproxObjectDiameter / 2,
    )
  }

  // Cast should be safe so long as the above loop isn't changed
  return new Vector3(randomPosition[0], 0, randomPosition[1])
}

export function genRandomHexColor(): HexColorString {
  const max = 1 << 24
  const randomColor = (max + Math.floor(Math.random() * max)).toString(16).slice(-6)
  return `#${randomColor}`
}

export function Vector3toVec3(vector: Vector3): Vec3 {
  return new Vec3(vector.x, vector.y, vector.z)
}

export function Vec3toVector3(vec: Vec3): Vector3 {
  return new Vector3(vec.x, vec.y, vec.z)
}

export function CannonQuaternionToThreeQuaternion(quat: CannonQuaternion): ThreeQuaternion {
  return new ThreeQuaternion(quat.x, quat.y, quat.z, quat.w)
}

export function ThreeQuaternionToCannonQuaternion(quat: ThreeQuaternion): CannonQuaternion {
  return new CannonQuaternion(quat.x, quat.y, quat.z, quat.w)
}

export function isHexColorString(str: string): boolean {
  return /^#[0-9A-F]{6}$/i.test(str)
}
