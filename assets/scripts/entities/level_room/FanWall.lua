
persistenceMode(TEMPLATE | ARGS, {"Transform"})

loadModels("assets/models/fan.glb", false)

defaultArgs({
    name = "FanWall",
    width = 5,
    height = 5
})

function create(e, args)

    if args.name ~= nil then
        setName(e, args.name)
    end

    setComponents(e, {
        RenderModel {
            modelName = "FanBase"
        },
        InstancedRendering {
            --staticTransforms = true
        },
        --ShadowReceiver(),
        ShadowCaster()
    })
    component.Transform.getFor(e)

    local fanInstancesParent = createChild(e, "fans")
    setComponents(fanInstancesParent, {
        Transform(),
        TransformChild {
            parentEntity = e
        },
        RenderModel {
            modelName = "Fan"
        },
        CustomShader {
            vertexShaderPath = "shaders/default.vert",
            fragmentShaderPath = "shaders/default.frag",
            defines = {FAN_ROTATING = "1", INSTANCED = "1"}
        },
        InstancedRendering {
            --staticTransforms = true
        },
        --ShadowReceiver(),
        ShadowCaster()
    })

    for x = 0, args.width - 1 do
        for y = 0, args.height - 1 do
            local child = createChild(e, "instance "..x..","..y)

            setComponents(child, {
                Transform(),
                TransformChild {
                    parentEntity = e,
                    offset = Transform {
                        position = vec3(x * 16, y * 16, 0)
                    }
                }
            })

            local rotatingFan = createChild(e, "instance "..x..","..y.." (rotating)")
            setComponents(rotatingFan, {
                Transform(),
                TransformChild {
                    parentEntity = e,
                    offset = Transform {
                        position = vec3(x * 16, y * 16, 0)
                    }
                }
            })

            component.InstancedRendering.getFor(e):dirty().transformEntities:add(child)
            component.InstancedRendering.getFor(fanInstancesParent):dirty().transformEntities:add(rotatingFan)
        end
    end

end
