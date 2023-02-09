return function(options)
    local RootPath = options.RootPath or WorldPath.."Dialog/"
    local VarsKey = options.VarsKey or "dialog"
    vars[VarsKey] = vars[VarsKey] or {}

    local mod = {
        RootPath = RootPath,
        ScriptsPath = RootPath.."Scripts/",
        GraphicsPath = RootPath.."Graphics/",
        TreesPath = RootPath.."Trees/",
        VarsKey = VarsKey,
    }

    local __DialogSystem = DialogSystem
    DialogSystem = mod

    mod.vars = function(character)
        return (character and vars[VarsKey][character]) or vars[VarsKey]
    end

    mod.func = dofile(mod.ScriptsPath.."func.lua")
    mod.anim = dofile(mod.ScriptsPath.."anim.lua")
    mod.cursors = {
        Pointer = dofile(mod.ScriptsPath.."cursors/Pointer.lua"),
        Underline = dofile(mod.ScriptsPath.."cursors/Underline.lua"),
        Highlight = dofile(mod.ScriptsPath.."cursors/Highlight.lua"),
        Sidelight = dofile(mod.ScriptsPath.."cursors/Sidelight.lua"),
    }
    mod.parse = dofile(mod.ScriptsPath.."parse.lua")
    mod.DefaultRenderer = dofile(mod.ScriptsPath.."DefaultRenderer.lua")
    mod.DefaultInputHandler = dofile(mod.ScriptsPath.."DefaultInputHandler.lua")
    mod.DialogTree = dofile(mod.ScriptsPath.."DialogTree.lua")
    mod.DialogMenu = dofile(mod.ScriptsPath.."DialogMenu.lua")

    DialogSystem = __DialogSystem

    return mod
end
