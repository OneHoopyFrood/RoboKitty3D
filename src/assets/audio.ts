/**
 * @fileoverview
 * This file contains the audio setup for the game. (SFX and BGM)
 */

<<<<<<<< HEAD:src/assets/audio.ts
// create an AudioListener and add it to the camera
//const listener = new THREE.AudioListener();
//camera.add( listener );

// create a global audio source
//const sound = new THREE.Audio( listener );

// load a sound and set it as the Audio object's buffer
//const audioLoader = new THREE.AudioLoader();
//audioLoader.load( 'Nostalgium BGM.ogg', function( buffer ) {
//	sound.setBuffer( buffer );
//	sound.setLoop( true );
//	sound.setVolume( 0.5 );
//	sound.play();
//});
========
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
>>>>>>>> a1cc44b (Phixd it):src/scripts/audio.ts
