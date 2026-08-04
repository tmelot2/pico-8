pico-8 cartridge // http://www.pico-8.com
version 41
__lua__

screenwidth = 127
screenheight = 127

button=0
t=0

wc=4
waves={}
sumwave={}

-- main
function _init()
	p={8,9,10,11,12}
	for i=1,wc do
		add(waves, {
			freq=1 + rnd(2),
			phase=rnd(i+5),
			amp=0.5+rnd(0.5),
			c=p[i%5+1]
		})
	end
end

function _update60()	
	input()
	t+=1
end

function _draw()
	cls(0)
	scale=8
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
			v = w.amp * sin((w.freq*x+t)/60)
			sumwave[x] += v
			-- pset(x, 75 - (v * scale), w.c)
		end
	end

	-- Sum wave
	for x=0,127 do
		pset(x, 75 - scale*sumwave[x], 12)
	end
end


-- input
function input()
	if btn(0) then button='left' end -- l
	if btn(1) then button='right' end -- r
	if btn(2) then button='up' end -- u
	if btn(3) then button='down' end -- d
	if btn(4) then button='o' end -- o
	if btn(5) then button='x' end -- x
	if btn() == 0 then button='' end -- d
end



__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
