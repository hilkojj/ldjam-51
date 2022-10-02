
#ifndef GAME_CAMERASYSTEM_H
#define GAME_CAMERASYSTEM_H

#include <ecs/systems/EntitySystem.h>
#include "../../level/room/Room3D.h"

class CameraSystem : public EntitySystem
{
  public:
    using EntitySystem::EntitySystem;

  protected:
    Room3D *room = NULL;

    void init(EntityEngine *) override;

    void update(double deltaTime, EntityEngine *) override;


};


#endif //GAME_CAMERASYSTEM_H
