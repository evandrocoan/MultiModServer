#if defined _dbz_mod
  #endinput
#endif
#define _dbz_mod

#define DBZ_INC_VERSION 13

enum
{
	GOKU = 1,
	VEGETA,
	GOHAN,
	KRILIN,
	PICOLO
}

enum
{
	FRIEZA = 1
	CELL,
	SUPER_BUU,
	BROLY,
	OMEGA_SHERON
}

native dbz_get_user_energy(id) // Gets Player Energy
native dbz_set_user_energy(id, amount) // Sets Player Energy
native dbz_get_user_hero_id(id) // Get user Hero id
native dbz_get_user_villain_id(id) // Get user Villain id
native dbz_get_energy_level(id) // Get Player Energy Level
native dbz_set_energy_level(id, amount) // Set Player Energy Level