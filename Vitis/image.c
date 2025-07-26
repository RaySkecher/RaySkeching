/* testbench_render.c
 * Build (native C simulation):
 *     gcc -std=c99 -O2 testbench_render.c trace_path.c -o render
 * Run:
 *     ./render
 * View:
 *     display render.ppm     # ImageMagick
 *     gimp render.ppm        # or any PPM‑capable viewer
 */

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

//#include "trace_path.h"

typedef struct {
    uint8_t r, g, b;
} Color;

extern Color trace_path(int x, int y);

/* Copy widths from the kernel */
#define WIDTH   256
#define HEIGHT  256
#define FRAC_BITS 12
#define ONE (1 << FRAC_BITS)


int main(void)
{
    FILE *fp = fopen("render.ppm", "w");
    if (!fp) { perror("render.ppm"); return 1; }

    /* P3 header: ascii RGB, max value 255 */
    fprintf(fp, "P3\n%d %d\n255\n", WIDTH, HEIGHT);

    /* Render top‑to‑bottom */
    for (int y = 0; y < HEIGHT; ++y)
    {
        for (int x = 0; x < WIDTH; ++x)
        {
            float r = 0;
            float g = 0;
            float b = 0;

            #define NUM_SAMPLES 1
            for (int i=0; i<NUM_SAMPLES; i++) {
                Color rgb_u8 = trace_path(x, y);

                r += (float)(rgb_u8.r) / NUM_SAMPLES;
                g += (float)(rgb_u8.g) / NUM_SAMPLES;
                b += (float)(rgb_u8.b) / NUM_SAMPLES;
            }

            fprintf(fp, "%d %d %d  ", (int)r, (int)g, (int)b);
        }
        fputc('\n', fp);
    }

    fclose(fp);
    printf("Wrote render.ppm (%dx%d)\n", WIDTH, HEIGHT);
    return 0;
}
