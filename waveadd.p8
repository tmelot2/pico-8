pico-8 cartridge // http://www.pico-8.com
version 41
__lua__

screenwidth = 127
screenheight = 127

button=0
t=0

wc=3
waves={}
sumwave={}

show_waves=false

-- main
function _init()
	p={8,9,10,11,12}

	waves = {}

	base_freq = 1/128
	base_amp = 1.5
	freq = base_freq
	amp = base_amp

	-- for i=1,rnd(3)+3 do
	for i=1,wc do
		speed = rndrange(-0.02, 0.02)
		phase = rnd() * 2
		-- if freq > 0.08 then freq = 1 end
		add(waves, {
			freq = freq,
			speed = speed,
			phase = phase,
			amp = amp,
			c = 5
		})
		freq *= 2.0
		amp *= 0.4
	end
end

function _update60()	
	input()
	t+=1
end

function _draw()
	cls(0)
	scale=4
	tv=0

	-- Reset sumwave for this frame
    sumwave = {}
    for x = 0, 127 do
        sumwave[x] = 0
    end

    -- Waves
	for i=1,#waves do
		w = waves[i]
		-- print('f'..w.freq..' p'..w.phase..' a'..w.amp, 2, 6*i, w.c)
		for x=1,127 do
			v = w.amp * sin(w.freq*x + w.speed*t + w.phase)
			sumwave[x] += v
			if show_waves then
				pset(x, 55 - (v * scale), w.c)
			end
		end
		print(w.freq)
	end

	-- Sum wave
	for x=0,127 do
		-- pset(x, 75 - scale*sumwave[x], 12)
		line(x, 75 - scale*sumwave[x], x, 128, 12)
		pset(x, 75 - scale*sumwave[x] -1, 13)
		pset(x, 75 - scale*sumwave[x] -2, 7)
		-- pset(x, 75 - scale*sumwave[x] +0, 1)
	end

	print(#waves..' waves')
end


-- input
function input()
	if btnp(0) then wc-=1 _init() end -- l
	if btnp(1) then wc+=1 _init() end -- r
	if btn(2) then button='up' end -- u
	if btn(3) then button='down' end -- d
	if btnp(4) then _init() end -- o
	if btnp(5) then show_waves = not show_waves end -- x
	if btn() == 0 then button='' end -- d
end


function rndrange(min, max)
	return min + rnd(max-min)
end



__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
