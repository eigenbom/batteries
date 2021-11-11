--[[
	array programming facilities

	these functions operate on arrays of numbers, such as vectors and flattened matrices
]]

local path = (...):gsub("array", "")

local array = {}

-----------------------------------------------------------
-- creation
-----------------------------------------------------------

function array.zero(n, into)
	return array.fill_range(0, into or {}, 1, n)
end

function array.fill(n, c, into)
	return array.fill_range(c, into or {}, 1, n)
end

function array.copy(a, into)
	return array.copy_range(a, 1, into or {}, 1, #a)
end

-----------------------------------------------------------
-- modification
-----------------------------------------------------------

function array.pack(into, ...)
	return array.pack_range(into, 1, ...)
end

function array.pack_range(into, index, ...)
	for i=1,select("#", ...) do
		into[index+i-1] = select(i, ...)
	end
	return into
end

-- ranged-based modification

function array.fill_range(c, into, index, count)
	for i=0,count-1 do
		into[index+i] = c
	end
	return into
end

function array.copy_range(a, a_index, into, into_index, count)
	for i=0,count-1 do
		into[into_index+i] = a[a_index+i]
	end
	return into
end

-----------------------------------------------------------
-- arithmetic
-----------------------------------------------------------

function array.add(a, b, into)
	into = into or {}
	for i=1,#a do
		into[i] = a[i] + b[i]
	end
	return into
end

function array.sub(a, b, into)
	into = into or {}
	for i=1,#a do
		into[i] = a[i] - b[i]
	end
	return into
end

function array.mul(a, b, into)
	into = into or {}
	for i=1,#a do
		into[i] = a[i] * b[i]
	end
	return into
end

function array.div(a, b, into)
	into = into or {}
	for i=1,#a do
		into[i] = a[i] / b[i]
	end
	return into
end

function array.sadd(a, b, into)
	into = into or {}
	for i=1,#a do
		into[i] = a[i] + b
	end
	return into
end

function array.ssub(a, b, into)
	into = into or {}
	for i=1,#a do
		into[i] = a[i] - b
	end
	return into
end

function array.smul(a, b, into)
	into = into or {}
	for i=1,#a do
		into[i] = a[i] * b
	end
	return into
end

function array.sdiv(a, b, into)
	into = into or {}
	for i=1,#a do
		into[i] = a[i] / b
	end
	return into
end

-----------------------------------------------------------
--equality comparison
-----------------------------------------------------------

local EQUALS_EPSILON = 1e-9

--true if the ranges a[1,#a] and b[1,#a] are equal
function array.equals(a, b)
	for i=1,#a do
		if a[i] ~= b[i] then
			return false
		end
	end
	return true
end

--true if the ranges a[1,#a] and b[1,#a] are within EQUALS_EPSILON
--also see array.equals()
function array.almost_equals(a, b)
	for i=1,#a do
		if math.abs(a[i] - b[i]) > EQUALS_EPSILON then
			return false
		end
	end
	return true
end

-----------------------------------------------------------
-- functional operations
-----------------------------------------------------------

-- see functional.lua

-----------------------------------------------------------
-- linear algebra
-----------------------------------------------------------

-- Vector length
function array.length(a)
	return math.sqrt(array.inner_product(a, a))
end

function array.length_squared(a)
	return array.inner_product(a, a)
end

function array.inner_product(a, b)
	local result = 0
	for i=1,#a do
		result = result + a[i] * b[i]
	end
	return result
end

function array.normalise(a, into)
	return array.sdiv(a, array.length(a), into)
end

-----------------------------------------------------------
-- unit tests
-- TODO: provide better way to do in-file unit tests
-----------------------------------------------------------

function array.unit_tests()
	do
		-- creation
		local zeros = array.zero(3)
		assert(#zeros == 3 and zeros[1]==0 and zeros[2]==0 and zeros[3]==0 and zeros[4]==nil)

		local ones = array.fill(3, 1)
		assert(#ones == 3 and ones[1]==1 and ones[2]==1 and ones[3]==1 and ones[4]==nil)
		
		local copy_ones = array.copy(ones)
		assert(ones ~= copy_ones and array.equals(copy_ones, ones))

	end

	do
		-- modification
		local a = table.pack(1,2,3,4,5)
		array.pack(a, 2,3,4,5,6)
		array.pack_range(a, 3, 0,0)
		assert(array.equals(a, {2,3,0,0,6}))

		local mostly_zeros = array.zero(8)
		array.fill_range(1, mostly_zeros, 3, 3)
		assert(table.concat(mostly_zeros)=="00111000")

		local mostly_ones = array.copy_range(mostly_zeros,3,{},1,4)
		assert(table.concat(mostly_ones)=="1110")
	end

	do
		-- Arithmetic
		local a = { 1,2,3 }
		local b = { 4,5,6 }
		assert(array.equals(array.add(a,b),{5,7,9}))
		assert(array.equals(array.sub(a,b),{-3,-3,-3}))
		assert(array.equals(array.mul(a,b),{4,10,18}))
		assert(array.almost_equals(array.div(a,b),{.25,.4,.5}))

		assert(array.equals(array.sadd(a,1),{2,3,4}))
		assert(array.equals(array.ssub(a,1),{0,1,2}))
		assert(array.equals(array.smul(a,2),{2,4,6}))
		assert(array.almost_equals(array.sdiv(a,2),{.5,1,1.5}))
	end

	do
		-- Linear Algebra
		local x_axis = { 1,0,0 }
		local y_axis = { 0,1,0 }
		local z_axis = { 0,0,1 }
		assert(array.length(x_axis)==1)
		assert(array.almost_equals(x_axis, array.normalise(x_axis)))
		assert(array.length_squared(array.add(x_axis,y_axis))==2)
		assert(array.inner_product(x_axis,x_axis)==1)
		assert(array.inner_product(x_axis,y_axis)==0)
	end

	print("array tests passed")
end

return array