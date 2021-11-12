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

function mat4:swap(m)
	self.data, m.data = m.data, self.data
	return self
end

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
		return mat4(array.sadd(self.data, m))
	else
		return mat4(array.add(self.data, m.data))
	end
end

function mat4:sub(m)
	if type(m) == "number" then
		return mat4(array.ssub(self.data,m))
	else
		return mat4(array.sub(self.data, m.data))
	end
end

function mat4:elementwise_mul(m)
	if type(m) == "number" then
		return mat4(array.smul(self.data,m))
	else
		return mat4(array.mul(self.data, m.data))
	end
end

function mat4:elementwise_div(m)
	if type(m) == "number" then
		return mat4(array.sdiv(self.data,m))
	else
		return mat4(array.div(self.data, m.data))
	end
end

-- Matrix product
function mat4:mmul(m, into)
	assert:type(m, "mat4", "mat4.mmuli - m", 1)
	if into then
		assert:type(into, "mat4", "mat4.mmuli - into", 1)
	end
	local result = array.matrix_product_mat4_mat4(self.data, m.data, into and into.data)
	return into or mat4(result)
end

-- Matrix-Vector product
function mat4:vmul(v, into)
	assert:type(v, "vec3", "mat4.vmul - v", 1)
	if into then
		assert:type(into, "vec3", "mat4.vmul - into", 1)
	end

	local result = array.matrix_product_mat4_vec3(self.data, {v.x, v.y, v.z})
	return into and into:sset(result[1],result[2],result[3]) or vec3(tablex.unpack3(result))
end

-----------------------------------------------------------
--equality comparison
-----------------------------------------------------------

--true if a and b are functionally equivalent
function mat4.equals(a, b)
	return array.almost_equals(a.data, b.data)
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
-- operator overloads
-----------------------------------------------------------

-- Add operators to mat4
-- NOTE: These are opt-in as they generate garbage like the non-immediate functions
local function add_operator_overload(mt)
	mt.__add = mat4.add
	mt.__mul = function( self, value )
		if type(value) == "number" then
			return self:elementwise_mul(value)
		elseif value:type() == "mat4" then
			return self:mmul( value )
		elseif value:type() == "vec3" then
			return self:vmul( value )
		else
			error("unsupported value type " .. type(value))
		end
	end
end

-----------------------------------------------------------
-- unit tests
-- TODO: provide better way to do in-file unit tests
-----------------------------------------------------------

function mat4.unit_tests()
	do
		-- creation
		local ident = mat4( 1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1 )
		assert(table.concat(ident.data)=="1000010000100001")
		local sequence = mat4( 1,2,3,4, 5,6,7,8, 9,10,11,12, 13,14,15,16 )
		assert(table.concat(sequence.data)=="12345678910111213141516")
		ident:swap(sequence)
		assert(table.concat(ident.data)=="12345678910111213141516")
		assert(table.concat(sequence.data)=="1000010000100001")
	end

	do
		-- arithmetic
		local z = mat4:zero()
		local sequence = mat4( 1,2,3,4, 5,6,7,8, 9,10,11,12, 13,14,15,16 )
		assert(mat4.equals(sequence, z:add(sequence)))
		assert(mat4.equals(sequence:add(sequence), sequence:elementwise_mul(2)))
	end

	do
		-- matrix and vector multiplication
		local rotate90 = mat4( 0,1,0,0, -1,0,0,0, 0,0,1,0, 0,0,0,1 )
		assert(vec3.equals(rotate90:vmul(vec3(1,0,0)),vec3(0,1,0)))
		assert(vec3.equals(rotate90:vmul(vec3(0,1,0)),vec3(-1,0,0)))
		
		local rotateNeg90 = mat4( 0,-1,0,0, 1,0,0,0, 0,0,1,0, 0,0,0,1 )
		local transform = rotate90:mmul(rotateNeg90)
		assert(mat4.equals(transform, mat4:identity()))
	end

	do
		-- Transforms
		local I = mat4:identity()
		local Z = mat4:zero()
		local T = mat4.translation
		local R = mat4.rotation
		local S = mat4.scale
		assert(vec3.equals(T(1,0,0):vmul(vec3:zero()),vec3(1,0,0)))
		assert(mat4.equals(T(1,0,0):mmul(T(-1,0,0)),I))
		assert(mat4.equals(R(vec3(0,0,1),math.pi/2), mat4( 0,1,0,0, -1,0,0,0, 0,0,1,0, 0,0,0,1)))
		assert(vec3.equals(S(2,0,0):vmul(vec3(1,2,3)),vec3(2,0,0)))
		assert(vec3.equals(S(2,3,4):vmul(vec3(1,2,3)),vec3(2,6,12)))
		local scale_zero = S(1,0,0):mmul(S(0,1,0))
		for row=1,4 do 
			for col=1,4 do
				local val = row==4 and col==4 and 1 or 0
				assert(scale_zero:get(row,col)==val)
			end
		end
	end

	do
		-- operator overloads
		add_operator_overload(mat4)
		local z = mat4:zero()
		local shift_x = mat4.translation(1,0,0)
		local sum = z + shift_x
		assert(shift_x ~= sum and mat4.equals(sum, shift_x))

		-- transforms again, but now with * overload
		local I = mat4:identity()
		local Z = mat4:zero()
		local T = mat4.translation
		local R = mat4.rotation
		local S = mat4.scale
		assert(vec3.equals(T(1,0,0) * vec3:zero(), vec3(1,0,0)))
		assert(mat4.equals(T(1,0,0) * T(-1,0,0), I))
		assert(mat4.equals(R(vec3(0,0,1),math.pi/2), mat4( 0,1,0,0, -1,0,0,0, 0,0,1,0, 0,0,0,1)))
		assert(vec3.equals(S(2,0,0) * vec3(1,2,3), vec3(2,0,0)))
		assert(vec3.equals(S(2,3,4) * vec3(1,2,3), vec3(2,6,12)))
		local scale_zero = S(1,0,0) * S(0,1,0)
		for row=1,4 do 
			for col=1,4 do
				local val = row==4 and col==4 and 1 or 0
				assert(scale_zero:get(row,col)==val)
			end
		end
	end

	print("mat4 tests passed")
end

return mat4