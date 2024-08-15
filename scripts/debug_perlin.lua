perlin_x = emu.getLabelAddress("perlin_x")
perlin_y = emu.getLabelAddress("perlin_y")
step_size = 0x10
min = 256
max = -256


function plot()
	x = emu.read16(perlin_x.address, perlin_x.memType)
	y = emu.read16(perlin_y.address, perlin_y.memType)
	color = emu.read(0x00, emu.memType.nesMemory, true)
	if (color < min) then
		min = color
	elseif (color > max) then
		max = color
	end
	emu.log(min .. " " .. max)
	
	
	emu.drawPixel(x / step_size, y / step_size, color * 2 + 128, 0)
end

emu.addMemoryCallback(plot, emu.callbackType.write, 0x4444)