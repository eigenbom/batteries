--[[
	matrix math, linear algebra
]]

local path = (...):gsub("mat4", "")
local vec3 = require( path .. "vec3")
local class = require(path .. "class")
local tablex = require(path .. "tablex")
local assert = require(path .. "assert")
local array  = require(path .. "array")
local unpack = table.unpack or unpack

local mat4 = class({
	name = "mat4",
})

-- returns the index into a flat-array of matrix 4x4 values stored in column-major order
local function index(row, col)
	return row+(col-1)*4
end

--stringification
function mat4:__tostring()
	local columns = {}
	for col=1,4 do
		local k = index(1, col)
		table.insert(columns, string.format("(%.2f, %.2f, %.2f, %.2f)", self.data[k], self.data[k+1], self.data[k+2], self.data[k+3]))
	end
	return "(" .. table.concat(columns, ", ") .. ")"
end

-- create a new matrix given column order values m_ij
-- if data_or_m11 is nil this creates the zero matrix
-- if data_or_m11 is a table this is used directly as the data
function mat4:new(data_or_m11, m21, m31, m41, m12, m22, m32, m42, m13, m23, m33, m43, m14, m24, m34, m44)
	if data_or_m11 == nil then
		self.data = array.zero(16)
	elseif type(data_or_m11) == "number" then
		self:sset(data_or_m11, m21, m31, m41, m12, m22, m32, m42, m13, m23, m33, m43, m14, m24, m34, m44)
	elseif type(data_or_m11) == "table" then
		self.data = data_or_m11
	else
		error("Unsupported constructor argument " .. tostring(data_or_m11))
	end
end

--explicit ctors
function mat4:copy()
	return mat4(array.copy(self.data))
end

function mat4:zero()
	return mat4()
end

function mat4:one()
	return mat4(1,1,1,1, 1,1,1,1, 1,1,1,1, 1,1,1,1)
end

function mat4:identity()
	return mat4(1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1)
end

--modify
function mat4:sset(m11, m21, m31, m41, m12, m22, m32, m42, m13, m23, m33, m43, m14, m24, m34, m44)
	assert( m11 and m21 and m31 and m41 and m12 and m22 and m32 and m42 and m13 and m23 and m33 and m43 and m14 and m24 and m34 and m44 )
	self.data = array.pack(self.data or {}, m11, m21, m31, m41, m12, m22, m32, m42, m13, m23, m33, m43, m14, m24, m34, m44)
	return self
end

function mat4:mset(m)
	return array.copy(m.data, self.data)
end

--[[
function mat4:swap(m)
	local data = tablex.copy(m.data)
	self:mset(data)
	m:sset(unpack(data))
	return self
end
--]]


function mat4:get(row, col)
	return self.data[index(row,col)]
end

function mat4:set(row, col, value)
	self.data[index(row,col)] = value
	return self
end

-----------------------------------------------------------
--arithmetic
-----------------------------------------------------------

--immediate mode

function mat4:addi(m)
	if type(m) == "number" then
		array.sadd(self.data,m,self.data)
	else
		array.add(self.data,m,self.data)
	end
	return self
end

function mat4:subi(m)
	if type(m) == "number" then
		array.ssub(self.data,m,self.data)
	else
		array.sub(self.data,m,self.data)
	end
	return self
end

function mat4:elementwise_muli(m)
	if type(m) == "number" then
		array.smul(self.data,m,self.data)
	else
		array.mul(self.data,m,self.data)
	end
	return self
end

function mat4:elementwise_divi(m)
	if type(m) == "number" then
		array.sdiv(self.data,m,self.data)
	else
		array.div(self.data,m,self.data)
	end
	return self
end

-- Matrix product
function mat4:mmuli(m)
	return self:copy():mul(m, self)
end

-- non-immediate mode

function mat4:add(m)
	if type(m) == "number" then
		return mat4(array.sadd(self.data,m))
	else
		return mat4(array.add(self.data,m))
	end
end

function mat4:sub(m)
	if type(m) == "number" then
		return mat4(array.ssub(self.data,m))
	else
		return mat4(array.sub(self.data,m))
	end
end

function mat4:elementwise_mul(m)
	if type(m) == "number" then
		return mat4(array.smul(self.data,m))
	else
		return mat4(array.mul(self.data,m))
	end
end

function mat4:elementwise_div(m)
	if type(m) == "number" then
		return mat4(array.sdiv(self.data,m))
	else
		return mat4(array.div(self.data,m))
	end
end

-- Matrix product
function mat4:mmul(m, into)
	assert:type(m, "mat4", "mat4.mmuli - m", 1)
	into = into or mat4()
	for col=1,4 do
		for row=1,4 do
			into:set(row, col, self:get(row,1)*m:get(1,col) + self:get(row,2)*m:get(2,col) + self:get(row,3)*m:get(3,col) + self:get(row,4)*m:get(4,col))
		end
	end
	return into
end

-- Matrix-Vector product
function mat4:vmul(v, into)
	if not into then into = vec3:zero() end

	assert:type(v, "vec3", "mat4.vmul - v", 1)
	assert:type(into, "vec3", "mat4.vmul - into", 1)

	return into:sset(
		self.data[1]*v.x + self.data[5]*v.y + self.data[9]*v.z + self.data[13],
		self.data[2]*v.x + self.data[6]*v.y + self.data[10]*v.z + self.data[14],
		self.data[3]*v.x + self.data[7]*v.y + self.data[11]*v.z + self.data[15] )
end

-----------------------------------------------------------
--equality comparison
-----------------------------------------------------------

--threshold for equality in each dimension
local EQUALS_EPSILON = 1e-9

--true if a and b are functionally equivalent
function mat4.equals(a, b)
	for i=1,16 do
		if math.abs(a.data[i] - b.data[i]) > EQUALS_EPSILON then 
			return false
		end
	end
	return true
end

--true if a and b are not functionally equivalent
function mat4.nequals(a, b)
	return not mat4.equals(a,b)
end

-----------------------------------------------------------
--linear algebra
-----------------------------------------------------------

-- Matrix product of two 16-element arrays representing 4x4 column-major matrices
function mat4.multiply(a, b, into)
	assert(#a==16)
	assert(#b==16)
	-- If into is a or b then need a temporary to store the results
	local tmp = (a == into or b == into) and {}
	into = into or mat4()
	local target = tmp or into
	for col=1,4 do
		for row=1,4 do
			target[index(row,col)] = a[index(row,1)]*b[index(1,col)] + a[index(row,2)]*b[index(2,col)] + a[index(row,3)]*b[index(3,col)] + a[index(row,4)]*b[index(4,col)]
		end
	end
	if tmp then
		array.copy(target, into)
		-- free tmp
	end
	return into
end

-- Matrix-Vector product
function mat4.vector_multiply(a, v, into)
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
--geometric transforms
-----------------------------------------------------------

-- create a transformation matrix that translates in the given vector
function mat4.translation(v_or_x,y,z)
	if type(v_or_x)~="number" then
		assert:type(v_or_x, "vec3", "mat4.translation - v_or_x", 1)
		v_or_x, y, z = v_or_x:unpack()
	end
	return mat4(1,0,0,0, 0,1,0,0, 0,0,1,0, v_or_x,y,z,1)
end

-- create a transformation matrix that scales in the given dimensions
function mat4.scale(v_or_x,y,z)
	if type(v_or_x)~="number" then
		assert:type(v_or_x, "vec3", "mat4.scale - v_or_x", 1)
		v_or_x, y, z = v_or_x:unpack()
	end
	return mat4(v_or_x,0,0,0, 0,y,0,0, 0,0,z,0, 0,0,0,1)
end

-- create a transformation matrix that rotates around an axis and angle
function mat4.rotation(axis, angle)
	assert:type(axis, "vec3", "mat4.rotation - axis", 1)
	local l,m,n = axis:unpack()
	local s = math.sin(angle)
	local c = math.cos(angle)
	local oc = 1-c
	return mat4(
		l*l*oc+c, l*m*oc+n*s, l*n*oc-m*s, 0,
		m*l*oc-n*s, m*m*oc+c, m*n*oc-l*s, 0,
		n*l*oc+m*s, n*m*oc-l*s, n*n*oc+c, 0,
		0, 0, 0, 1)
end


-----------------------------------------------------------
-- unit tests
-- TODO: provide better way to do in-file unit tests
-----------------------------------------------------------

function mat4.unit_tests()
	do
		local ident = mat4( 1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1 )
		assert(table.concat(ident.data)=="1000010000100001")
		local sequence = mat4( 1,2,3,4, 5,6,7,8, 9,10,11,12, 13,14,15,16 )
		assert(table.concat(sequence.data)=="12345678910111213141516")
	end

	do
		-- Matrix Vector multiplication
		local rotate90 = mat4( 0,1,0,0, -1,0,0,0, 0,0,1,0, 0,0,0,1 )
		assert(vec3.equals(rotate90:vmul(vec3(1,0,0)),vec3(0,1,0)))
		assert(vec3.equals(rotate90:vmul(vec3(0,1,0)),vec3(-1,0,0)))
	end

	do
		-- Matrix multiplication
		local rotate90 = mat4( 0,1,0,0, -1,0,0,0, 0,0,1,0, 0,0,0,1 )
		local rotateNeg90 = mat4( 0,-1,0,0, 1,0,0,0, 0,0,1,0, 0,0,0,1 )
		local transform = rotate90:mmul(rotateNeg90)
		assert(mat4.equals(transform, mat4:identity()))
	end

	do
		-- Transforms
		local I = mat4:identity()
		local T = mat4.translation
		local R = mat4.rotation
		local S = mat4.scale
		assert(vec3.equals(T(1,0,0):vmul(vec3:zero()),vec3(1,0,0)))
		assert(mat4.equals(T(1,0,0):mmul(T(-1,0,0)),I))
		assert(mat4.equals(R(vec3(0,0,1),math.pi/2), mat4( 0,1,0,0, -1,0,0,0, 0,0,1,0, 0,0,0,1)))
	end

	print("mat4 tests passed")
end

return mat4