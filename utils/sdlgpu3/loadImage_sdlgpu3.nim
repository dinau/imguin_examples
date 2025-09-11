#// See:
#//    https://github.com/ocornut/imgui/wiki/Image-Loading-and-Displaying-Examples
#//
##define _CRT_SECURE_NO_WARNINGS
#//#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"
#include <stdbool.h>
#include <stdlib.h>
#include "loadImage_sdlgpu3.h"

import sdl3_nim
import stb_image/read as stbi

#define SDL_GPU_TEXTUREUSAGE_SAMPLER                                 (1u << 0) /**< Texture supports sampling. */
#define SDL_GPU_TEXTUREUSAGE_COLOR_TARGET                            (1u << 1) /**< Texture is a color render target. */
#define SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET                    (1u << 2) /**< Texture is a depth stencil target. */
#define SDL_GPU_TEXTUREUSAGE_GRAPHICS_STORAGE_READ                   (1u << 3) /**< Texture supports storage reads in graphics stages. */
#define SDL_GPU_TEXTUREUSAGE_COMPUTE_STORAGE_READ                    (1u << 4) /**< Texture supports storage reads in the compute stage. */
#define SDL_GPU_TEXTUREUSAGE_COMPUTE_STORAGE_WRITE                   (1u << 5) /**< Texture supports storage writes in the compute stage. */
#define SDL_GPU_TEXTUREUSAGE_COMPUTE_STORAGE_SIMULTANEOUS_READ_WRITE (1u << 6) /**< Texture supports reads and writes in the same compute shader. This is NOT equivalent to READ | WRITE. */

const SDL_GPU_TEXTUREUSAGE_SAMPLER  =  (1 shl 0) #/**< Texture supports sampling. */

proc loadTextureFromBufferSDLGPU3*(data: seq[byte], data_size: csize_t, device: ptr SDL_GPUDevice , out_texture: ptr ptr SDL_GPUTexture , out_width: ptr cint, out_height: ptr cint): bool =
    #// Load from disk into a raw RGBA buffer
    var image_width: uint32
    var image_height: uint32
    var channels: int
    #var image_data = stbi.loadFromMemory(data , image_width, image_height, channels, 4)
    var image_data = data

    #// Create texture
    var texture_info: SDL_GPUTextureCreateInfo
    texture_info.type_field = SDL_GPU_TEXTURETYPE_2D
    texture_info.format = SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM;
    texture_info.usage = SDL_GPU_TEXTUREUSAGE_SAMPLER;
    texture_info.width = image_width
    texture_info.height = image_height
    texture_info.layer_count_or_depth = 1;
    texture_info.num_levels = 1;
    texture_info.sample_count = SDL_GPU_SAMPLECOUNT_1;

    var texture = SDL_CreateGPUTexture(device, addr texture_info)

    #// Create transfer buffer
    #// FIXME: A real engine would likely keep one around, see what the SDL_GPU backend is doing.
    var transferbuffer_info = SDL_GPUTransferBufferCreateInfo()
    transferbuffer_info.usage = SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD
    transferbuffer_info.size = image_width * image_height * 4
    var transferbuffer = SDL_CreateGPUTransferBuffer(device, addr transferbuffer_info)
    #//IM_ASSERT(transferbuffer != NULL);

    #// Copy to transfer buffer
    var upload_pitch = image_width * 4
    var texture_ptr = SDL_MapGPUTransferBuffer(device, transferbuffer, true);
    for y in 0..image_height:
        copyMem(cast[ptr uint8](cast[uint64](texture_ptr) + y * upload_pitch) , cast[ptr uint8](cast[uint64](addr image_data[0]) + y * upload_pitch), upload_pitch)
    SDL_UnmapGPUTransferBuffer(device, transferbuffer)

    var  transfer_info = SDL_GPUTextureTransferInfo();
    transfer_info.offset = 0;
    transfer_info.transfer_buffer = transferbuffer;

    var texture_region = SDL_GPUTextureRegion();
    texture_region.texture = texture;
    texture_region.x = 0;
    texture_region.y = 0;
    texture_region.w = image_width;
    texture_region.h = image_height;
    texture_region.d = 1;

    #// Upload
    var cmd = SDL_AcquireGPUCommandBuffer(device);
    var  copy_pass = SDL_BeginGPUCopyPass(cmd);
    SDL_UploadToGPUTexture(copy_pass, addr transfer_info, addr texture_region, false);
    SDL_EndGPUCopyPass(copy_pass);
    SDL_SubmitGPUCommandBuffer(cmd);

    SDL_ReleaseGPUTransferBuffer(device, transferbuffer);

    out_texture[] = texture;
    out_width[] = image_width.int32;
    out_height[] = image_height.int32;
    return true;

# Open and read a file, then forward to LoadTextureFromMemory()
proc loadTextureFromFileSDLGPU3*(file_name: string, device: var ptr SDL_GPUDevice, out_texture: var ptr SDL_GPUTexture, out_width, out_height: var cint ): bool =
    var channels: int
    var file_data = stbi.load(file_name, cast[var int](out_width), cast[var int](out_height), channels, 4)
    return  loadTextureFromBufferSDLGPU3(file_data
                               , file_data.len.csize_t
                               , device, addr out_texture, addr out_width, addr out_height)

proc DestroyTexture(device: ptr SDL_GPUDevice, texture: ptr SDL_GPUTexture) =
    SDL_ReleaseGPUTexture(device, texture);
