import * as THREE from 'three'
import { WebGLRenderer } from 'three'
import { CUBE_SIZE, GRID_SIZE } from '../misc/constants'
import { allowCameraChange, enableControlInversion } from '../misc/functionKeys'
import { detectCollision } from '../misc/interactions'
import { genRandomPosition } from '../misc/util'
import { Cube } from './Cube'
import { GameSettings } from './GameSettings'
import { Player } from './Player'

// Create an interface type to contain the game state

export class Game {
  static settings: GameSettings

  renderer: WebGLRenderer
  scene: THREE.Scene
  lights: THREE.Light[]
  currentCamera: THREE.Camera
  topCamera: THREE.OrthographicCamera
  grid: THREE.GridHelper
  player: Player
  cubes: Cube[]

  constructor(numCubes = 100, domElement: HTMLElement) {
    Game.settings = new GameSettings()

    // Run assets
    this.renderer = this._setupRenderer()
    this.scene = new THREE.Scene()

    // Game objects
    this.lights = this._letThereBeLights()
    this.topCamera = this._createTopViewCamera()
    this.grid = new THREE.GridHelper(GRID_SIZE, GRID_SIZE / CUBE_SIZE, 0x000000, 0x000000)
    this.player = new Player(domElement)
    this.cubes = this._generateCubes(numCubes)

    // Set up initial camera
    this.currentCamera = this.player.camera

    // Putting it all together
    this._bootstrap()
    this._setupFunctionKeys()
    this._listenForResize()
  }

  public loadSettings() {
    Game.settings.load()
  }

  public begin() {
    function animate(game: Game) {
      requestAnimationFrame(() => animate(game))
      game._update()
    }
    animate(this)
  }

  private _update() {
    this.player.update((player: Player) => detectCollision(player, this.cubes, 0.0001))

    this.renderer.render(this.scene, this.currentCamera)
  }

  set numCubes(numCubes: number) {
    this.cubes = this._generateCubes(numCubes)
  }

  private _setupRenderer() {
    const renderer = new THREE.WebGLRenderer({ antialias: true })
    renderer.setSize(window.innerWidth, window.innerHeight)
    renderer.setClearColor(0x222222, 1)
    renderer.domElement.id = 'game'
    document.body.appendChild(renderer.domElement)
    renderer.setPixelRatio(window.devicePixelRatio)
    renderer.setSize(window.innerWidth, window.innerHeight)

    return renderer
  }

  private _letThereBeLights(): THREE.Light<THREE.LightShadow<THREE.Camera> | undefined>[] {
    const light = new THREE.DirectionalLight(0xffffff, 1)
    light.position.set(0, 100, 0)
    light.castShadow = true
    light.shadow.camera.top = 180
    light.shadow.camera.bottom = -100
    light.shadow.camera.left = -120
    light.shadow.camera.right = 120
    this.scene.add(light)

    const ambientLight = new THREE.AmbientLight(0x404040, 1)
    this.scene.add(ambientLight)

    return [light, ambientLight]
  }

  private _setupFunctionKeys(): void {
    allowCameraChange(this)
    enableControlInversion(this)
  }

  /**
   * Adjust camera to render the scene as a square rather than following
   * screen size
   */
  private _adjustTopCameraForAspectRatio(inputCamera?: THREE.OrthographicCamera) {
    const topCamera = inputCamera || this.topCamera
    const aspect = window.innerWidth / window.innerHeight
    topCamera.left = (-GRID_SIZE * aspect) / 2
    topCamera.right = (GRID_SIZE * aspect) / 2
    topCamera.top = GRID_SIZE / 2
    topCamera.bottom = -GRID_SIZE / 2
    topCamera.updateProjectionMatrix()
  }

  private _createTopViewCamera() {
    const topCamera = new THREE.OrthographicCamera()
    topCamera.position.y = 1000
    topCamera.position.z = 0
    topCamera.rotation.x = -Math.PI / 2
    topCamera.near = 0.1
    topCamera.far = 1000
    this._adjustTopCameraForAspectRatio(topCamera)
    return topCamera
  }

  private _generateCubes(numCubes = 100): Cube[] {
    const cubes: Cube[] = []
    // I'm using a for loop here because I want to be able to limit the number or
    // retries to something reasonable. Normally you'd use a while loop here, but
    // that TECHNICALLY has the potential to run forever.
    for (let i = 0; cubes.length < numCubes; i++) {
      if (i > numCubes * 3) {
        console.warn(`Could not generate enough cubes! Only ${cubes.length} cubes generated.`)
        break
      }

      const gridPosition = genRandomPosition(GRID_SIZE, CUBE_SIZE, true)
      gridPosition.y = CUBE_SIZE / 2

      // Prevent cubes from spawning inside each other
      if (cubes.some((otherCube) => otherCube.position.distanceTo(gridPosition) < CUBE_SIZE * 2)) {
        continue
      }

      const newCube = new Cube(CUBE_SIZE)
      newCube.position.copy(gridPosition)

      cubes.push(newCube)
    }
    return cubes
  }

  private _bootstrap() {
    const scene = this.scene
    scene.add(this.grid)
    scene.add(this.player.body)
    scene.add(this.player.camera)
    this.cubes.forEach((cube) => scene.add(cube))
    this.lights.forEach((light) => scene.add(light))
    scene.add(this.topCamera)
  }

  // Adapt to window resizing
  private _listenForResize() {
    window.addEventListener(
      'resize',
      () => {
        const aspect = window.innerWidth / window.innerHeight
        this.player.cameraAspect = aspect
        this.player.updateCameraProjectionMatrix()
        this._adjustTopCameraForAspectRatio()
        this.renderer.setSize(window.innerWidth, window.innerHeight)
      },
      false,
    )
  }
}
