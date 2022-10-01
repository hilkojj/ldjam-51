
persistenceMode(TEMPLATE | ARGS) --, {"Transform"})

defaultArgs({
    setAsMain = false,
    name = ""
})

masks = include("scripts/entities/level_room/_masks")

function create(cam, args)

    setComponents(cam, {
        CameraPerspective {
            fieldOfView = 75,
            nearClipPlane = .1,
            farClipPlane = 1000,
            visibilityMask = -1 & ~masks.PLAYER
        }
    })

    component.Transform.getFor(cam)

    if args.name ~= "" then
        setName(cam, args.name)
    end
    if args.setAsMain then
        setMainCamera(cam)
    end

end
