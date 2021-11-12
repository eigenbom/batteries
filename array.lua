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

function array.generate(n, f)
	local tbl = {}
	for i=1,n do
		table.insert(tbl, f(i))
	end
	return tbl
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

-- TODO: function array.cross_product(a, b)

function array.matrix_product(a, b, into)
	if #a==16 and #b==16 then
		return array.matrix_product_mat4_mat4(a, b, into)
	elseif #a==16 and #b==3 then
		return array.matrix_product_mat4_vec3(a, b, into)
	else
		error(string.format("Unsupported array lengths %d and %d", #a, #b))
	end
end

-- Matrix product of two 4x4 matrices flattened in column-major order
function array.matrix_product_mat4_mat4(a, b, into)
	assert(#a==16)
	assert(#b==16)
	local function index(row, col)
		return row+(col-1)*4
	end
	-- If into is a or b then need a temporary to store the results
	local tmp = (a == into or b == into) and {}
	into = into or {}
	local target = tmp or into
	for col=1,4 do
		for row=1,4 do
			target[index(row,col)] = a[index(row,1)]*b[index(1,col)] + a[index(row,2)]*b[index(2,col)] + a[index(row,3)]*b[index(3,col)] + a[index(row,4)]*b[index(4,col)]
		end
	end
	if tmp then
		array.copy(target, into)
		-- can free tmp
	end
	return into
end

-- Product of a 4x4 matrix flattened in column-major order and a 3 element vector
function array.matrix_product_mat4_vec3(a, v, into)
	assert(#a==16)
	assert(#v==3)
	local x, y, z =
		a[1]*v[1] + a[5]*v[2] + a[9]*v[3] + a[13],
		a[2]*v[1] + a[6]*v[2] + a[10]*v[3] + a[14],
		a[3]*v[1] + a[7]*v[2] + a[11]*v[3] + a[15]
	if into then
		return array.pack(into, x, y, z)
	else
		return table.pack(x,y,z)
	end
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

		local ident = {1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1}
		math.randomseed(0)
		local random_unit = function() return math.random() end
		local random_mat4 = array.generate(16, random_unit)
		local result = array.matrix_product(ident, random_mat4)
		assert(array.almost_equals(result, random_mat4))
		local random_vec3 = array.generate(3, random_unit)
		assert(array.almost_equals(random_vec3, array.matrix_product(ident, random_vec3)))

	end

	print("array tests passed")
end

return array