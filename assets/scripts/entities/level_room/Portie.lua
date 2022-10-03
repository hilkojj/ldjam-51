
masks = include("scripts/entities/level_room/_masks")

loadModels("assets/models/cubeman.glb", false)

defaultArgs({
    isLocalPlayer = false
})

function create(portie, args)
    setName(portie, "player")

    setComponents(portie, {
        Transform {
            position = vec3(0, 3, 0)
        },
        RenderModel {
            modelName = "Portie",
            visibilityMask = args.isLocalPlayer and masks.PLAYER or -1
        },
        --[[
        CustomShader {
            vertexShaderPath = "shaders/default.vert",
            fragmentShaderPath = "shaders/default.frag",
            defines = {TEST = "1"}
        },
        Rigged {
            playingAnimations = {
                PlayAnimation {
                    name = "testanim",
                    influence = 1,
                }
            }
        },
        ]]--
        ShadowCaster(),
        RigidBody {
            gravity = vec3(0),
            mass = 1,
            linearDamping = .1,
            angularAxisFactor = vec3(0),
            collider = Collider {
                bounciness = 0,
                frictionCoefficent = .1,
                collisionCategoryBits = masks.DYNAMIC_CHARACTER,
                collideWithMaskBits = masks.STATIC_TERRAIN | masks.STATIC_WALLS | masks.STATIC_FLOORS | masks.SENSOR,
                registerCollisions = true
            }
        },
        SphereColliderShape {
            radius = 1
        },
        GravityFieldAffected {
            gravityScale = 30,
            defaultGravity = vec3(0, -30, 0)
        },
        CharacterMovement {
            --inputInCameraSpace = true
        },
        MovementInput(),
        --Inspecting()
    })
    component.InputHistory.getFor(portie)

    local wheel = createChild(portie, "wheel")
    setComponents(wheel, {
        Transform (),
        TransformChild {
            parentEntity = portie,
            rotation = false
        },
        RotationOffsetIsVelocity {
            velocityOf = portie
        },
        RenderModel {
            modelName = "PortieWheel",
            visibilityMask = args.isLocalPlayer and masks.PLAYER or -1
        },
        ShadowCaster(),
    })

    local eye = createChild(portie, "eye")
    setComponents(eye, {
        Transform (),
        TransformChild {
            parentEntity = portie,
            offset = Transform {
                position = vec3(0, 0.7, 0)
            }
        },
        RenderModel {
            modelName = "PortieEye",
            visibilityMask = args.isLocalPlayer and masks.PLAYER or -1
        },
        ShadowCaster(),
    })

    --[[
    local dropShadowSun = createChild(player, "drop shadow sun")
    setComponents(dropShadowSun, {
        Transform(),
		TransformChild {
			parentEntity = player,
            offset = Transform {
                position = vec3(0, 2.5, 0)
            }
		},
        DirectionalLight {
            color = vec3(-.7)
        },
        ShadowRenderer {
            visibilityMask = masks.PLAYER,
            resolution = ivec2(256),
            frustrumSize = vec2(2),
            farClipPlane = 16
        }
    })
    ]]--

    if args.isLocalPlayer then

        local cam = getByName("3rd_person_camera")
        if valid(cam) then
            setComponents(cam, {
                ThirdPersonFollowing {
                    target = portie,
                    visibilityRayMask = masks.STATIC_TERRAIN
                }
            })
        else
            cam = getByName("1st_person_camera")
            if valid(cam) then
                setComponents(cam, {
                    FirstPersonCamera {
                        target = portie
                    },
                    TransformChild {
                        parentEntity = portie,
                        offset = Transform {
                            position = vec3(0, 0.75, 0),
                        },
                        scale = false
                    }
                })

                local gunA = createChild(portie, "gunA")
                applyTemplate(gunA, "PortalGun", { isA = true, dummy = false })
                local rot = quat:new()
                rot.x = 5
                rot.y = 9
                rot.z = 0
                setComponents(gunA, {
                    TransformChild {
                        parentEntity = cam,
                        offset = Transform {
                            position = vec3(0.3, -0.3, -0.4),
                            rotation = rot
                        },
                        scale = false
                    }
                })
                rot.y = -rot.y
                local gunB = createChild(portie, "gunB")
                applyTemplate(gunB, "PortalGun", { isA = false, dummy = false })
                setComponents(gunB, {
                    TransformChild {
                        parentEntity = cam,
                        offset = Transform {
                            position = vec3(-0.3, -0.3, -0.4),
                            rotation = rot
                        },
                        scale = false
                    }
                })
            end
        end

        local sun = getByName("sun")
        if valid(sun) then
            local sunRot = quat:new()
            sunRot.x = 58
            sunRot.y = 68
            sunRot.z = 0

            setComponents(sun, {
                TransformChild {
                    parentEntity = portie,
                    offsetInWorldSpace = true,
                    position = true,
                    rotation = false,
                    scale = false,
                    offset = Transform {
                        position = vec3(160, 110, 64),
                        rotation = sunRot
                    }
                }
            })
        end

    else -- isLocalPlayer (is false here:)

        local decoGunA = createChild(portie, "decoGunA")
        applyTemplate(decoGunA, "PortalGun", { isA = true, dummy = true })
        setComponents(decoGunA, {
            TransformChild {
                parentEntity = portie,
                offset = Transform {
                    position = vec3(0.5, 0.16, -0.5),
                    scale = vec3(2.5)
                },
                scale = false
            }
        })
        local decoGunB = createChild(portie, "decoGunB")
        applyTemplate(decoGunB, "PortalGun", { isA = false, dummy = true })
        setComponents(decoGunB, {
            TransformChild {
                parentEntity = portie,
                offset = Transform {
                    position = vec3(-0.5, 0.16, -0.5),
                    scale = vec3(2.5)
                },
                scale = false
            }
        })

    end -- isLocalPlayer
end
