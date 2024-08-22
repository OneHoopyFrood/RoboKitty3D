import { Game } from '../Models/Game'

export function allowCameraChange(game: Game) {
  document.addEventListener('keyup', (event) => {
    if (event.key === 'F2') {
      game.player.resetView()
      game.player.resetView()
      game.currentCamera = game.topCamera
    }
    if (event.key === 'F3') {
      game.player.switchCamera()
      game.currentCamera = game.player.camera
    }
  })
}

// TEMPORARY
export function enableControlInversion(game: Game) {
  const player = game.player

  document.addEventListener('keyup', (event) => {
    if (event.key === 'F4') {
      Game.settings.set('invertPitchControl', !Game.settings.get('invertPitchControl'))
    }
  })
}
