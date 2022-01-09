#include <stdio.h>
#include <stdlib.h>
#include <allegro5/allegro.h>
#include <allegro5/allegro_image.h>

#define DISP_WIDTH 800
#define DISP_HEIGHT 600
#define BM_DECIMAL_VAL 19778

extern void bilinear_interpolation(void *pixel_array, int width, int height, void *scaled_pixel_array_buffer, int scaled_bmp_width, int scaled_bmp_height);

int main(int argc, char* argv[]) {

    if (argc != 2){
        printf("usage: ./test <example.bmp>\n");
        return -1;
    }
    FILE *fp;
    fp = fopen(argv[1], "rb");

    if (fp == NULL){
        printf("file read error\n");
        return -1;
    }
    short header_field;
    fread(&header_field, 2, 1, fp);
    if (header_field != BM_DECIMAL_VAL) {
        printf("not a valid .bmp file");
        return -1;
    }
    unsigned int bmp_size, bmp_width, bmp_height, offset;

    fread(&bmp_size, 4, 1, fp);

    fseek(fp, 10, SEEK_SET);
    fread(&offset, 4, 1, fp);

    fseek(fp, 18, SEEK_SET);
    fread(&bmp_width, 4, 1, fp);
    fread(&bmp_height, 4, 1, fp);
    void* pixel_array = malloc(bmp_size - offset);

    fseek(fp, offset, SEEK_SET);
    fread(pixel_array, 1, bmp_size - offset, fp);
    fclose(fp);

    if(!al_init()) {
        printf("failed to initialize allegro\n");
        return -1;
    }
   
    ALLEGRO_DISPLAY* display = al_create_display(DISP_WIDTH, DISP_HEIGHT);

    if(!display) {
        printf("failed to create display\n");
        return -1;
    }
    ALLEGRO_EVENT_QUEUE *event_queue = al_create_event_queue();
    al_install_keyboard();
    al_init_image_addon();

    al_register_event_source(event_queue, al_get_keyboard_event_source());
    al_register_event_source(event_queue, al_get_display_event_source(display));

    al_clear_to_color(al_map_rgb(0, 0, 0));
    
    ALLEGRO_BITMAP *image = al_load_bitmap(argv[1]);
    al_draw_bitmap(image, 0, 0, 0);
    al_flip_display();
    bool exit = false;
    int scaled_bmp_width = bmp_width;
    int scaled_bmp_height = bmp_height;

    while (exit == false) {
        ALLEGRO_EVENT event;
        al_wait_for_event(event_queue, &event);

        if (event.type == ALLEGRO_EVENT_KEY_DOWN) {
            switch(event.keyboard.keycode) {
                case ALLEGRO_KEY_DOWN:
                    scaled_bmp_height += 25;
                    if (scaled_bmp_height > DISP_HEIGHT){
                        scaled_bmp_height = DISP_HEIGHT;
                    } 
                    break;
                case ALLEGRO_KEY_UP:
                    scaled_bmp_height -= 25;
                    if (scaled_bmp_height <= 0){
                        scaled_bmp_height = 1;
                    } 
                    break;
                case ALLEGRO_KEY_RIGHT:
                    scaled_bmp_width += 25;
                    if (scaled_bmp_width > DISP_WIDTH){
                        scaled_bmp_width = DISP_WIDTH;
                    }
                    break;
                case ALLEGRO_KEY_LEFT:
                    scaled_bmp_width -= 25;
                    if (scaled_bmp_width <= 0) {
                        scaled_bmp_width = 1;
                    }
                    break;
            
            }
            int scaled_pixel_array_size = (3 * scaled_bmp_width + scaled_bmp_width % 4) * scaled_bmp_height;
            void *scaled_pixel_array = malloc(scaled_pixel_array_size);

            unsigned char bmpfileheader[14] = {'B','M', 0, 0, 0, 0, 0, 0, 0, 0, 54, 0, 0, 0};
            unsigned char bmpinfoheader[40] = {40, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 24, 0};

            bmpfileheader[2] = (unsigned char)(scaled_pixel_array_size);
            bmpfileheader[3] = (unsigned char)(scaled_pixel_array_size>>8);
            bmpfileheader[4] = (unsigned char)(scaled_pixel_array_size>>16);
            bmpfileheader[5] = (unsigned char)(scaled_pixel_array_size>>24);

            bmpinfoheader[4] = (unsigned char)(scaled_bmp_width);
            bmpinfoheader[5] = (unsigned char)(scaled_bmp_width>>8);
            bmpinfoheader[6] = (unsigned char)(scaled_bmp_width>>16);
            bmpinfoheader[7] = (unsigned char)(scaled_bmp_width>>24);

            bmpinfoheader[8] = (unsigned char)(scaled_bmp_height);
            bmpinfoheader[9] = (unsigned char)(scaled_bmp_height>> 8);
            bmpinfoheader[10] = (unsigned char)(scaled_bmp_height>>16);
            bmpinfoheader[11] = (unsigned char)(scaled_bmp_height>>24);

            bilinear_interpolation(pixel_array, (int) bmp_width, (int) bmp_height, scaled_pixel_array, scaled_bmp_width, scaled_bmp_height);

            fp = fopen("result.bmp", "wb");
            if (fp == NULL) {
                printf("error opening out file\n");
                return 0;
            }
            fwrite(bmpfileheader, 1, 14, fp);
            fwrite(bmpinfoheader, 1, 40, fp);
            fwrite(scaled_pixel_array, 1, scaled_pixel_array_size, fp);
            fclose(fp);
            free(scaled_pixel_array);
            image = al_load_bitmap("result.bmp");
            al_draw_bitmap(image, 0, 0, 0);
            al_flip_display();
            al_clear_to_color( al_map_rgb(0, 0 ,0) );
        }

        else if (event.type == ALLEGRO_EVENT_DISPLAY_CLOSE) {
            exit = true;
        }
    }
    free(pixel_array);
    al_destroy_display(display);
    al_destroy_event_queue(event_queue);
    al_destroy_bitmap(image);
   
    return 0;
}