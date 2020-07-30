local Store = require('store')

local StoreTests = test.declare('StoreTests')

local store

function StoreTests.setup()
	store = Store.new()
end


---
-- `new()` should return an object and not crash.
---

function StoreTests.new_returnsObject()
	test.isNotNil(store)
end


---
-- `query()` should return an object and not crash. See `test_query.lua` for
-- tests of the returned Query object.
---

function StoreTests.query_returnsObject()
	test.isNotNil(store:query())
end
