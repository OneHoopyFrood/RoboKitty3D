/**
 * @fileoverview
 * This file contains the audio setup for the game. (SFX and BGM)
 */

import { Audio, AudioListener, AudioLoader, Camera } from 'three'

export function setupAudio(camera: Camera) {
  // create an AudioListener and add it to the camera
  const listener = new AudioListener()
  camera.add(listener)

  // create a global audio source
  const sound = new Audio(listener)

  // load a sound and set it as the Audio object's buffer
  const audioLoader = new AudioLoader()
  audioLoader.load('assets/Nostalgium BGM.ogg', function (buffer) {
    sound.setBuffer(buffer)
    sound.setLoop(true)
    sound.setVolume(0.5)
    sound.play()
  })
}
