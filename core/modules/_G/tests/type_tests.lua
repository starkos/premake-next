local TypeTests = test.declare('TypeTests', 'types')


function TypeTests.declareType_associatesClassMethods()
	local TestType = declareType('TestType')

	function TestType.testMethod(self)
		return self.x
	end

	local instance = instantiateType(TestType, {
		x = true
	})

	test.isTrue(instance:testMethod())
end


function TypeTests.declareType_supportsInheritance()
	local BaseType = declareType('BaseType')

	function BaseType.testMethod(self)
		return self.x
	end

	local DerivedType = declareType('DerivedType', BaseType)

	local instance = instantiateType(DerivedType, {
		x = true
	})

	test.isTrue(instance:testMethod())
end

