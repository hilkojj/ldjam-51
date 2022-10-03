
persistenceMode(TEMPLATE | ARGS, {"Transform"})

defaultArgs({
    name = "InstancedSpawner",
    spawnRate = 0.5,
    maxAlive = 20,
    instanceTemplate = "BananaInstanced",
    renderModel = "Banana",
    activatedByDefault = true
})

function create(e, args)

    setName(e, args.name)

    setComponents(e, {

        RenderModel {
            modelName = args.renderModel
        },
        InstancedRendering {
        },
        ShadowReceiver(),
        ShadowCaster()
    })
    component.Transform.getFor(e)

    local tube = createChild(e, "tube")
    setComponents(tube, {
        Transform(),
        TransformChild {
            parentEntity = e
        },
        RenderModel {
            modelName = "Tube"
        },
        ShadowCaster()
    })

    local i = 0

    currentEngine["activate"..args.name] = function()

        print("Activate "..args.name)

        setUpdateFunction(e, args.spawnRate, function()

            i = i + 1

            if i > args.maxAlive then
                local oldest = getChild(e, "instance "..(i - math.floor(args.maxAlive)))
                if oldest ~= nil then
                    destroyEntity(oldest)
                end
            end

            local child = createChild(e, "instance "..i)

            applyTemplate(child, args.instanceTemplate)
            component.Transform.getFor(child).position = component.Transform.getFor(e).position - vec3(0, 1, 0)

            component.InstancedRendering.getFor(e):dirty().transformEntities:add(child)

            setOnDestroyCallback(child, function()
                -- TODO: parent could be (about to be) destroyed, doing .getFor on a parent could cause a crash.

                component.InstancedRendering.getFor(e):dirty().transformEntities:erase(child)
            end)

        end)

    end

    currentEngine["deactivate"..args.name] = function()

        print("Deactivate "..args.name)

        setUpdateFunction(e, 0, nil)

    end

    if args.activatedByDefault then
        currentEngine["activate"..args.name]()
    end

end

