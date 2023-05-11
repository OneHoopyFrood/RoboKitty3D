import * as THREE from 'three'

// Create one canvas and reuse it for each symbol
const canvas = document.createElement('canvas')
const SYMBOL_CANVAS_SIZE = 128 // Make sure this is a power of two
canvas.width = SYMBOL_CANVAS_SIZE
canvas.height = SYMBOL_CANVAS_SIZE
const ctx = canvas.getContext('2d')

// prettier-ignore
export const SYMBOLS: [ '!', '@', '$', '%', '&', '*', '+', '.', '/', '0', '3', '8', ';', '=', 
                        '?', 'A', 'F', 'X', 'a', 'f', 'g', 'h', 'i', 'm', 'n', 't', 'w', ] = 
                      [ '!', '@', '$', '%', '&', '*', '+', '.', '/', '0', '3', '8', ';', '=', 
                        '?', 'A', 'F', 'X', 'a', 'f', 'g', 'h', 'i', 'm', 'n', 't', 'w', ]

export type AllowedSymbols = (typeof SYMBOLS)[number]
type HexColorString = `#${string}`

function isHexColorString(str: string): str is HexColorString {
  return str.length === 4 || (str.length === 7 && str[0] === '#')
}

if (ctx === null) {
  throw new Error('Could not get canvas context for symbol texture')
}

/**
 * Creates a texture from a symbol that can be used in a Material
 */
function createSymbolTexture(
  symbol: AllowedSymbols,
  fontSize: number,
  fontColor: HexColorString,
  backgroundColor: HexColorString,
) {
  validateSymbolGenArgs(symbol, fontSize, fontColor)

  if (ctx === null) {
    throw new Error('Could not get canvas context for symbol texture')
  }

  // Clear canvas before drawing new symbol
  ctx.clearRect(0, 0, canvas.width, canvas.height)

  // Fill the canvas with a solid color
  ctx.fillStyle = backgroundColor // Set the background color
  ctx.fillRect(0, 0, canvas.width, canvas.height)

  // Draw symbol
  ctx.font = `bold ${fontSize}px Terminus, monospace, Arial, sans-serif`
  ctx.fillStyle = fontColor
  ctx.textAlign = 'center'
  ctx.textBaseline = 'middle'
  ctx.fillText(symbol, canvas.width / 2, canvas.height / 2)

  // Create an image from the canvas so that the texture won't follow the state
  // of the canvas that we're reusing
  const image = new Image()
  image.src = canvas.toDataURL()

  // Create a texture from the image
  const texture = new THREE.Texture(image)
  texture.needsUpdate = true

  // Enable mipmapping
  texture.generateMipmaps = true
  texture.minFilter = THREE.LinearMipmapLinearFilter

  return texture
}

/**
 * Just a convenience function to hold all the validation logic for the createSymbolTexture function
 */
function validateSymbolGenArgs(symbol: string, fontSize: number, fontColor: string) {
  if (symbol.length !== 1) {
    throw new Error('Symbol must be a single character')
  }
  if (fontSize > SYMBOL_CANVAS_SIZE) {
    throw new Error('Font size must be less than the canvas size')
  }
  if (fontSize <= 0) {
    throw new Error('Font size must be greater than 0')
  }
  if (fontSize % 1 !== 0) {
    throw new Error('Font size must be an integer')
  }
  if ((fontColor.length !== 4 && fontColor.length !== 7) || fontColor[0] !== '#') {
    throw new Error('Font color must be a hex color string')
  }
}

/**
 * Creates a material from a symbol that can be used in a Mesh
 */
function genSymbolMaterial(
  symbol: AllowedSymbols,
  fontColor: HexColorString,
  bgColor: HexColorString,
): THREE.MeshBasicMaterial {
  const texture = createSymbolTexture(symbol, 64, fontColor, bgColor)
  const material = new THREE.MeshBasicMaterial({ map: texture })
  return material
}

/**
 * Creates a cube with a symbol on each face
 */
export function makeCube(size: number, color: THREE.Color, symbol: AllowedSymbols, x = 0, z = 0, y = 0) {
  const backgroundColor: HexColorString = `#${color.getHexString()}`
  if (!isHexColorString(backgroundColor)) {
    throw new Error('Could not convert background color to hex string')
  }

  // The font color should be the same as the background color, but offset in
  // brightness either up or down depending on the brightness of the background
  const target = { h: 0, s: 0, l: 0 }
  const fontColorLightnessOffset = 0.3
  const fontColorLightness =
    color.getHSL(target).l > 0.5 ? target.l - fontColorLightnessOffset : target.l + fontColorLightnessOffset
  const fontColor = `#${new THREE.Color().setHSL(target.h, target.s, fontColorLightness).getHexString()}`
  if (!isHexColorString(fontColor)) {
    throw new Error('Could not convert font color to hex string')
  }

  const symbolMaterial = genSymbolMaterial(symbol, fontColor, backgroundColor)

  const cubeGeometry = new THREE.BoxGeometry(size, size, size)

  const cube = new THREE.Mesh(cubeGeometry, symbolMaterial)
  cube.position.z = z
  cube.position.x = x
  cube.position.y = y || size / 2

  return cube
}
