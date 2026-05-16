game.AddParticles("particles/of_simple_bleeding.pcf")
game.AddParticles("particles/of_simple_bleeding_darker.pcf")

PrecacheParticleSystem("of_simple_bleeding_spray")
PrecacheParticleSystem("of_simple_bleeding_spray_b")
PrecacheParticleSystem("of_simple_bleeding_darker_spray")
PrecacheParticleSystem("of_simple_bleeding_darker_spray_b")

CreateConVar("of_bleeding_enabled", "1", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "")
CreateConVar("of_bleeding_player", "0", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "")
CreateConVar("of_bleeding_maxactive", "40", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "", 10, 500)
CreateConVar("of_bleeding_cooldown", "0.2", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "", 0, 1)
CreateConVar("of_bleeding_debug", "0", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "")
CreateConVar("of_bleeding_darker", "0", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "")