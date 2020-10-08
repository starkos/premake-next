local Dom = declareType('Dom')

Dom.Project = doFile('./src/project.lua', Dom)
Dom.Workspace = doFile('./src/workspace.lua', Dom)

return Dom
