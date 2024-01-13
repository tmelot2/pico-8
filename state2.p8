pico-8 cartridge // http://www.pico-8.com
version 41
__lua__

-- Naive design for state machine using function pointers

screenwidth = 127
screenheight = 127

state_title=1
state_game=2
state_gameover=3
state=nil

-- state function pointers
init_fp=nil
update_fp=nil
draw_fp=nil
input_fp=nil

-- main
function _init()
	set_state(state_title)
end

function _update60()	
	input()
	update_fp()
end

function _draw()
	draw_fp()
end

function input()
	input_fp()
end


-- astate
function set_state(s)
	log('set state '..s)
	if s==state_title then
		init_fp=init_title
		input_fp=input_title
		update_fp=update_title
		draw_fp=draw_title
	
	elseif s==state_game then
		init_fp=init_game
		input_fp=input_game
		update_fp=update_game
		draw_fp=draw_game
	
	elseif s==state_gameover then
		init_fp=init_gameover
		input_fp=input_gameover
		update_fp=update_gameover
		draw_fp=draw_gameover
	end

	init_fp()
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
