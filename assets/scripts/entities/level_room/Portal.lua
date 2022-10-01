
persistenceMode(TEMPLATE | ARGS, {"Transform", "Portal"})

collisionMasks = include("scripts/entities/level_room/_masks")

defaultArgs({
    name = "TestPortal"
})

function create(portal, args)

    setName(portal, args.name)

    component.Transform.getFor(portal)
    component.Portal.getFor(portal)

    setComponents(createChild(portal, "Camera"), {
        Transform(),
        RenderModel {
            modelName = "Sphere"
        }
    })

end
