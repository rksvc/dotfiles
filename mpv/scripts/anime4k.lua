local anime4k = false

local function toggle()
    if not anime4k then
        mp.set_property('glsl-shaders', '')
        return
    end
    local height, error = mp.get_property_number('height')
    if error then
        mp.msg.error(error)
        return
    end
    if math.abs(height - 1080) < math.abs(height - 720) then
        mp.set_property('glsl-shaders',
            '~~/shaders/Anime4K_Clamp_Highlights.glsl;~~/shaders/Anime4K_Restore_CNN_M.glsl;~~/shaders/Anime4K_Upscale_CNN_x2_M.glsl;~~/shaders/Anime4K_AutoDownscalePre_x2.glsl;~~/shaders/Anime4K_AutoDownscalePre_x4.glsl;~~/shaders/Anime4K_Upscale_CNN_x2_S.glsl')
    elseif math.abs(height - 720) < math.abs(height - 480) then
        mp.set_property('glsl-shaders',
            '~~/shaders/Anime4K_Clamp_Highlights.glsl;~~/shaders/Anime4K_Restore_CNN_Soft_M.glsl;~~/shaders/Anime4K_Upscale_CNN_x2_M.glsl;~~/shaders/Anime4K_AutoDownscalePre_x2.glsl;~~/shaders/Anime4K_AutoDownscalePre_x4.glsl;~~/shaders/Anime4K_Upscale_CNN_x2_S.glsl')
    else
        mp.set_property('glsl-shaders',
            '~~/shaders/Anime4K_Clamp_Highlights.glsl;~~/shaders/Anime4K_Upscale_Denoise_CNN_x2_M.glsl;~~/shaders/Anime4K_AutoDownscalePre_x2.glsl;~~/shaders/Anime4K_AutoDownscalePre_x4.glsl;~~/shaders/Anime4K_Upscale_CNN_x2_S.glsl')
    end
end

mp.register_event('file-loaded', function(event)
    if event.error then
        mp.msg.error(event.error)
        return
    end
    toggle()
end)

mp.register_script_message('toggle-anime4k', function()
    anime4k = not anime4k
    mp.osd_message('Anime4K: ' .. (anime4k and 'on' or 'off'))
    toggle()
end)
