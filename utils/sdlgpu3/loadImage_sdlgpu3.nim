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

proc loadTextureFromBufferSDLGPU3*(data: seq[byte], data_size: csize_t, device: ptr SDL_GPUDevice , out_texture: var ptr SDL_GPUTexture , out_width: var cint, out_height: var cint): bool =
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

    out_texture = texture;
    out_width = image_width.int32;
    out_height = image_height.int32;
    return true;

# Open and read a file, then forward to LoadTextureFromMemory()
proc loadTextureFromFileSDLGPU3*(file_name: string, device: var ptr SDL_GPUDevice, out_texture: var ptr SDL_GPUTexture, out_width: var cint, out_height: var cint ): bool =
    var channels: int
    var width,height: int
    var file_data = stbi.load(file_name, width, height, channels, 4)
    out_width = width.cint
    out_height = height.cint
    return  loadTextureFromBufferSDLGPU3(file_data
                               , file_data.len.csize_t
                               , device, out_texture, out_width, out_height)

proc DestroyTexture(device: ptr SDL_GPUDevice, texture: ptr SDL_GPUTexture) =
    SDL_ReleaseGPUTexture(device, texture);
