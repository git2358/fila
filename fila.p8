pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-- tests

function _init()
	-- create a new fila instance
	local life = fila()
	
	-- life --> "mortal"
	life:knot("mortal")
	assert(life:find("mortal"))
	
	-- ===========================
	
	-- create a child instance of
	-- life
	local animal = life()

	assert(animal:get_parent()
		== life)
	assert(animal:is(life))
	
	-- * life is mortal (knot)
	--   animal is life (instance)
	--   animal is mortal
	--    (knot inheritance)
	assert(animal:find("mortal"))
	
	-- ===========================
	
	local bird = animal()
	
	assert(bird:is(animal))
	assert(bird:is(life))
	assert(bird:find("mortal"))
	
	-- bird -[true]-> "can_fly"
	bird:knot("can_fly", true)
	
	local res, param
	res, param = bird:find("can_fly")
	assert(res == true)
	assert(param == true)
	assert(not animal:find("can_fly"))
	
	-- ===========================
	
	local penguin = bird()
	
	-- override parent's knot
	penguin:knot("can_fly", false)
	
	res, param = penguin:find("can_fly")
	assert(res == true)
	assert(param == false)
	
	-- ===========================
	
	-- more compact way to create
	-- an instance with knots
	local ostrich = bird {
		can_fly = false,
		"funny", -- no parameter
	}
	
	-- more compact way to get knot
	assert(ostrich:get("can_fly")
		== false)
	assert(ostrich:get("funny")
		== nil) -- no parameter
		
	-- life:get("can_fly")
	-- ! error: knot not found
	
	-- ostrich:unknot("mortal")
	-- ! error: knot not found
	-- 	 * parent's knots cannot be
	--     removed from children
	
	ostrich:knot("mortal")
	ostrich:unknot("mortal")
	-- unknot only removes knots
	-- from the instance itself,
	-- life is still mortal
	assert(ostrich:find("mortal"))
	
	-- ===========================
	
	assert(bird:get_children_count()
		== 2)
	
	local children = {}
	for child in bird:iter_children() do
		children[child] = true
	end
	
	assert(children[penguin])
	assert(children[ostrich])
	
	-- ===========================
	
	local knots = {}
	for knot, param in penguin:iter_knots() do
		knots[knot] = param == nil
			and "no_param" or param
	end
	
	assert(knots["can_fly"] == false)
	-- iter_knots only provide
	-- knots added specifically
	-- on this instance
	assert(knots["mortal"] == nil)
	
	-- ===========================
	
	-- group containing children
	-- of life that has remaining-
	-- _lifetime less or equal to 0
	local dead_grp =
		life:group(function(f)
			local res, l =
				f:find("remaining_lifetime")
			return res and l <= 0
		end)
		
	-- when an life is added to the
	-- group, knot it with "dead"
	dead_grp:on_add(function(g, f)
		f:knot("dead")
	end)
	
	-- when an life is removed from
	-- the group, unknot "dead"
	dead_grp:on_remove(function(g, f)
		f:unknot("dead")
	end)
	
	-- * use unlisten_add and
	--   unlisten_remove to remove
	--   callbacks from group
	
	local old_penguin = penguin {
		remaining_lifetime = 1
	}
	
	assert(not dead_grp:has(old_penguin))
	assert(not old_penguin:find("dead"))
	
	old_penguin:knot(
		"remaining_lifetime", 0)
	
	assert(dead_grp:count() == 1)
	assert(dead_grp:has(old_penguin))
	assert(old_penguin:find("dead"))
		
	local old_ostrich = ostrich {
		remaining_lifetime = -1
	}
	
	assert(dead_grp:count() == 2)
	assert(dead_grp:has(old_ostrich))
	assert(old_ostrich:find("dead"))
	
	-- don't misinterpret * child
	-- instance * as 'child' in
	-- real world. it's more like
	-- * derived concept *.
	-- a child instance of old_-
	-- penguin inherits all the
	-- knots from old_penguin, thus
	-- is also dead (unfortunately)
	local old_penguin_2 =
		old_penguin {
			other_knot = "other_param"
		}
	assert(old_penguin_2:find("dead"))

	local dead = {}
	
	for i, f in dead_grp:iter() do
		dead[f] = true
	end
	
	assert(dead[old_penguin])
	assert(dead[old_ostrich])
	
	-- let's revive them!
	
	old_penguin:knot(
		"remaining_lifetime", 41)
	old_ostrich:knot(
		"remaining_lifetime", 42)
		
	assert(not old_penguin:find("dead"))
	assert(not old_ostrich:find("dead"))
	
	-- since old_penguin_2 is the
	-- child instance and does not
	-- override its parent's
	-- remaining_lifetime knot,
	-- when the parent gets revived
	-- it revives at the same time
	assert(not old_penguin_2:find("dead"))
	
	assert(dead_grp:count() == 0)
	assert(not dead_grp:has(old_penguin))
	assert(not dead_grp:has(old_ostrich))
	
	-- groups do not act on filae
	-- containing them
	life:knot(
		"remaining_lifetime", -1)
	assert(not life:find("dead"))
	life:unknot(
		"remaining_lifetime")
		
	-- sadly, old_penguin does not
	-- hold the answer to life,
	-- the universe, and everything
	old_penguin:knot(
		"remaining_lifetime", 0)
	assert(old_penguin:find("dead"))
	assert(old_penguin_2:find("dead"))

	-- groups does not get released
	-- after not referenced any
	-- more, you must destroy them
	-- manually
	dead_grp:destroy()
	
	-- when getting destroyed, all
	-- filae in the group are
	-- removed, triggering on_remove
	-- callbacks
	assert(not old_penguin:find("dead"))
	assert(not old_penguin_2:find("dead"))
	
	-- * groups created by group
	--   method have very poor
	--   performance since the
	--   predicate function has to
	--   be executed each time when
	--   any child of the instance
	--   knots or unknots anything
	
	-- * more performance can be
	--   gained by seperating
	--   groups into different fila
	--   instances that really need
	--   them
	
	-- * for better performance,
	--   use * fast group *
	
	-- ===========================
	
	-- fast groups are literally
	-- faster but limited in their
	-- instance selecting method:
	-- they can only be used to
	-- select instances that have
	-- specific set of knots
	
	-- g contains all the instances
	-- of life which have remainin-
	-- g_lifetime knot (and any
	-- pamameter of it)
	local g = life:fast_group(
		"remaining_lifetime")
		
	-- note that fast groups are
	-- cached - invoking fast_group
	-- twice with the same knots as
	-- arguments on the same fila
	-- gets the same group
	assert(g == life:fast_group(
		"remaining_lifetime"))
		
	assert(g:count() == 3)
	assert(g:has(old_penguin))
	assert(g:has(old_penguin_2))
	assert(g:has(old_ostrich))
	
	local dead = {}
	
	for i, f in g:iter() do
		dead[f] = true
	end
	
	assert(dead[old_penguin])
	assert(dead[old_penguin_2])
	assert(dead[old_ostrich])
	
	-- on_add_iter listens the add
	-- event just as on_add, while
	-- also invoking the callback
	-- for each fila that has been
	-- added to the group before
	g:on_add_iter(function(g, f)
		-- filae in the group must
		-- have remaining_lifetime
		-- knot
		local l =
			f:get("remaining_lifetime")
		if l <= 0 then
			f:knot("dead")
		end
	end)
	
	g:on_remove(function(g, f)
		f:unknot("dead")
	end)
	
	assert(old_penguin:find("dead"))
	assert(old_penguin_2:find("dead"))
	-- recall that old_ostrich has
	-- remaining lifetime of 42
	assert(not old_ostrich:find("dead"))
	
	-- now let's revive old_penguin
	-- (and old_penguin_2)
	old_penguin:knot(
		"remaining_lifetime", 42)
	
	-- but old penguin is still
	-- dead! this is because on_add
	-- callback only gets invoked
	-- when remaining_lifetime knot
	-- is added to a fila (a knot
	-- event), not when modified
	-- (a reknot event)
	assert(old_penguin:find("dead"))
	
	-- * to achieve the result we
	--   want, i.e. invoking some
	--   calbbacks each time when a
	--   fila that has specific set
	--   of knots changes one of
	--   those knots, promote the
	--   existing group to or
	--   create a new * reactive
	--   group *
	
	-- ===========================

	-- create a new reactive group
	-- (if a fast group with the
	-- same knot arguments has 
	-- already existed, it will be
	-- promoted to reactive group)
	local g = life:reactive_group(
		"remaining_lifetime")
	
	-- on_react callbacks are
	-- invoked each time when a
	-- fila is added to the group
	-- or updates its knots that
	-- are used by this group to
	-- select filae (in this case,
	-- it's remaining_lifetime)
	
	-- just like on_add_iter, call-
	-- backs added by on_react will
	-- be invoked firstly for each
	-- existing fila in the group
	g:on_react(function(g, f)
		local l =
			f:get("remaining_lifetime")
		if l <= 0 then
			f:knot("dead")
		else
			-- try_unknot won't throw
			-- an error if the knot does
			-- not exist
			f:try_unknot("dead")
		end
	end)
	
	-- * for removing the callback,
	--   use unlisten_react
	
	-- now, old_penguin and old_pe-
	-- guin_2 are alive!
	assert(not old_penguin:find("dead"))
	assert(not old_penguin_2:find("dead"))

	old_ostrich:knot(
		"remaining_lifetime", 0)
	assert(old_ostrich:find("dead"))

	-- * in essence, a group repre-
	--   sents some sort of rule
	--   that must be abided by all
	--   the child instances of the
	--   fila containing the group

	-- ===========================
	
	-- as you may have gussed,
	-- fast groups and reactive
	-- groups can have multiple
	-- knot targets as their
	-- arguments to select child
	-- instances (which are
	-- called knottees in fila
	-- paradigm, so knot = knottee
	-- + optional parameter)
	
	-- a dead life will start
	-- decomposing
	life:fast_group("dead")
		:on_add(function(g, f)
			f:knot("decomposing")
		end)
	
	local during_decomposing
	local goodbye
	
	-- a decomposing life which
	-- has decomposing time greater
	-- or equal to 1 will be
	-- destroyed (for fila, it's
	-- done by reset method) 
	life:reactive_group(
		"decomposing",
		"decomposing_time")
		:on_react(function(g, f)
			if f:get("decomposing_time")
				>= 1 then
				f:reset()
			end
		end)
		-- on_* methods returns the
		-- group itself, so you can
		-- chain them together
		:on_add(function(g, f)
			during_decomposing = true
		end)
		:on_remove(function(g, f)
			goodbye = true
		end)
	
	old_penguin:knot(
		"remaining_lifetime", 0)
		
	assert(old_penguin:find(
		"dead"))
	assert(old_penguin:find(
		"decomposing"))
	
	assert(not during_decomposing)
	
	old_penguin:knot(
		"decomposing_time", 0)
		
	assert(during_decomposing)
	
	old_penguin:knot(
		"decomposing_time", 1)
		
	assert(goodbye)
	
	-- once a fila is reset it will
	-- be detached from its parent,
	-- and all the knots and groups
	-- will be removed, as if you 
	-- reassign the variable with
	-- an empty fila created by
	-- `fila()`
	local ks = {}
	for k, p in
		old_penguin:iter_knots() do
		ks[#ks+1] = k
	end
	assert(#ks == 0)
	assert(old_penguin:get_parent()
		== nil)
		
	-- reset is recursive
	assert(old_penguin:get_children_count()
		== 0)
	assert(old_penguin_2:get_parent()
		== nil)
	
	-- old_penguin and old_penguin-
	-- _2 now are totally dead, but
	-- you can reuse those empty
	-- filae left by them and
	-- * reattach * them to other
	-- fila, which, in a romantic
	-- interpretation, is analogous 
	-- to the reincarnation of life
	local plant = life()
	local angiosperm = plant()
	angiosperm:knot("has_flower")
	
	local rose = old_penguin
	rose:reattach(angiosperm)
	assert(rose:is(plant))
	assert(rose:find("has_flower"))
	
	local patchouli = old_penguin_2
	patchouli:reattach(angiosperm)
	assert(patchouli:is(plant))
	assert(patchouli:find("has_flower"))
	
	-- ===========================
	
	-- it is possible to lift a
	-- fila to the same level as
	-- its parent using lift method
	
	local super_penguin = penguin()
	super_penguin:knot(
		"can_fly", true)
	
	local super_penguin_2 =
		super_penguin()
		
	assert(super_penguin_2:get_parent()
		== super_penguin)
	assert(super_penguin_2:get(
		"can_fly") == true)
		
	super_penguin_2:lift()
	
	assert(super_penguin_2:get_parent()
		== penguin)
		
	-- when lifting, all knots
	-- owned by fila's parent will
	-- be copied to the fila
	assert(super_penguin_2:get(
		"can_fly") == true)
		
	-- ===========================
	
	-- detach method repeats
	-- lifting the fila until it
	-- has no more parent (at top
	-- level)
	
	local super_penguin_template =
		fila()
	
	super_penguin_template
		:knot("can_fly", true)
		
	local mega_super_penguin_template =
		super_penguin_template()
		
	mega_super_penguin_template
		:knot("can_fly_into_space")
		
	local the_penguin =
		mega_super_penguin_template()
	
	the_penguin:detach()
	
	assert(the_penguin:get_parent()
		== nil)
	assert(the_penguin:get(
		"can_fly") == true)
	assert(the_penguin:find(
		"can_fly_into_space"))
	
	-- using reattach to attach the
	-- penguin to penguin fila
	the_penguin:reattach(penguin)
	assert(the_penguin:get_parent()
		== penguin)
	
	-- reattach will automatically
	-- invoke detach method if the
	-- fila has non-nil parent, so
	-- you can use it directly
	local the_penguin_2 =
		mega_super_penguin_template()
	the_penguin_2:reattach(penguin)
	
	assert(the_penguin_2:get(
		"can_fly") == true)
	assert(the_penguin_2:find(
		"can_fly_into_space"))
	assert(the_penguin_2:get_parent()
		== penguin)
	
	print("all tests passed")
end
-->8
-- fila

-- local fila = {}
fila = {}
fila.__index = fila

local no_param = {}

local function create(knots)
	local f = setmetatable({
		-- children = {},
		-- children_n = 0,
		-- knots = {},
		-- listeners = {},
		-- groups = {},
		-- fast_groups = {}
		hash = rnd()
	}, fila)
	
	if knots then
		assert(type(knots) == "table",
			"invalid knots")
		
		local ks = {}

		for k, p in pairs(knots) do
			if type(k) == "number" then
				k = p
				p = no_param
			end
			ks[k] = p
		end

		f.knots = ks
	end
	
	return f
end

local function event(sender, method, ...)
	local f = sender.parent
	while f do
		local ltns = f.listeners
		if ltns then
			for l in pairs(ltns) do
				local m = l[method]
				if m then m(l, sender, ...) end
			end
		end
		f = f.parent
	end
end

-- used by knot and reknot
local function event_rec(sender, method, k, ...)
	event(sender, method, k, ...)
	
	local children = sender.children
	if children then
		for child in pairs(children) do
			local ks = child.knots
			if not ks or not ks[k] then
				event_rec(child, method, k, ...)
			end
		end
	end
end

local function add_child(self, f)
	local children = self.children
	if not children then
		children = {}
		self.children = children
		self.children_n = 0
	end
 
	children[f] = true
	self.children_n =
		self.children_n + 1
	
	f.parent = self
	event(f, "notify_create")
end

setmetatable(fila, {
	__call = function(_, knots)
		return create(knots)
	end
})

function fila:__call(knots)
	local f = create(knots)
	add_child(self, f)
	return f
end

function fila:__tostring()
	return "[fila: "..self.hash.."]"
end

function fila:get_hash()
	return self.hash
end

function fila:get_parent()
	return self.parent
end

function fila:is(f)
	local p = self
	repeat
		if p == f then
			return true
		end
		p = p.parent
	until not p
end

function fila:get_children_count()
	return self.children_n or 0
end

function fila:iter_children()
	local children = self.children
	return next, children or no_param
end

function fila:clear_children()
	local children = self.children
	if not children then return end
	
	for child in pairs(children) do
		child:reset()
	end
end

function fila:add_listener(l)
	assert(type(l) == "table",
		"invalid listener")

	local ltns = self.listeners
	if not ltns then
		ltns = {}
		self.listeners = ltns
	end
	ltns[l] = true
end

function fila:remove_listener(l)
	local ltns = self.listeners
	if ltns then
		ltns[l] = nil
	end
end

function fila:knot(k, param)
	assert(k ~= nil,
		"knottee cannot be nil")

	local knots = self.knots
	if not knots then
		knots = {}
		self.knots = knots
	end
	
	local old = knots[k]

	knots[k] = param == nil
		and no_param or param

	local m = old == nil
		and "notify_knot"
		or "notify_reknot"
	event_rec(self, m, k, param)
	return self
end

local function try_unknot(self, k)
	local knots = self.knots
	if not knots then return end
	
	local p = knots[k]
	if p == nil then return end
	
	knots[k] = nil

	if p == no_param then p = nil end
	event_rec(self, "notify_unknot", k, p)
	return true
end

fila.try_unknot = try_unknot

function fila:unknot(k)
	assert(try_unknot(self, k),
		"knot not found")
	return self
end

local function raw_find(self, k)
	local ks = self.knots
	if not ks then return end
	
	local p = ks[k]
	if p == nil then return end
	if p == no_param then p = nil end
	return true, p
end

fila.raw_find = raw_find

function fila:find(k)
	local curr = self
	repeat
		local res, param = raw_find(curr, k)
		if res then
			return res, param
		end
		curr = curr.parent
	until not curr
end

function fila:get(k)
	local res, param = self:find(k)
	assert(res, "knot not found")
	return param
end

local function knot_iter(ks, k)
	k = next(ks, k)
	if k == nil then return nil end
	
	local p = ks[k]
	if p == no_param then p = nil end
	return k, p
end

function fila:iter_knots()
	local knots = self.knots
	if knots then
		return knot_iter, knots
	else
		return next, no_param
	end
end

function fila:lift()
	local p = self.parent
	if not p then return end

	local pks = p.knots
	if pks and next(pks) ~= nil then
		local ks = self.knots
		if ks then
			for k, p in pairs(pks) do
				if ks[k] == nil then
					ks[k] = p
				end
			end
		else
			ks = {}
			for k, p in pairs(pks) do
				ks[k] = p
			end
			self.knots = ks
		end
	end

	local pls = p.listeners
	if pls and next(pls) ~= nil then
		for l in pairs(pls) do
			local m = l["notify_detach"]
			if m then m(l, self) end
		end
	end
	
	self.parent = p.parent
	return self
end

function fila:detach()
	while self.parent do
		self:lift()
	end
	return self
end

function fila:reattach(new_parent)
	assert(getmetatable(new_parent) == fila,
		"invalid new_parent")
	if self.parent then
		self:detach()
	end
	add_child(new_parent, self)
	return self
end

function fila:reset()
	local children = self.children
	if children then
		for child in pairs(children) do
			child:reset()
		end
	end
	
	event(self, "notify_detach")
	
	local gs = self.groups
	if gs then
		for g in pairs(gs) do
			g:destroy()
		end
	end

	local parent = self.parent
	if parent then
		parent.children[self] = nil
	end
	
	for k, v in pairs(self) do
		if k ~= "hash" then
			self[k] = nil
		end
	end
	
	return self
end

local group = {}
group.__index = group

function raw_group(f, predicate)
	local es = {}
	
	local function select(f, es, p)
		local children = f.children
		if not children then
			return 0
		end
		
		local count = 0
		
		for c in pairs(children) do
			if p(c) then
				es[c] = true
				count = count + 1
			end
			count = count +
				select(c, es, p)
		end
		
		return count
	end
	
	local g = setmetatable({
		fila = f,
		entities = es,
		ent_count =
			select(f, es, predicate),
		cache = {},
		cache_dirty = true,
		add_cbs = {},
		update_cbs = {},
		remove_cbs = {}
	}, group)
	
	local gs = f.groups
	if not gs then
		gs = {}
		f.groups = gs
	end
	
	gs[g] = true
	return g
end

fila.raw_group = raw_group

function group:iter()
	local cache = self.cache
	
	if self.cache_dirty then
		local i = 1
		for e in pairs(self.entities) do
			cache[i] = e
			i = i + 1
		end
		for j = i, #cache do
			cache[i] = nil
		end
		self.cache_dirty = false
	end
	
	return pairs(cache)
end

function group:has(f)
	return self.entities[f]
end

function group:first()
	return next(self.entities)
end

function group:count()
	return self.ent_count
end

function group:on_add(c)
	assert(type(c) == "function",
		"invalid callback")
	self.add_cbs[c] = true
	return self
end

function group:on_add_iter(c)
	self:on_add(c)
	for i, f in self:iter() do
		c(self, f)
	end
end

function group:unlisten_add(c)
	self.add_cbs[c] = nil
	return self
end

function group:on_remove(c)
	assert(type(c) == "function",
		"invalid callback")
	self.remove_cbs[c] = true
	return self
end

function group:unlisten_remove(c)
	self.remove_cbs[c] = nil
	return self
end

function group:has_callbacks()
	return next(self.add_cbs)
		or next(self.remove_cbs)
end

function group:destroy()
	local es = self.entities
	local cbs = self.remove_cbs

	for e in pairs(es) do
		for c in pairs(cbs) do
			c(self, e)
		end
	end
	
	self.entities = nil
	self.cache = nil

	local f = self.fila
	f.groups[self] = nil
	f:remove_listener(self)
end

function group:is_destroyed()
	return self.entities == nil
end

local function grp_add(g, f)
	g.entities[f] = true
	g.ent_count = g.ent_count + 1
	
	for c in pairs(g.add_cbs) do
		c(g, f)
	end
	g.cache_dirty = true
end


local function grp_remove(g, f)
	g.entities[f] = nil
	g.ent_count = g.ent_count - 1
	
	for c in pairs(g.remove_cbs) do
		c(self, f)
	end
	
	g.cache_dirty = true
end

group.add = grp_add
group.remove = grp_remove

function fila:group(predicate)
	assert(type(predicate) == "function",
		"invalid predicate")
		
	local g =
		raw_group(self, predicate)
	local es = g.entities
	
	function g:notify_create(f)
		if predicate(f) then
			grp_add(self, f)
		end
	end
	
	function g:notify_detach(f)
		if es[f] then
			grp_remove(self, f)
		end
	end
	
	local function notify_knot(self, f, k, param)
		if predicate(f) then
			if not es[f] then
				grp_add(self, f)
			end
		elseif es[f] then
			grp_remove(self, f)
		end
	end
	
	group.notify_knot = notify_knot
	group.notify_reknot = notify_knot

	function group:notify_unknot(f, k, param)
		if predicate(f) then
			if not es[f] then
				grp_add(self, f)
			end
		elseif es[f] then
			grp_remove(self, f)
		end
	end
	
	self:add_listener(g)
	return g
end

-- event bus

local function init_ebus(self)
	-- fila subscriptions
	local knot_fs = {}
	local reknot_fs = {}
	local unknot_fs = {}
	local detach_fs = {}

	local f_subs = {
		knot = knot_fs,
		reknot = reknot_fs,
		unknot = unknot_fs,
		detach = detach_fs
	}
	
	-- knot-matching subscriptions
	local knot_ks = {}
	local reknot_ks = {}
	local unknot_ks = {}
	
	local k_subs = {
		knot = knot_ks,
		reknot = reknot_ks,
		unknot = unknot_ks
	}
	
	local function trig(subs, target, ...)
		local s = subs[target]
		if not s then return end
		for c in pairs(s) do
			c(target, ...)
		end
	end
	
	local listener = {}
	
	function listener:notify_knot(f, k, param)
		trig(knot_fs, f, k, param)
		trig(knot_ks, k, f, param)
	end
	
	function listener:notify_reknot(f, k, param)
		trig(reknot_fs, f, k, param)
		trig(reknot_ks, k, f, param)
	end
	
	function listener:notify_unknot(f, k, param)
		trig(unknot_fs, f, k, param)
		trig(unknot_ks, k, f, param)
	end
	
	function listener:notify_detach(f)
		trig(detach_fs, f)
		knot_fs[f] = nil
		reknot_fs[f] = nil
		unknot_fs[f] = nil
		detach_fs[f] = nil
	end
	
	self:add_listener(listener)
	
	function self:__ebus_args(a1, a2, c)
		assert(type(c) == "function",
			"invalid callback")
			
		local subs, target
		
		if type(a1) == "string" then
			subs = assert(k_subs[a1],
				"invalid event")
			target = a2
		else
			subs = assert(f_subs[a2],
				"invalid event")
			target = a1
			assert(getmetatable(a1) == fila,
				"invalid fila")
		end
		
		return subs, target, c
	end
end

function fila:__ebus_args(...)
	-- invoked if event bus is not
	-- initialized
	init_ebus(self)
	return self:__ebus_args(...)
end

function fila:on(a1, a2, c)
	local subs, target, callback =
		self:__ebus_args(a1, a2, c)

	local s = subs[target]
	if not s then
		s = {}
		subs[target] = s
	end
	
	s[callback] = true
	return self
end

function fila:unlisten(a1, a2, c)
	local subs, target, callback =
		self:__ebus_args(a1, a2, c)
	
	local s = subs[target]
	if not s then return self end
	
	s[callback] = nil
	return self
end

-- fast group

local function check_fg(g, ks)
	if #ks ~= #g:get_knottees() then
		return false
	end
	
	local k_table = g.k_table
	for i = 1, #ks do
		if not k_table[ks[i]] then
			return false
		end
	end
	return true
end

local function raw_fg(f, ks, hash)
	local k_table = {}
	for i = 1, #ks do
		local k = ks[i]
		k_table[k] = true
	end
	
	local g = raw_group(f, function(f)
		for i = 1, #ks do
			if not f:find(ks[i]) then
				return false
			end
		end
		return true
	end)
	
	g.k_table = k_table
	local es = g.entities

	local listener = {}

	function listener:notify_create(f)
		for i = 1, #ks do
			local k = ks[i]
			if not f:find(k) then
				return
			end
		end
		grp_add(g, f)
	end

	f:add_listener(listener)
	
	local function on_knot(new_k, f)
		for i = 1, #ks do
			local k = ks[i]
			if k ~= new_k
				and not f:find(k) then
				return
			end
		end
		grp_add(g, f)
	end
	
	local function on_unknot(k, f)
		if es[k] then
			grp_remove(g, f)
		end
	end
	
	for i = 1, #ks do
		local k = ks[i]
		f:on("knot", k, on_knot)
		f:on("unknot", k, on_unknot)
	end
	
	local function on_detach(f)
		grp_remove(g, f)
	end
	
	g:on_add_iter(function(g, e)
		f:on(e, "detach", on_detach)
	end)
	
	g:on_remove(function(g, e)
		f:unlisten(e, "detach", on_detach)
	end)
	
	function g:get_knottees()
		return ks
	end
	
	function g:destroy()
		group.destroy(g)

		f:remove_listener(listener)

		for i = 1, #ks do
			local k = ks[i]
			f:unlisten("knot", k, on_knot)
			f:unlisten("unknot", k, on_unknot)
		end
		
		local fgs = f.fast_groups
		local slot = fgs[hash]
		
		if getmetatable(slot) then
			fgs[hash] = nil
		else
			slot[self] = nil
			if not next(slot) then
				fgs[hash] = nil
			end
		end
	end
	
	return g
end

local function sort(a)
	for i=1,#a do
		local j = i
		while j > 1 and a[j-1] > a[j] do
			a[j],a[j-1] = a[j-1],a[j]
			j = j - 1
		end
	end
end

local function create_hash(ks)
	local t = {}
	for i = 1, #ks do
		if getmetatable(k) == fila then
			t[#t+1] = tostr(k:get_hash())
		else
			t[#t+1] = tostr(k)
		end
	end
	sort(t)
	local h = ""
	for i = 1, #t do
		h = h..t[i]
	end
	return h
end

function fila:fast_group(...)
	local knottees = {...}
	assert(#knottees > 0,
		"no knottee specified")
	
	local fgs = self.fast_groups
	if not fgs then
		fgs = {}
		self.fast_groups = fgs
	end
	
	local hash = create_hash(knottees)
	local slot = fgs[hash]
	if slot then
		if not getmetatable(slot) then
			-- collided groups
			for grp in pairs(slot) do
				if check_fg(grp, knottees) then
					return grp
				end
			end
			
			local g = raw_fg(self, knottees, hash)
			slot[g] = true
			return g
		elseif check_fg(slot, knottees) then
			return slot
		else
			-- hash collision!
			local g = raw_fg(self, knottees, hash)
			fgs[hash] = {
				[slot] = true,
				[g] = true
			}
			return g
		end
	end
	
	local g = raw_fg(self, knottees, hash)
	fgs[hash] = g
	
	return g
end

function fila:reactive_group(...)
	local g = self:fast_group(...)
	if g.reactive then return g end
	
	local react_cbs = {}
	
	function g:on_react(c)
		assert(type(c) == "function",
			"invalid callback")
		react_cbs[c] = true
		
		for i, f in g:iter() do
			c(g, f)
		end
		
		return self
	end
	
	function g:unlisten_react(c)
		react_cbs[c] = nil
		return self
	end
	
	local ks = g.k_table
	
	local function on_reknot(f, k)
		if ks[k] then
			for c in pairs(react_cbs) do
				c(g, f, k)
			end
		end
	end
	
	g:on_add_iter(function(g, f)
		self:on(f, "reknot", on_reknot)
		for c in pairs(react_cbs) do
			c(g, f)
		end
	end)
	
	g:on_remove(function(g, f)
		self:unlisten(f, "reknot", on_reknot)
	end)
	
	g.reactive = true
	return g
end

function fila:iter_fast_groups()
	local fgs = self.fast_groups
	if not fgs then
		return next, no_param
	end
	
	local fgs_key
	local slot, slot_key
	
	return function()
		if slot then
			slot_key = next(slot, slot_key)
			if slot_key then
				return slot_key
			end
		end
		
		fgs_key, slot = next(fgs, fgs_key)
		if not fgs_key then
			return nil
		end
		
		if not getmetatable(slot) then
			slot_key = next(slot)
			return slot_key
		else
			local g = slot
			slot = nil
			return g
		end
	end
end

function fila:clear_fast_groups()
	for g in self:iter_fast_groups() do
		if not g:has_callbacks() then
			g:destroy()
		end
	end
end

-- return fila
__gfx__
ccccccc8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cc777cc8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cc7cccc8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cc7c7cc8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cc7cccc8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cc7c7cc8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cc777cc8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ccccccc8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
