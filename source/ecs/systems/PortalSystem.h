
#ifndef GAME_PORTALSYSTEM_H
#define GAME_PORTALSYSTEM_H

#include <ecs/systems/EntitySystem.h>
#include "../../level/room/Room3D.h"
#include "../../generated/Character.hpp"

class PortalSystem : public EntitySystem
{
  public:
    using EntitySystem::EntitySystem;

    static vec4 getPortalPlane(const Transform &);

    static mat4 teleportThroughPortals(const mat4 &transformPortalAMat, mat4 transformPortalBMat, const mat4 &toTeleport);

    static vec3 transformDirectionByTeleport(const mat4 &transformPortalAMat, mat4 transformPortalBMat, const vec3 &toTeleport);

  protected:
    Room3D *room = NULL;

    void init(EntityEngine *) override;

    void update(double portalAE, EntityEngine *) override;

  private:

    float timePastSinceReplay = 0.0f;

    std::vector<InputHistory> histories;

    void replay();

};


#endif //GAME_PORTALSYSTEM_H
