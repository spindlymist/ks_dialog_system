return function(options)
    -- Configuration -----------------------------------------------------------
    local RootPath = options.RootPath or WorldPath.."Dialog/"
    local VarsKey = options.VarsKey or "dialog"
    vars[VarsKey] = vars[VarsKey] or {}

    local mod = {
        RootPath = RootPath,
        ScriptsPath = RootPath.."Scripts/",
        GraphicsPath = RootPath.."Graphics/",
        TreesPath = RootPath.."Trees/",
        VarsKey = VarsKey,
        TemplatesBank = 254,
    }

    local __DialogSystem = DialogSystem
    DialogSystem = mod

    mod.vars = function(character)
        vars[VarsKey] = vars[VarsKey] or {}

        if character then
            vars[VarsKey][character] = vars[VarsKey][character] or {}
            return vars[VarsKey][character]
        else
            return vars[VarsKey]
        end
    end

    -- Utilities ---------------------------------------------------------------
    mod.func = dofile(mod.ScriptsPath.."func.lua")
    mod.parse = dofile(mod.ScriptsPath.."parse.lua")
    mod.anim = dofile(mod.ScriptsPath.."anim.lua")

    -- Core --------------------------------------------------------------------
    mod.DialogTree = dofile(mod.ScriptsPath.."DialogTree.lua")
    mod.DialogMenu = dofile(mod.ScriptsPath.."DialogMenu.lua")

    -- Default Components ------------------------------------------------------
    mod.cursors = {
        Pointer = dofile(mod.ScriptsPath.."cursors/Pointer.lua"),
        Underline = dofile(mod.ScriptsPath.."cursors/Underline.lua"),
        Highlight = dofile(mod.ScriptsPath.."cursors/Highlight.lua"),
        Tracer = dofile(mod.ScriptsPath.."cursors/Tracer.lua"),
    }
    mod.DefaultRenderer = dofile(mod.ScriptsPath.."DefaultRenderer.lua")
    mod.DefaultInputHandler = dofile(mod.ScriptsPath.."DefaultInputHandler.lua")

    -- Convenience -------------------------------------------------------------
    mod.factory = dofile(mod.ScriptsPath.."factory.lua")
    mod.withOptions = mod.factory.withOptions

    DialogSystem = __DialogSystem

    return mod
end
