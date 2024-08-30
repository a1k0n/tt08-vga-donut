#include <stdint.h>
#include "Vaudiotrack.h"
#include "Vaudiotrack__Syms.h"
#include "verilated.h"
#include <SDL2/SDL.h>

uint64_t samples_generated = 0;

// SDL audio callback
void audio_callback(void* userdata, uint8_t* stream, int len) {
  Vaudiotrack* top = (Vaudiotrack*) userdata;

  uint16_t *stream16 = (uint16_t*) stream;
  // Write audio samples to the stream
  for (int i = 0; i < len/2; i++) {
    // force a new sample to be generated, rather than stepping through the
    // sigma-delta modulator
    top->rootp->audiotrack__DOT__sample_div = 1023;
    top->clk48 = 0; top->eval(); top->clk48 = 1; top->eval();
    stream16[i] = top->audio_sample;
  }
  samples_generated += len;
}

int main(int argc, char** argv) {
  Verilated::commandArgs(argc, argv);

  Vaudiotrack* top = new Vaudiotrack;

  top->rst_n = 0;
  top->clk48 = 0; top->eval(); top->clk48 = 1; top->eval();
  top->rst_n = 1;

  SDL_SetHint(SDL_HINT_NO_SIGNAL_HANDLERS, "1");

  // Initialize SDL audio
  if (SDL_Init(SDL_INIT_AUDIO) < 0) {
    printf("SDL audio initialization failed: %s\n", SDL_GetError());
    return 1;
  }

  SDL_AudioSpec desiredSpec, obtainedSpec;
  desiredSpec.freq = 46875;
  desiredSpec.format = AUDIO_U16;
  desiredSpec.channels = 1;
  desiredSpec.samples = 8192;
  desiredSpec.callback = audio_callback;
  desiredSpec.userdata = (void*) top;

  SDL_AudioDeviceID audioDevice = SDL_OpenAudioDevice(NULL, 0, &desiredSpec, &obtainedSpec, 0);
  if (audioDevice == 0) {
    printf("Failed to open audio device: %s\n", SDL_GetError());
    return 1;
  }

  // Start audio playback
  SDL_PauseAudioDevice(audioDevice, 0);

  for (;;) {
    usleep(100000);
    fprintf(stderr, "\rsamples_generated: %lu\e[K", samples_generated);
    fflush(stderr);

    //if (samples_generated >= 48000 * 10) {
    //  break;
    //}
  }

  // Close audio device and quit SDL
  SDL_CloseAudioDevice(audioDevice);
  SDL_Quit();
}

