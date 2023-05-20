/**
 * This is the entry point for the game.
 * Its job is to:
 * 1. Setup all the game objects and resources
 * 2. Coordinate state
 * 3. Start the game loop
 *
 * Effectively, this module serves as a coordination point for everything in the game.
 */

import '../styles/index.css'
import { Game } from './Models/Game'

function getReady(): Game {
  const game: Game = new Game(100, document.body)
  return game
}

function getSet(game: Game): void {
  game.loadSettings()
}

function go(game: Game): void {
  // Start the game loop
  game.begin()
}

function main() {
  const game: Game = getReady()

  getSet(game)

  go(game)
}
main()
