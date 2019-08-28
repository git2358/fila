[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-brightgreen.svg)](https://github.com/sicusa/fila/graphs/commit-activity)
[![License](https://img.shields.io/github/license/mashape/apistatus.svg)](https://en.wikipedia.org/wiki/MIT_License) 
[![Made With PICO-8](https://img.shields.io/badge/Made%20With-PICO--8-ff004d.svg?style=flat&logo=data%3Aimage%2Fpng%3Bbase64%2CiVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAAlUlEQVQ4jWP8v5gBFTxOR%2BVXPfuPwp8SxIjCt%2BBG4TIxUBkMfgNZGIyi0IRmoobZxxeo0rcPocp%2FEEEJ08HvZaobyPj%2FjTpqmLAeJM2EtgMo3MHvZeqnw9X%2FXVHSUdhnP5Qw%2Fc%2B7CUVDS%2BsWFH6QpuyIT4cMT8xQBJI%2B1aHwj1%2F3RgnTVJbrKGH29egxFPWD38tUNxAAun4liexlTtMAAAAASUVORK5CYII%3D)](https://www.lexaloffle.com/pico-8.php)

![PICO-Tween](img/logo.png)

Fila is a generalized PICO-8 framework derived from ECS paradigm and prototype-oriented programming. It allows developers to model both data and logic in an unprecedented way.

## Demo

``` lua
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
--   * parent's knots cannot be
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
--   callbacks each time when a
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
```