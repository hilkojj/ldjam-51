
loadModels("assets/models/title.glb", false)

function create(title)
    setName(title, "Title")
    setComponents(title, {
        Transform {
            position = vec3(-1.7, 0, 0),
            scale = vec3(2.0)
        },
        RenderModel {
            modelName = "Title"
        },
        PointLight(),
        PortalGun {
            portalName = "TitlePortalA",
            color = vec3(0.8, 0.3, 0.4)
        }
    })

    local portal = createChild(title, "portal")
    applyTemplate(portal, "Portal", {
        gunE = title
    })

    currentEngine.hudText = "A Game made for Ludum Dare 51 by hilkojj\n\n                              Click to start..."
end
