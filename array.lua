--[[
	array programming facilities

	these functions assume they are working with arrays of numbers
	most functions assume both args are the same length
]]

local path = (...):gsub("array", "")

local array = {}

-----------------------------------------------------------
-- creation
-----------------------------------------------------------

function array.zero(n, into)
	return array.fill_range(0, 1, n, into)
end

function array.fill(n, c, into)
	return array.fill_range(c, 1, n, into)
end

function array.copy(a, into)
	return array.copy_range(a, 1, #a, into)
end

-----------------------------------------------------------
-- ranged-based creation
-----------------------------------------------------------

function array.fill_range(c, from, to, into)
	into = into or {}
	for i=from,to do
		into[i] = c
	end
	return into
end

function array.copy_range(a, from, to, into)
	into = into or {}
	for i=from,to do
		into[i] = a[i]
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
-- linear algebra
-----------------------------------------------------------

function array.inner_product(a, b)
	local result = 0;
	for i=1,#a do
		result = result + a[i] * b[i]
	end
	return result
end

-----------------------------------------------------------
-- unit tests
-- TODO: provide better way to do in-file unit tests
-----------------------------------------------------------

function array.unit_tests()
	do
		-- Construction
		local zeros = array.zero(3)
		assert(#zeros == 3 and zeros[1]==0 and zeros[2]==0 and zeros[3]==0 and zeros[4]==nil)

		local ones = array.fill(3, 1)
		assert(#ones == 3 and ones[1]==1 and ones[2]==1 and ones[3]==1 and ones[4]==nil)
		
		local copy_ones = array.copy(ones)
		assert(ones ~= copy_ones and array.equals(copy_ones, ones))
	end
end

return array