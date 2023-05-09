import * as THREE from "three"

export function makeCube(size: number, color: THREE.Color, x = 0, z = 0, y = 0) {
  const cubeGeometry = new THREE.BoxGeometry(size, size, size) // Create a cube geometry with dimensions of 1x1x1 units
  const cubeMaterial = new THREE.MeshBasicMaterial({
    color,
  }) // Set the material to be red
  const cube = new THREE.Mesh(cubeGeometry, cubeMaterial) // Create a mesh using the cube geometry and material
  cube.position.z = z
  cube.position.x = x
  cube.position.y = y || size / 2

  return cube
}
