pico-8 cartridge // http://www.pico-8.com
version 41
__lua__

screenwidth = 127
screenheight = 127

function log(s)
	printh(s, 'log.txt')
end

function print_memory(from,to)
	for i=0,to-from do

	end
end

function write_fake_scores()
	write_score(1, 1000, 'aaa', 1)
	write_score(1, 900, 'def', 2)
	write_score(1, 800, 'ghi', 3)
	write_score(1, 700, 'jkl', 4)
	write_score(1, 600, 'mno', 5)

	write_score(2, 500, 'pqr', 1)
	write_score(2, 400, 'stu', 2)
	write_score(2, 300, 'vwx', 3)
	write_score(2, 200, 'yz1', 4)
	write_score(2, 100, '234', 5)
end

-- high score format
-- every 25 bytes in cartdata() is a level
-- bytes
-- 	1,2 	16-bit score (0-32767)
-- 	3,4,5	name, 3 chr 	
--
-- level num & score slot are 1-based
--
-- write chars with ord() (char to code)
function write_score(level_num, score, name, slot)
	log('writing score '..score..' '..name..' to slot '..slot)
	local base=0x5e00
	local level_start_addr=base+25*(level_num-1)
	local slot_addr=(slot-1)*5
	poke2(level_start_addr+slot_addr, score)
	poke(level_start_addr+slot_addr+2, ord(name,1), ord(name,2), ord(name,3))
end

-- level num & score slot are 1-based
-- returns table of scores for level 
-- { 1={name,score}, 2={name,score}, ...}
-- reads chars with chr() (code to char)
function read_scores(level_num)
	log('reading scores for level '..level_num)
	local base=0x5e00
	local level_start_addr=base+25*(level_num-1)
	local highscores={}
	for i=0,4 do
		local slot_addr=5*i
		local score=peek2(level_start_addr+slot_addr)
		local name=chr(peek(level_start_addr+slot_addr+2))..chr(peek(level_start_addr+slot_addr+3))..chr(peek(level_start_addr+slot_addr+4))
		highscores[i+1]={score=score, name=name}
	end
	return highscores
end

-- checks if score is a high score for level num
-- if so, returns score slot it goes in
-- otherwise, returns -1
function get_high_score_slot(level_num, new_score)
	log('checking if '..new_score..' is a high score')
	local scores=read_scores(level_num)
	for i=1,#scores do
		local cur_score=scores[i].score
		if new_score>cur_score then
			log(new_score..' ('..cur_score..') is a new high score in slot '..i)
			return i
		end
	end
	return -1
end

function insert_high_score(level_num, slot, new_score, name)
	local scores=read_scores(level_num)

	log('new high score name '..name..' slot '..slot..' new score '..new_score)
	add(scores, {name=name,score=new_score}, slot)

	for i=1,#scores do
		if i>5 then
			log('break')
			break
		end
		write_score(level_num, scores[i].score, scores[i].name, i)
	end
end

function print_level_scores(s)
	for i=0,4 do
		local name=s[i+1].name
		local score=s[i+1].score
		print(name..' '..score)
	end
end

-- main
cls()
cartdata('tm_cartdata1')
-- write_fake_scores()
log('============== START')
s1=read_scores(1)
print('level 1 high scores')
print_level_scores(s1)
print('')

s2=read_scores(2)
print('level 2 high scores')
print_level_scores(s2)

local level_num=1
local score=1001
local slot=get_high_score_slot(level_num, score)
local name='ted'
if slot>0 then
	insert_high_score(level_num, slot, score, name)
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
