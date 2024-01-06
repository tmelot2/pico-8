pico-8 cartridge // http://www.pico-8.com
version 41
__lua__

screenwidth = 128
screenheight = 128

cx = screenwidth/2
cy = screenheight/2

bgc = 1

em = nil
actor = {
	x = 5,
	y = screenheight/2-20,
	c = 7,
	s = 'rest'
}

-- main
function _init()
	em = initEaseManager()
end

function _update60()	
	input()
	em.update(em)
end

function _draw()
	cls(bgc)
	spr(1, actor.x, actor.y, 3, 1)
	print('actor.y '..actor.y, 1, 1, 7)
	print('em len '..#em.list, 1, 7, 7)
end


-- input
function input()
	if btnp(4) then
		if actor.s == 'rest' then
			actor.s = 'moving'
			actor.x = 5
			actor.y = screenheight/2-20
			em.ease(actor, 'y', actor.y, actor.y+20, 60, bg)
			em.ease(actor, 'x', actor.x, actor.x+50, 60, bg)
		end
	end
end

function bg()
	actor.s = 'rest'
end


-- ease manager
function initEaseManager()
	local newEm = {}
	newEm.list = {}

	newEm.ease = function(obj, field, start, final, duration, cb)
		local c = cocreate(function()
			for i=1,duration do
				obj[field] = easeInOutQuad(i, start, final-start, duration)
				yield()
			end
			obj[field] = final
			if (cb ~= nil) then
				cb()
			end
		end)

		add(newEm.list, c)
	end

	newEm.update = function(self)
		for c in all(self.list) do
			if costatus(c) != 'dead' then
				coresume(c)
			else
				del(self.list, c)
			end
		end
	end

	return newEm
end


function easeInOutQuad(t,b,c,d)
	t /= d/2
	if (t < 1) return c/2*t*t + b
	t -= 1
	return -c/2 * (t*(t-2) - 1) + b
end

__gfx__
00000000099999900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000099999900999990009999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
007007000aa99aa0099aaa0009aa9900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700000099000099999000900a990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700000099000099aaa0009000990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
007007000009900009999900090099a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000990000aaaaa0009999a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000aa000000000000aaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
