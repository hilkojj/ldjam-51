
-- physics:

STATIC_TERRAIN		= 1
BULLET_WALLS		= STATIC_TERRAIN * 2
DYNAMIC_PROPS		= BULLET_WALLS * 2
DYNAMIC_CHARACTER	= DYNAMIC_PROPS * 2
SENSOR				= DYNAMIC_CHARACTER * 2
PORTAL_BULLET		= SENSOR * 2


-- visibility:
NON_PLAYER	= 1
PLAYER		= NON_PLAYER * 2
