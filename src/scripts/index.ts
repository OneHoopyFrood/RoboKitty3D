/**
 * This is the entry point for the game.
 */

import '../styles/index.css'
import { Game } from './Models/Game'

async function main() {
  const game: Game = await Game.create(100, document.body)
  game.loadSettings()
  game.begin()
}
main()
