import * as CANNON from 'cannon-es'
import { BoxGeometry, Color, LinearMipmapLinearFilter, Mesh, MeshBasicMaterial, Texture } from 'three'
import { CannonQuaternionToThreeQuaternion, Vec3toVector3, Vector3toVec3, genRandomHexColor } from '../misc/util'
import { HexColorString, isHexColorString } from '../types/HexColorString'

const SYMBOL_CANVAS_SIZE = 128 // Make sure this is a power of two

export class Cube {
  symbol: string

  emojiMode: boolean = false

  private _renderBody: Mesh<BoxGeometry>
  private _physicsBody: CANNON.Body

  private static _secretCanvas: HTMLCanvasElement = document.createElement('canvas')
  private static _symbolFontSize: number = 64
  private _bgColor: HexColorString

  private constructor(
    size: number,
    mass: number,
    symbol: string = Cube.randomSymbol(),
    color: HexColorString = genRandomHexColor(),
  ) {
    if (symbol.length !== 1) {
      throw new Error('Symbol must be a single character')
    }
    if ((color.length !== 4 && color.length !== 7) || color[0] !== '#') {
      throw new Error('Color must be a hex color string')
    }

    Cube._secretCanvas.width = SYMBOL_CANVAS_SIZE
    Cube._secretCanvas.height = SYMBOL_CANVAS_SIZE

    this.symbol = symbol

    const geometry = new BoxGeometry(size, size, size)

    this._renderBody = new Mesh(geometry)

    // Render body creation requires an async process and so it is
    // handled in the static create method

    this._physicsBody = new CANNON.Body({
      mass,
      shape: new CANNON.Box(new CANNON.Vec3(size / 2, size / 2, size / 2)),
    })
  }

  static async create(
    size: number,
    mass: number,
    symbol: string = Cube.randomSymbol(),
    color: HexColorString = genRandomHexColor(),
  ) {
    const cube = new Cube(size, mass, symbol, color)
    await cube.setColor(color)
    return cube
  }

  public getColor(): HexColorString {
    return this._bgColor
  }
  public async setColor(color: HexColorString) {
    this._bgColor = color
    const fontColor = Cube._getFontColorFromBgColor(color)
    this._renderBody.material = await Cube._genSymbolMaterial(this.symbol, fontColor, color)
  }

  public get renderBody() {
    return this._renderBody
  }

  public get physicsBody() {
    return this._physicsBody
  }

  public syncBodies() {
    this._renderBody.position.copy(Vec3toVector3(this._physicsBody.position))
    this._renderBody.quaternion.copy(CannonQuaternionToThreeQuaternion(this._physicsBody.quaternion))
  }

  public setPosition(newPosition: THREE.Vector3) {
    this._renderBody.position.copy(newPosition)
    this._physicsBody.position.copy(Vector3toVec3(newPosition))
  }

  private static _getFontColorFromBgColor(bgColor: HexColorString): HexColorString {
    // The font color should be the same as the background color, but offset in
    // brightness either up or down depending on the brightness of the background
    const target = { h: 0, s: 0, l: 0 }
    const fontColorLightnessOffset = 0.3

    const bgColorObj = new Color(bgColor)

    const fontColorLightness =
      bgColorObj.getHSL(target).l > 0.5 ? target.l - fontColorLightnessOffset : target.l + fontColorLightnessOffset
    const fontColor = `#${new Color().setHSL(target.h, target.s, fontColorLightness).getHexString()}`
    if (!isHexColorString(fontColor)) {
      throw new Error('Could not convert font color to hex string')
    }

    return fontColor
  }

  private static _canvas: HTMLCanvasElement | null = null

  /**
   *  Returns a random character from ASCII 33 to 126
   */
  public static randomSymbol(): string {
    // Pulls from the same set of characters as the terminal version
    return String.fromCharCode(Math.floor(Math.random() * 93) + 33)
  }

  private static async _genSymbolMaterial(
    symbol: string,
    fontColor: HexColorString,
    bgColor: HexColorString,
  ): Promise<MeshBasicMaterial> {
    const texture = await this._genSymbolTexture(symbol, this._symbolFontSize, fontColor, bgColor)
    const material = new MeshBasicMaterial({ map: texture })
    return material
  }

  /**
   * Creates a texture from a symbol that can be used in a Material
   */
  private static async _genSymbolTexture(
    symbol: string,
    fontSize: number,
    fontColor: HexColorString,
    backgroundColor: HexColorString,
  ): Promise<THREE.Texture> {
    this._validateSymbolGenArgs(symbol, fontSize, fontColor)

    const ctx = this._secretCanvas.getContext('2d')
    const canvas = this._secretCanvas

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

    // Wait for the image to load before returning the texture
    await new Promise((resolve) => {
      image.onload = resolve
    })

    // Create a texture from the image
    const texture = new Texture(image)
    texture.needsUpdate = true

    // Enable mipmapping
    texture.generateMipmaps = true
    texture.minFilter = LinearMipmapLinearFilter

    return texture
  }

  private static _validateSymbolGenArgs(symbol: string, fontSize: number, fontColor: string) {
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
}
