import THREE from 'three'
import { GridPosition, PLAYER_HEIGHT } from '.'

export function makePlayer(position: GridPosition) {
  // Just a tall box for now
  const geometry = new THREE.BoxGeometry(5, PLAYER_HEIGHT * 10, 5)
  const material = new THREE.MeshBasicMaterial({ color: 0x00ff00 })
  const cube = new THREE.Mesh(geometry, material)
  cube.position.x = position[0]
  cube.position.z = position[1]
  cube.position.y = (PLAYER_HEIGHT * 10) / 2
  return cube
}
