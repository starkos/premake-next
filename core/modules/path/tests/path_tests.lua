local path = require('path')

local PathTests = test.declare('PathTests')

-- path.join() --

function PathTests.join_addsSeparator_onRelativePath()
	test.isEqual('p1/p2', path.join('p1', 'p2'))
end

function PathTests.join_removesTrailingSeparatorFromRoot()
	test.isEqual('p1/p2', path.join('p1/', 'p2'))
end

function PathTests.join_removesSequentialSeparators()
	test.isEqual('p1/p2/p3', path.join('p1', 'p2//p3'))
end

function PathTests.join_replacesRoot_onAbsoluteUnixPath()
	test.isEqual('/p2', path.join('p1', '/p2'))
end

function PathTests.join_replacesRoot_onAbsoluteWindowsPath()
	test.isEqual('C:/p2', path.join('p1', 'C:/p2'))
end

function PathTests.join_replacesRoot_onEnvVar()
	test.isEqual('$ORIGIN', path.join('foo/bar', '$ORIGIN'))
end

function PathTests.join_replacesRoot_onWindowsEnvVar()
	test.isEqual('%ROOT%/foo', path.join('foo/bar', '%ROOT%/foo'))
end

function PathTests.join_appends_onPremakeToken()
	test.isEqual('foo/bar/%{test}/foo', path.join('foo/bar', '%{test}/foo'))
end

function PathTests.join_toCurrentDirectory()
	test.isEqual('p2', path.join('.', 'p2'))
end

function PathTests.join_removesFromRoot_onUpDir()
	test.isEqual('p1', path.join('p1/p2', '..'))
end

function PathTests.join_usesCwd_ifUpDirClearsRoot()
	test.isEqual('.', path.join('p1/p2', '../..'))
end

function PathTests.join_addsUpDirs_ifUpDirGoesPastRoot()
	test.isEqual('../..', path.join('p1', '../../..'))
end

function PathTests.join_joinsPath_withUpDirs()
	test.isEqual('../../../../foo', path.join('../../', '../../foo'))
end

function PathTests.join_onUpToBase()
	test.isEqual('foo', path.join('p1/p2/p3', '../../../foo'))
end

function PathTests.join_ignoreLeadingDots()
	test.isEqual('p1/p2/foo', path.join('p1/p2', '././foo'))
end

function PathTests.join_ignoresNilParts()
	test.isEqual('p2', path.join(nil, 'p2', nil))
end

function PathTests.join_onMoreThanTwoParts()
	test.isEqual('p1/p2/p3', path.join('p1', 'p2', 'p3'))
end

function PathTests.join_removesTrailingSlash()
	test.isEqual('p1/p2', path.join('p1', 'p2/'))
end

function PathTests.join_ignoresEmptyParts()
	test.isEqual('p2', path.join('', 'p2', ''))
end

function PathTests.join_canJoinBareSlash()
	test.isEqual('/Users', path.join('/', 'Users'))
end

function PathTests.join_keepsLeadingEnvVar()
	test.isEqual('$(ProjectDir)/../../Bin', path.join('$(ProjectDir)', '../../Bin'))
end

function PathTests.join_keepsInternalEnvVar()
	test.isEqual('$(ProjectDir)/$(TargetName)/../../Bin', path.join('$(ProjectDir)/$(TargetName)', '../../Bin'))
end

function PathTests.join_keepsComplexInternalEnvVar()
	test.isEqual('$(ProjectDir)/myobj_$(Arch)/../../Bin', path.join('$(ProjectDir)/myobj_$(Arch)', '../../Bin'))
end

function PathTests.join_keepsRecursivePattern()
	test.isEqual('p1/**.lproj/../p2', path.join('p1/**.lproj', '../p2'))
end

function PathTests.join_removesSingleDot()
	test.isEqual('p2', path.join('p1/.', '../p2'))
end
