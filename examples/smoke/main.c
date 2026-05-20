#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>

#include <SDL.h>
#include <SDL_image.h>
#include <SDL_ttf.h>

static bool env_path_exists(const char *name, const char **out) {
    const char *value = getenv(name);
    if (value == NULL || value[0] == '\0') {
        return false;
    }
    SDL_RWops *rw = SDL_RWFromFile(value, "rb");
    if (rw == NULL) {
        fprintf(stderr, "%s=%s is not readable: %s\n", name, value, SDL_GetError());
        return false;
    }
    SDL_RWclose(rw);
    *out = value;
    return true;
}

int main(int argc, char **argv) {
    (void)argc;
    (void)argv;

    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_TIMER) != 0) {
        fprintf(stderr, "SDL_Init failed: %s\n", SDL_GetError());
        return 1;
    }

    if (TTF_Init() != 0) {
        fprintf(stderr, "TTF_Init failed: %s\n", TTF_GetError());
        SDL_Quit();
        return 1;
    }

    int image_flags = IMG_INIT_JPG | IMG_INIT_PNG;
    int image_ready = IMG_Init(image_flags);
    if ((image_ready & image_flags) != image_flags) {
        fprintf(stderr, "IMG_Init partial failure: %s\n", IMG_GetError());
    }

    const char *driver = SDL_GetCurrentVideoDriver();
    printf("mlp1-smoke: video_driver=%s\n", driver != NULL ? driver : "(none)");

    SDL_Window *window = SDL_CreateWindow(
        "MLP1 smoke",
        SDL_WINDOWPOS_UNDEFINED,
        SDL_WINDOWPOS_UNDEFINED,
        640,
        480,
        SDL_WINDOW_SHOWN);
    if (window == NULL) {
        fprintf(stderr, "SDL_CreateWindow failed: %s\n", SDL_GetError());
        IMG_Quit();
        TTF_Quit();
        SDL_Quit();
        return 1;
    }

    SDL_Renderer *renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);
    if (renderer == NULL) {
        fprintf(stderr, "accelerated renderer failed: %s\n", SDL_GetError());
        renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_SOFTWARE);
    }
    if (renderer == NULL) {
        fprintf(stderr, "SDL_CreateRenderer failed: %s\n", SDL_GetError());
        SDL_DestroyWindow(window);
        IMG_Quit();
        TTF_Quit();
        SDL_Quit();
        return 1;
    }

    const char *font_path = NULL;
    TTF_Font *font = NULL;
    if (env_path_exists("MLP1_SMOKE_FONT", &font_path)) {
        font = TTF_OpenFont(font_path, 24);
        printf("mlp1-smoke: font=%s status=%s\n", font_path, font != NULL ? "loaded" : TTF_GetError());
    }

    const char *image_path = NULL;
    SDL_Texture *image = NULL;
    if (env_path_exists("MLP1_SMOKE_IMAGE", &image_path)) {
        image = IMG_LoadTexture(renderer, image_path);
        printf("mlp1-smoke: image=%s status=%s\n", image_path, image != NULL ? "loaded" : IMG_GetError());
    }

    for (int frame = 0; frame < 90; frame++) {
        SDL_Event event;
        while (SDL_PollEvent(&event)) {
            if (event.type == SDL_QUIT) {
                frame = 90;
                break;
            }
        }

        SDL_SetRenderDrawColor(renderer, 16, 20, 24, 255);
        SDL_RenderClear(renderer);

        SDL_Rect rect = {80 + (frame % 120), 80, 180, 120};
        SDL_SetRenderDrawColor(renderer, 70, 180, 140, 255);
        SDL_RenderFillRect(renderer, &rect);

        if (image != NULL) {
            SDL_Rect dst = {320, 80, 160, 160};
            SDL_RenderCopy(renderer, image, NULL, &dst);
        }

        if (font != NULL) {
            SDL_Color color = {240, 240, 240, 255};
            SDL_Surface *surface = TTF_RenderUTF8_Blended(font, "MLP1 smoke", color);
            if (surface != NULL) {
                SDL_Texture *text = SDL_CreateTextureFromSurface(renderer, surface);
                if (text != NULL) {
                    SDL_Rect dst = {80, 240, surface->w, surface->h};
                    SDL_RenderCopy(renderer, text, NULL, &dst);
                    SDL_DestroyTexture(text);
                }
                SDL_FreeSurface(surface);
            }
        }

        SDL_RenderPresent(renderer);
        SDL_Delay(16);
    }

    if (image != NULL) {
        SDL_DestroyTexture(image);
    }
    if (font != NULL) {
        TTF_CloseFont(font);
    }
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    IMG_Quit();
    TTF_Quit();
    SDL_Quit();

    printf("mlp1-smoke: ok\n");
    return 0;
}

