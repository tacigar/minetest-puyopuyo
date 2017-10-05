---------------------------------------------------------------------
-- minetest-puyopuyo
-- Copyright (C) 2017 tacigar
---------------------------------------------------------------------

local colorref = {"blue", "green", "purple", "red", "yellow"}

local imgs = {}
imgs["puyo"] = {
	["blue"]    = "puyopuyo_puyo_blue.png",
	["green"]   = "puyopuyo_puyo_green.png",
	["purple"]  = "puyopuyo_puyo_purple.png",
	["red"]     = "puyopuyo_puyo_red.png",
	["yellow"]  = "puyopuyo_puyo_yellow.png",
}
imgs["title"] = "puyopuyo_title.png"
imgs["background"] = "puyopuyo_background.png"

local formspecs = {}
formspecs["start"] =
	"size[5.9,5.7]" ..
	string.format("image[0.25,1;6.5,2;%s]", imgs["title"]) ..
	"button[2,2.5;2,2;start;New Game]" ..
	default.gui_bg ..
	default.gui_bg_img ..
	default.gui_slots

formspecs["game"] = function(kumipuyo, field, nextpuyo, score, scoremanager)
	return "size[5.9,5.7]" ..
		"button[3.6,4.5;0.6,0.6;rotateleft;L]" ..
		"button[4.8,4.5;0.6,0.6;rotateright;R]" ..
		"button[3,4.5;0.6,0.6;moveleft;←]" ..
		"button[5.4,4.5;0.6,0.6;moveright;→]" ..
		"button[4.2,4.5;0.6,0.6;movedown;↓]" ..
		string.format("image[0.015,0.025;3.5,6.5;%s]", imgs["background"]) ..
		field:toformspec() ..
		kumipuyo:toformspec() ..
		string.format("image[3.25,0.5;1,2;%s]", imgs["background"]) ..
		string.format("image[3.45,0.85;0.55,0.55;%s]", imgs["puyo"][nextpuyo[1][2]]) ..
		string.format("image[3.45,1.35;0.55,0.55;%s]", imgs["puyo"][nextpuyo[1][1]]) ..
		string.format("image[4.5,0.5;1,2;%s]", imgs["background"]) ..
		string.format("image[4.7,0.85;0.55,0.55;%s]", imgs["puyo"][nextpuyo[2][2]]) ..
		string.format("image[4.7,1.35;0.55,0.55;%s]", imgs["puyo"][nextpuyo[2][1]]) ..
		"label[3,2.75;SCORE:]" ..
		string.format("label[3.85,2.75;%d]", score + scoremanager.value) ..
		"button[3.5,3;2,2;start;New Game]" ..
		default.gui_bg ..
		default.gui_bg_img ..
		default.gui_slots
end

local numcolors = 4

local function makecolorpair()
	return { colorref[math.random(1, numcolors)], colorref[math.random(1, numcolors)] }
end

local function round(x)
	return math.floor(x + 0.5)
end

local function getchildposition(x, y, r)
	return { x = x + math.sin(math.rad(r)),	y = y + math.cos(math.rad(r)) }
end

local scale = 0.05

---------------------------------------------------------------------
-- KUMIPUYO CLASS
---------------------------------------------------------------------
local Kumipuyo = {}
Kumipuyo.__index = Kumipuyo

setmetatable(Kumipuyo, {
	__call = function(_, params)
		local self = setmetatable({}, Kumipuyo)

		self.x = params.x
		self.y = params.y
		self.r = params.r
		self.colors = params.colors
		self.field = params.field

		return self
	end,
})

function Kumipuyo:move(dir)
	if dir == "right" or dir == "left" then
		local dx = (dir == "right") and 1 or -1
		local poss = {
			{ x = self.x + dx, y = self.y },
			getchildposition(self.x + dx, self.y, self.r),
		}

		local enable = true
		for _, p in ipairs(poss) do
			if self.field:get(p.x, p.y) ~= "no" then
				enable = false
				break
			end
		end

		if enable then
			self.x = self.x + dx
		end

	elseif dir == "down" then
		local poss = {
			{ x = self.x, y = self.y - 1 },
			getchildposition(self.x, self.y - 1, self.r)
		}

		local enable = true
		for _, p in ipairs(poss) do
			if self.field:get(p.x, p.y) ~= "no" then
				enable = false
				break
			end
		end

		if enable then
			self.y = self.y - 1
		else
			self:fix()
			return true
		end
	end
	return false
end

function Kumipuyo:rotate(dir)
	local function rotatecommon(nextr)
		local cpos = getchildposition(self.x, self.y, nextr)

		if self.field:get(cpos.x, cpos.y) == "no" then
			self.r = nextr
			return
		else
			local tpos = getchildposition(self.x, self.y, (nextr + 180) % 360)

			if self.field:get(tpos.x, tpos.y) == "no" then
				self.r = nextr
				self.x = tpos.x
				self.y = tpos.y
				return
			else -- upsidedown
				self.r = (self.r + 180) % 360
				self.y = self.y + 1
				return
			end
		end
	end

	if dir == "right" then
		if self.r == 360 then
			self.r = 0
		end
		rotatecommon(self.r + 90)
	elseif dir == "left" then
		if self.r == 0 then
			self.r = 360
		end
		rotatecommon(self.r - 90)
	end
end

function Kumipuyo:fix()
	local poss = {
		{ x = self.x, y = self.y },
		getchildposition(self.x, self.y, self.r)
	}

	for i, p in ipairs(poss) do
		if p.y == 1 or self.field:get(p.x, p.y - 1) ~= "no" then
			for j, p2 in ipairs(poss) do
				if p2.y <= 13 then
					self.field:set(p2.x, p2.y, self.colors[j])
				end
			end

			for j, p2 in ipairs(poss) do
				if p2.y <= 13 then
					self.field:set(p2.x, p2.y, "no")
					while p2.y > 1 and self.field:get(p2.x, p2.y - 1) == "no" do
						p2.y = p2.y - 1
					end
					self.field:set(p2.x, p2.y, self.colors[j])
				end
			end
		end
	end
end

function Kumipuyo:toformspec()
	local poss = {
		{ x = self.x, y = self.y },
		getchildposition(self.x, self.y, self.r)
	}

	local tbl = {}
	for i, p in ipairs(poss) do
		if p.y <= 12 then
			local x = (p.x - 1) * 0.475
			local y = (12 - p.y) * 0.475

			tbl[i] = string.format("image[%f,%f;%f,%f;%s]", x, y, 0.55, 0.55, imgs["puyo"][self.colors[i]])
		end
	end

	return table.concat(tbl)
end

---------------------------------------------------------------------
-- FIELD CLASS
---------------------------------------------------------------------
local Field = {}
Field.__index = Field

setmetatable(Field, {
	__call = function(_, data)
		if not data then
			data = {}
			for i = 1, 13 do
				data[i] = {}
				for j = 1, 6 do
					data[i][j] = "no"
				end
			end
		end

		return setmetatable(data, Field)
	end,
})

function Field:get(x, y)
	local x = round(x)
	local y = round(y)

	if x <= 0 or x > 6 or y <= 0 or y > 13 then
		return "wall"
	else
		return self[y][x]
	end
end

function Field:set(x, y, c)
	local x = round(x)
	local y = round(y)

	self[y][x] = c
end

function Field:delete()
	local checkedfield = {}
	for i = 1, 13 do
		checkedfield[i] = {}
		for j = 1, 6 do
			checkedfield[i][j] = 0
		end
	end

	local deletes = {}
	local checkedcolor = {}
	local linknums = {}

	local function check(color, x, y, auxfield, poss)
		if self[y] == nil or self[y][x] ~= color or auxfield[y][x] then
			return 0
		end

		auxfield[y][x] = true
		local cnt = 1
		table.insert(poss, { x = x, y = y })

		for _, diff in ipairs{{ x = 1, y = 0 }, { x = -1, y = 0 }, { x = 0, y = 1 }, { x = 0, y = -1 }} do
			local tmpcnt = check(color, x + diff.x, y + diff.y, auxfield, poss)
			cnt = cnt + tmpcnt
		end

		return cnt
	end

	for i = 1, 13 do
		for j = 1, 6 do
			if self[i][j] ~= "no" and checkedfield[i][j] == 0 then
				local auxfield = {}
				for i = 1, 13 do
					auxfield[i] = {}
				end

				local poss = {}
				local cnt = check(self[i][j], j, i, auxfield, poss)

				if cnt >= 4 then
					table.insert(linknums, cnt)
					checkedcolor[self[i][j]] = true
					for _, pos in ipairs(poss) do
						checkedfield[pos.y][pos.x] = 2
						table.insert(deletes, { x = pos.x, y = pos.y, color = self[i][j]})
					end
				elseif cnt >= 1 then
					for _, pos in ipairs(poss) do
						checkedfield[pos.y][pos.x] = 1
					end
				end
			end
		end
	end

	local numcolors = 0
	for _ in pairs(checkedcolor) do
		numcolors = numcolors + 1
	end

	return deletes, linknums, numcolors
end

function Field:toformspec()
	local tbl = {}
	for i = 1, 12 do
		for j = 1, 6 do
			if self[i][j] ~= "no" then
				local x = (j - 1) * 0.475
				local y = (12 - i) * 0.475

				table.insert(tbl, string.format("image[%f,%f;%f,%f;%s]", x, y, 0.55, 0.55, imgs["puyo"][self[i][j]]))
			end
		end
	end
	return table.concat(tbl)
end

---------------------------------------------------------------------
-- SCOREMANAGER CLASS
---------------------------------------------------------------------

Scoremanager = {}
Scoremanager.__index = Scoremanager

setmetatable(Scoremanager, {
	__call = function(_, params)
		local self = setmetatable({}, Scoremanager)
		if params then
			self.value = params.value
			self.chaincounter = params.chaincounter
		else
			self:reset()
		end
		return self
	end,
})

function Scoremanager:reset()
	self.value = 0
	self.chaincounter = 0
end

Scoremanager.chainbonus = {
	[1] = 0, [2] = 8, [3] = 16, [4] = 32,
	[5] = 64, [6] = 96, [7] = 128, [8] = 160,
	[9] = 192, [10] = 224, [11] = 256, [12] = 288,
	[13] = 320, [14] = 352, [15] = 384, [16] = 416,
	[17] = 448, [18] = 480,	[19] = 512,
}

Scoremanager.linkbonus = {
	[4] = 0, [5] = 2, [6] = 3, [7] = 4, [8] = 5, [9] = 6, [10] = 7,
}

Scoremanager.colorbonus = {
	[1] = 0, [2] = 3, [3] = 6, [4] = 12, [5] = 24,
}

function Scoremanager:chain(numdrops, linknums, numcolors)
	self.chaincounter = self.chaincounter + 1
	local chainbonus = Scoremanager.chainbonus[self.chaincounter]
	local linkbonus = 0
	for _, v in ipairs(linknums) do
		if v > 10 then
			linkbonus = linkbonus + 10
		else
			linkbonus = linkbonus + Scoremanager.linkbonus[v]
		end
	end
	local colorbonus = Scoremanager.colorbonus[numcolors]

	local totalbonus = chainbonus + linkbonus + colorbonus
	if totalbonus == 0 then
		totalbonus = 1
	end

	self.value = self.value + (numdrops * totalbonus) * 10
end

---------------------------------------------------------------------

local function startnewgame(pos)
	local timer = minetest.get_node_timer(pos)
	timer:start(0.5)

	local ret = {}
	ret.field = Field()
	ret.kumipuyo = Kumipuyo{ x = 3, y = 13, r = 0, colors = makecolorpair(), field = ret.field }
	ret.nextpuyo = { makecolorpair(), makecolorpair() }
	ret.score = 0
	ret.state = "control"
	ret.scoremanager = Scoremanager()

	return ret
end

minetest.register_node("puyopuyo:puyopuyo", {
	description = "PuyoPuyo!",
	groups = { snappy = 3 },
	tiles = {"puyopuyo_node.png"},

	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", formspecs["start"])
	end,

	on_timer = function(pos)
		local meta = minetest.get_meta(pos)

		local datatbl = minetest.deserialize(meta:get_string("puyopuyo"))

		if datatbl == nil then
			return false
		end

		local field = Field(datatbl.field)

		datatbl.kumipuyo.field = field
		local kumipuyo = Kumipuyo(datatbl.kumipuyo)

		local scoremanager = Scoremanager(datatbl.scoremanager)

		if datatbl.state == "control" then
			local stuck = kumipuyo:move("down")
			if stuck then
				kumipuyo = Kumipuyo{ x = 3, y = 13, r = 0, colors = datatbl.nextpuyo[1], field = field }
				scoremanager:reset()
				datatbl.state = "delete"
			end

		elseif datatbl.state == "delete" then
			local deletes, linknums, numcolors = field:delete()
			if #deletes == 0 then
				if field:get(3, 13) ~= "no" then
					return false
				else
					datatbl.score = datatbl.score + scoremanager.value
					datatbl.nextpuyo = { datatbl.nextpuyo[2], makecolorpair() }
					datatbl.state = "control"
					scoremanager:reset()
				end
			else
				scoremanager:chain(#deletes, linknums, numcolors)
				for _, d in ipairs(deletes) do
					field:set(d.x, d.y, "no")
				end
				datatbl.state = "fall"
			end

		elseif datatbl.state == "fall" then
			for j = 1, 6 do
				for i = 13, 1, -1 do
					if field:get(j, i) == "no" then
						for k = i, 12 do
							field[k][j] = field[k + 1][j]
						end
					end
				end
			end
			datatbl.state = "delete"
		end

		meta:set_string("formspec", formspecs["game"](kumipuyo, field, datatbl.nextpuyo, datatbl.score, scoremanager))
		kumipuyo.field = nil

		meta:set_string("puyopuyo", minetest.serialize({
			field = field,
			kumipuyo = kumipuyo,
			nextpuyo = datatbl.nextpuyo,
			score = datatbl.score,
			state = datatbl.state,
			scoremanager = scoremanager,
		}))

		return true
	end,

	on_receive_fields = function(pos, formname, fields, sender)
		local meta = minetest.get_meta(pos)

		if fields["start"] ~= nil then
			local data = startnewgame(pos)

			meta:set_string("formspec", formspecs["game"](data.kumipuyo, data.field, data.nextpuyo, data.score, data.scoremanager))
			data.kumipuyo.field = nil
			meta:set_string("puyopuyo", minetest.serialize(data))

		else
			local datatbl = minetest.deserialize(meta:get_string("puyopuyo"))

			local field = Field(datatbl.field)

			datatbl.kumipuyo.field = field
			local kumipuyo = Kumipuyo(datatbl.kumipuyo)

			local scoremanager = Scoremanager(datatbl.scoremanager)

			if datatbl.state == "control" then
				if fields["moveleft"] then
					kumipuyo:move("left")
				elseif fields["moveright"] then
					kumipuyo:move("right")
				elseif fields["rotateleft"] then
					kumipuyo:rotate("left")
				elseif fields["rotateright"] then
					kumipuyo:rotate("right")
				elseif fields["movedown"] then
					local stuck = kumipuyo:move("down")
					if stuck then
						kumipuyo = Kumipuyo{ x = 3, y = 13, r = 0, colors = datatbl.nextpuyo[1], field = field }
						scoremanager:reset()
						datatbl.state = "delete"
					end
				end
			end

			meta:set_string("formspec", formspecs["game"](kumipuyo, field, datatbl.nextpuyo, datatbl.score, scoremanager))
			kumipuyo.field = nil
			meta:set_string("puyopuyo", minetest.serialize({
				field = field,
				kumipuyo = kumipuyo,
				nextpuyo = datatbl.nextpuyo,
				score = datatbl.score,
				state = datatbl.state,
				scoremanager = scoremanager,
			}))
		end
	end,
})
