local jecs = require(script.Parent)
local world = jecs.World.new()

local A, B, C, D = world:entity(), world:entity(), world:entity(), world:entity()
local E, F, G, H = world:entity(), world:entity(), world:entity(), world:entity()
print("A", A)
print("B", B)
print("C", C)
print("D", D)
print("E", E)
print("F", F)
print("G", G)
print("H", H)

local common = 0
local N = 2^16-2
local archetypes = {}
local function flip() 
	return math.random() >= 0.5
end

local amountOfCombination = 0
for i = 1, N do 
	local entity = world:entity()
	local combination = ""

	if flip() then 
		combination ..= "2_"
		world:set(entity, B, { value = true})
	end
	if flip() then 
		combination ..= "3_"
		world:set(entity, C, { value = true})
	end
	if flip() then 
		combination ..= "4_"
		world:set(entity, D, { value = true})
	end
	if flip() then 
		combination ..= "5_"
		world:set(entity, E, { value = true})
	end
	if flip() then 
		combination ..= "6_"
		world:set(entity, F, { value = true})
	end
	if flip() then 
		combination ..= "7_"
		world:set(entity, G, { value = true})
	end
	if flip() then 
		combination ..= "8"
		world:set(entity, H, { value = true})
	end

	if #combination == 7 then 
		combination = "1_" .. combination
		common += 1
		world:set(entity, A, { value = true})
	end

	if combination:find("2") 
		and combination:find("3") 
		and combination:find("4")
		and combination:find("6")
	then 
		amountOfCombination += 1
	end
	archetypes[combination] = true
end

return function()
	describe("World", function()
		it("should add component", function()
			local id = world:entity()
			world:set(id, A, true)
			world:set(id, B, 1)

			local id1 = world:entity()
			world:set(id1, A, "hello")
			expect(world:get(id, A)).to.equal(true)
			expect(world:get(id, B)).to.equal(1)
			expect(world:get(id1, A)).to.equal("hello")
		end)

		it("should remove component", function() 
			local Tag = world:entity()
			local entities = {}
			for i = 1, 10 do 
				local entity = world:entity()
				entities[i] = entity
				world:set(entity, Tag)
			end

			for i = 1, 10 do 
				local entity = entities[i]
				expect(world:get(entity, Tag)).to.equal(nil)
				world:remove(entity, Tag)
			end
			
		end)

		it("should override component data", function() 
		
			local id = world:entity()
			world:set(id, A, true)
			expect(world:get(id, A)).to.equal(true)

			world:set(id, A, false)
			expect(world:get(id, A)).to.equal(false)

		end)

		it("should not query a removed component", function() 
			local Tag = world:entity()
			local AnotherTag = world:entity()

			local entity = world:entity()
			world:set(entity, Tag)
			world:set(entity, AnotherTag)
			world:remove(entity, AnotherTag)

			local added = 0
			for e, t, a in world:query(Tag, AnotherTag) do 
				added += 1
			end
			expect(added).to.equal(0)
		end)

		it("should query correct number of compatible archetypes", function()
			local added = 0
			for _ in world:query(B, C, D, F) do
				added += 1
			end        
			expect(added).to.equal(amountOfCombination)
		end)

		it("should not query poisoned players", function() 
			local Player = world:entity()
			local Health = world:entity()
			local Poison = world:entity()

			local one = world:entity()
			world:set(one, Player, { name = "alice"})
			world:set(one, Health, 100)
			world:set(one, Poison)

			local two = world:entity()
			world:set(two, Player, { name = "bob"})
			world:set(two, Health, 90)

			local withoutCount = 0
			for _id, _player in world:query(Player):without(Poison) do
				withoutCount += 1
			end

			expect(withoutCount).to.equal(1)
		end)

		it("should allow calling world:entity before world:component", function() 
			for _ = 1, 256 do 
				world:entity()
			end	
			expect(world:component()).to.be.ok()
		end)

		it("should skip iteration", function() 
			local Position, Velocity = world:entity(), world:entity()
			local e = world:entity()
			world:set(e, Position, Vector3.zero)
			world:set(e, Velocity, Vector3.one)
			local added = 0
			for i in world:query(Position):without(Velocity) do
				added += 1
			end        
			expect(added).to.equal(0)
		end)

		it("track changes", function() 
			local Position = world:entity()

			local moving = world:entity()
			world:set(moving, Position, Vector3.new(1, 2, 3))

			local count = 0

			for e, position in world:observer(Position).event(jecs.ON_ADD) do 
				count += 1
				expect(e).to.equal(moving)
				expect(position).to.equal(Vector3.new(1, 2, 3))
			end
			expect(count).to.equal(1)
		end)

		it("should query all matching entities", function()

			local world = jecs.World.new()
			local A = world:component()
			local B = world:component()

			local entities = {}
			for i = 1, N do
				local id = world:entity()


				world:set(id, A, true)
				if i > 5 then world:set(id, B, true) end
				entities[i] = id
			end

			for id in world:query(A) do
				local i = table.find(entities, id)
				expect(i).to.be.ok()
				table.remove(entities, i)
			end

			expect(#entities).to.equal(0)
		end)

		it("should query all matching entities when irrelevant component is removed", function()

			
			local world = jecs.World.new()
			local A = world:component()
			local B = world:component()
	
			local entities = {}
			for i = 1, N do
				local id = world:entity()
	
				world:set(id, A, true)
				world:set(id, B, true)
				if i > 5 then world:remove(id, B, true) end
				entities[i] = id
			end
	
			local added = 0
			for id in world:query(A) do
				added += 1
				local i = table.find(entities, id)
				expect(i).to.be.ok()
				table.remove(entities, i)
			end
	
			expect(added).to.equal(N)
		end)

		it("should query all entities without B", function() 
			local world = jecs.World.new()
			local A = world:component()
			local B = world:component()
	
			local entities = {}
			for i = 1, N do
				local id = world:entity()
	
				world:set(id, A, true)
				if i < 5 then
					entities[i] = id
				else
					world:set(id, B, true)
				end
				
			end
	
			for id in world:query(A):without(B) do
				local i = table.find(entities, id)
				expect(i).to.be.ok()
				table.remove(entities, i)
			end
	
			expect(#entities).to.equal(0)
		end)

		it("should allow setting components in arbitrary order", function() 
			local world = jecs.World.new()

			local Health = world:entity()
			local Poison = world:component()

			local id = world:entity()
			world:set(id, Poison, 5)
			world:set(id, Health, 50)

			expect(world:get(id, Poison)).to.equal(5)
		end)

		it("Should allow deleting components", function() 
			local world = jecs.World.new()

			local Health = world:entity()
			local Poison = world:component()

			local id = world:entity()
			world:set(id, Poison, 5)
			world:set(id, Health, 50)
			world:delete(id)

			expect(world:get(id, Poison)).to.never.be.ok()
			expect(world:get(id, Health)).to.never.be.ok()
		end)
	end)
end