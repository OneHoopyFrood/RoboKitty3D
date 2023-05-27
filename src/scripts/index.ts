/**
 * This is the entry point for the game.
 */

import '../styles/index.css'
import { Game } from './Models/Game'

function main() {
  const game: Game = new Game(100, document.body)
  game.loadSettings()
  game.begin()
}
main()
