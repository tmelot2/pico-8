pico-8 cartridge // http://www.pico-8.com
version 41
__lua__

-- Naive design for state machine using simple ifs

screenwidth = 127
screenheight = 127

state_title=1
state_game=2
state_gameover=3
state=nil

-- main
function _init()
	init_title()
end

function _update60()	
	input()

	if state==state_title then
		update_title()
	elseif state==state_game then
		update_game()
	elseif state==state_gameover then
		update_gameover()
	end
end

function _draw()
	if state==state_title then
		draw_title()
	elseif state==state_game then
		draw_game()
	elseif state==state_gameover then
		draw_gameover()
	end
end

function input()
	if state==state_title then
		input_title()
	elseif state==state_game then
		input_game()
	elseif state==state_gameover then
		input_gameover()
	end
end


-- astate
function set_state(s)
	log('set state '..s)
	if s==state_title then
		init_title()
	elseif s==state_game then
		init_game()
	elseif s==state_gameover then
		init_gameover()
	end
end


-- atitle

function init_title()
	state=state_title
	t=0
end

function update_title()
	t+=1
end

function draw_title()
	cls(9)
	cooltext('title '..t,t,2)
end

function input_title()
	if btnp(4)==true then
		set_state(state_game)
	end
end


-- agame
function init_game()
	state=state_game
	t=0
end

function update_game()
	t+=1
end

function draw_game()
	cls(2)
	cooltext('game '..t,t,12)
end

function input_game()
	if btnp(4) then
		set_state(state_gameover)
	end
end


-- agameover
function init_gameover()
	state=state_gameover
	t=0
	gameover_len=150
end

function update_gameover()
	t+=1
	if t>gameover_len then
		set_state(state_title)
	end
end

function draw_gameover()
	cls(3)
	cooltext('gameover '..gameover_len-t,t,9)
end

function input_gameover()
	if btnp(4) then
		set_state(state_title)
	end
end


-- autil
function log(s)
	printh(s, 'log.txt', false, true)
end

function cooltext(s,t,c)
	w=4*#s
	cx=screenwidth/2-(w/2)
	cy=20
	for i=1,#s do
		y=cy+4*sin(t+((i+t))/240)
		print(s[i], cx+i*4, y, c)
	end
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
