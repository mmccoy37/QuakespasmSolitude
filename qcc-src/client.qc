// prototypes
void() W_WeaponFrame;
void(float weap) W_WeaponSwitch;
void() player_pain;
void() player_stand1;
void(vector org) spawn_tfog;
void(vector org, entity death_owner) spawn_tdeath;
void() Setup_Gametype;
void(entity client) Setup_Slowmo;
void(entity client, float howmuch) Add_Slowmo;
void(entity client) Medal;
BOOL(entity targ, entity attacker) OnSameTeam;

float modelindex_eyes, modelindex_player;

/*
=============================================================================

				LEVEL CHANGING / INTERMISSION

=============================================================================
*/

string nextmap;

/*QUAKED info_intermission (1 0.5 0.5) (-16 -16 -16) (16 16 16)
This is the camera point for the intermission.
Use mangle instead of angle, so you can set pitch or roll as well as yaw.  'pitch roll yaw'
*/
void() info_intermission = {
        self.angles = self.mangle; // so C can get at it
};

void() SetChangeParms = {
    if (self.health <= 0) {
        SetNewParms();
        return;
    }

    // cap super health

	if (self.health > self.max_health)
	    self.health = self.max_health;
	parm1 = self.items;
	parm2 = self.health;
	parm3 = self.armorvalue;
	parm4 = 12;
	/*
	if (self.ammo_shells_real < 25)
		parm4 = 25;
	else
		parm4 = self.ammo_shells_real;
	*/
	parm6 = self.ammo_rockets_real;
	parm7 = self.ammo_cells_real;
	parm8 = self.weapon;
	parm9 = self.armortype;
	// Solitude
	parm10 = self.exshells;
	parm11 = self.exnails;
	parm12 = self.exrockets;
	//parm13 = self.pfov;
	parm14 = self.ammo_shells2;
	parm15 = self.exshells2;
	if (deathmatch != SWAT)
	    parm16 = self.nade_lives;
};

// ignored? See Gametypes.qc::Start_Weapon()
void() SetNewParms = {
    // starting weapon
    parm1 = 0; //SET IN Start_Weapon()! //WEAPON_AR + WEAPON_PISTOL; // start Assault rifle // ignored?
    if (deathmatch != SWAT)
        parm2 = 130;
    else
        parm2 = 30;
    parm3 = 0;
    parm4 = 0;
    //parm4 = 25;
    parm6 = 0;
    parm7 = 0;
    parm8 = 0; // set in Start_Weapon(); WEAPON_AR; // start Assault rifle // ignored?
    parm9 = 0;
    // Solitude
    parm10 = 40;
    parm11 = 560;
    parm12 = MSG_BROADCAST;
    //parm13 = 90;
    parm14 = SVC_INTERMISSION;
    parm15 = 60;
    if (deathmatch != SWAT) {
        parm16 = cvar("max_nades");
    }
};

void() DecodeLevelParms = {
    if (!deathmatch) {
        if (world.model == "maps/start.bsp")
            SetNewParms(); // take away all stuff on starting new episode
    }

    self.items = 0; //parm1; Set in Start_Weapon()!
    self.health = parm2;
    self.armorvalue = parm3;
    self.ammo_shells_real = parm4;
    self.ammo_rockets_real = parm6;
    self.ammo_cells_real = parm7;
    self.weapon = 0;//parm8; set in Start_Weapon();
    self.armortype = parm9;
    // solitude
    self.ammo_hshells = 0;
    self.exhshells = 0;
    self.exshells = 0;
    self.exnails = 0;
    self.exrockets = 0;
    self.pfov = 90;
    self.ammo_shells2 = 0;
    self.exshells2 = 0;
    if (deathmatch != SWAT) {
        self.nade_lives = parm16;
        self.plasma_lives = parm16;
    }
    // weapon we start with:
};

/*
============
FindIntermission

Returns the entity to view from
============
*/
entity() FindIntermission = {
        local entity spot;
        local float cyc;

        // look for info_intermission first
        spot = find(world, classname, "info_intermission");
        if (spot) { // pick a random one
            cyc = random() * 4;
            while (cyc > 1) {
                spot = find(spot, classname, "info_intermission");
                if (!spot)
                    spot = find(spot, classname, "info_intermission");
                cyc = cyc - 1;
            }
            return spot;
        }

        // then look for the start position
        spot = find(world, classname, "info_player_start");
        if (spot)
        return spot;

        objerror("FindIntermission: no spot");
        return world; // remove warning
};

void() GotoNextMap = {
        local string newmap;

        //ZOID: 12-13-96, samelevel is overloaded, only 1 works for same level

        if (cvar("samelevel") == 1) // if samelevel is set, stay on same level
            changelevel(mapname);
        else {
            // configurable map lists, see if the current map exists as a
            // serverinfo/localinfo var
            newmap = stringserverinfokey(mapname);
            if (newmap != "")
                changelevel(newmap);
            else
                changelevel(nextmap);
        }
};

void() ExitIntermission = {
        // skip any text in deathmatch
//        if (deathmatch) {
//            GotoNextMap();
//            return;
//        }
        if (deathmatch == 2) {
            stuffcmd(self, "disconnect_f\n");
            return;
        } else if (deathmatch) {
            stuffcmd(self, "disconnect_m\n");
            return;
        }

        intermission_exittime = time + 1;
        intermission_running = intermission_running + 1;

        //
        // run some text if at the end of an episode
        //
        if (intermission_running == 2) {
            if (world.model == "maps/e1m7.bsp") {
                ENG_SwitchTrack(2, 3);
                if (!cvar("registered")) {
                    WriteByte(MSG_ALL, SVC_FINALE);
                    WriteString(MSG_ALL, "As the corpse of the monstrous entity\nChthon sinks back into the lava whence\nit rose, you grip the Rune of Earth\nMagic tightly. Now that you have\nconquered the Dimension of the Doomed,\nrealm of Earth Magic, you are ready to\ncomplete your task in the other three\nhaunted lands of Quake. Or are you? If\nyou don't register Quake, you'll never\nknow what awaits you in the Realm of\nBlack Magic, the Netherworld, and the\nElder World!");
                } else {
                    WriteByte(MSG_ALL, SVC_FINALE);
                    WriteString(MSG_ALL, "As the corpse of the monstrous entity\nChthon sinks back into the lava whence\nit rose, you grip the Rune of Earth\nMagic tightly. Now that you have\nconquered the Dimension of the Doomed,\nrealm of Earth Magic, you are ready to\ncomplete your task. A Rune of magic\npower lies at the end of each haunted\nland of Quake. Go forth, seek the\ntotality of the four Runes!");
                }
                return;
            } else if (world.model == "maps/e2m6.bsp") {
                ENG_SwitchTrack(2, 3);
                WriteByte(MSG_ALL, SVC_FINALE);
                WriteString(MSG_ALL, "The Rune of Black Magic throbs evilly in\nyour hand and whispers dark thoughts\ninto your brain. You learn the inmost\nlore of the Hell-Mother; Shub-Niggurath!\nYou now know that she is behind all the\nterrible plotting which has led to so\nmuch death and horror. But she is not\ninviolate! Armed with this Rune, you\nrealize that once all four Runes are\ncombined, the gate to Shub-Niggurath's\nPit will open, and you can face the\nWitch-Goddess herself in her frightful\notherworld cathedral.");
                return;
            } else if (world.model == "maps/e3m6.bsp") {
                ENG_SwitchTrack(2, 3);
                WriteByte(MSG_ALL, SVC_FINALE);
                WriteString(MSG_ALL, "The charred viscera of diabolic horrors\nbubble viscously as you seize the Rune\nof Hell Magic. Its heat scorches your\nhand, and its terrible secrets blight\nyour mind. Gathering the shreds of your\ncourage, you shake the devil's shackles\nfrom your soul, and become ever more\nhard and determined to destroy the\nhideous creatures whose mere existence\nthreatens the souls and psyches of all\nthe population of Earth.");
                return;
            } else if (world.model == "maps/e4m7.bsp") {
                ENG_SwitchTrack(2, 3);
                WriteByte(MSG_ALL, SVC_FINALE);
                WriteString(MSG_ALL, "Despite the awful might of the Elder\nWorld, you have achieved the Rune of\nElder Magic, capstone of all types of\narcane wisdom. Beyond good and evil,\nbeyond life and death, the Rune\npulsates, heavy with import. Patient and\npotent, the Elder Being Shub-Niggurath\nweaves her dire plans to clear off all\nlife from the Earth, and bring her own\nfoul offspring to our world! For all the\ndwellers in these nightmare dimensions\nare her descendants! Once all Runes of\nmagic power are united, the energy\nbehind them will blast open the Gateway\nto Shub-Niggurath, and you can travel\nthere to foil the Hell-Mother's plots\nin person.");
                return;
            }

            GotoNextMap();
        }

        if (intermission_running == 3) {
            if (!cvar("registered")) { // shareware episode has been completed, go to sell screen
                WriteByte(MSG_ALL, SVC_SELLSCREEN);
                return;
            }

            if ((serverflags & 15) == 15) {
                WriteByte(MSG_ALL, SVC_FINALE);
                WriteString(MSG_ALL, "Now, you have all four Runes. You sense\ntremendous invisible forces moving to\nunseal ancient barriers. Shub-Niggurath\nhad hoped to use the Runes Herself to\nclear off the Earth, but now instead,\nyou will use them to enter her home and\nconfront her as an avatar of avenging\nEarth-life. If you defeat her, you will\nbe remembered forever as the savior of\nthe planet. If she conquers, it will be\nas if you had never been born.");
                return;
            }

        }

        GotoNextMap();
};

/*
============
IntermissionThink

When the player presses attack or jump, change to the next level
============
*/
void() IntermissionThink = {
        if (time < intermission_exittime && !self.button1 && !self.button2)
        return;

        ExitIntermission();
};

/*
============
execute_changelevel

The global "nextmap" has been set previously.
Take the players to the intermission spot
============
*/
void() execute_changelevel = {
    local entity pos;

    intermission_running = 1;

    // enforce a wait time before allowing changelevel
    if (deathmatch)
        intermission_exittime = time + 8;
    else
        intermission_exittime = time + 5;

    pos = FindIntermission();

    // play announcer
    sound(self.owner, CHAN_WEAPON, "gameover.wav", 1, ATTN_NONE);

    // play intermission music
    ENG_SwitchTrack(3, 3);

#ifdef NETQUAKE
    pos = FindIntermission();

    other = find(world, classname, "player");
    while (other != world) {
        other.view_ofs = '0 0 0';
        other.angles = other.v_angle = pos.mangle;
        other.fixangle = TRUE; // turn this way immediately
        other.nextthink = time + 0.5;
        other.takedamage = DAMAGE_NO;
        other.solid = SOLID_NOT;
        other.movetype = MOVETYPE_NONE;
        other.modelindex = 0;
        setorigin(other, pos.origin);
        other = find(other, classname, "player");
    }

    WriteByte(MSG_ALL, SVC_INTERMISSION);
#else
    WriteByte(MSG_ALL, SVC_INTERMISSION);
    WriteCoord(MSG_ALL, pos.origin_x);
    WriteCoord(MSG_ALL, pos.origin_y);
    WriteCoord(MSG_ALL, pos.origin_z);
    WriteAngle(MSG_ALL, pos.mangle_x);
    WriteAngle(MSG_ALL, pos.mangle_y);
    WriteAngle(MSG_ALL, pos.mangle_z);

    other = find(world, classname, "player");
    while (other != world) {
        other.takedamage = DAMAGE_NO;
        other.solid = SOLID_NOT;
        other.movetype = MOVETYPE_NONE;
        other.modelindex = 0;
        other = find(other, classname, "player");
    }
#endif
};

void() changelevel_touch = {
        if (other.classname != "player")
        return;

        // if "noexit" is set, blow up the player trying to leave
        //ZOID, 12-13-96, noexit isn't supported in QW.  Overload samelevel
        //      if ((cvar("noexit") == 1) || ((cvar("noexit") == 2) && (mapname != "start")))
        if (deathmatch) {
            if ((cvar("samelevel") == 2) || ((cvar("samelevel") == 3) && (mapname != "start"))) {
                T_Damage(other, self, self, 50000, MOD_EXIT);
                return;
            }
        }

        bprint2(PRINT_HIGH, other.netname, " exited the level\n");

        nextmap = self.map;

        SUB_UseTargets();

        self.touch = SUB_Null;

        // we can't move people right now, because touch functions are called
        // in the middle of C movement code, so set a think time to do it
        self.think = execute_changelevel;
        self.nextthink = time + 0.1;
};

/*QUAKED trigger_changelevel (0.5 0.5 0.5) ? NO_INTERMISSION
When the player touches this, he gets sent to the map listed in the "map" variable.  Unless the NO_INTERMISSION flag is set, the view will go to the info_intermission spot and display stats.
*/
void() trigger_changelevel = {
        if (!self.map)
        objerror("chagnelevel trigger doesn't have map");

        InitTrigger();
        self.touch = changelevel_touch;
};

/*
=============================================================================

				PLAYER GAME EDGE FUNCTIONS

=============================================================================
*/

void() set_suicide_frame;

// create a deadbody ent that is removed over time
void(entity ent) CopyToDeadbody = {
        local entity deadbody;

        deadbody = spawn();
        deadbody.angles = ent.angles;
        deadbody.model = ent.model;
        deadbody.modelindex = ent.modelindex;
        deadbody.frame = ent.frame;
        deadbody.colormap = ent.colormap;
        deadbody.movetype = ent.movetype;
        deadbody.velocity = ent.velocity;
        deadbody.flags = 0;
        setorigin(deadbody, ent.origin);
        setsize(deadbody, ent.mins, ent.maxs);

        deadbody.think = SUB_Remove;
        deadbody.nextthink = time + 3;
};

// called by ClientKill and DeadThink
void() respawn = {
        if (self.setup_death == #TRUE) {
            Player_SetupDeath();
        }
};

void() true_respawn = {
        if (coop) {
            // make a copy of the dead body for appearances sake
            CopyToDeadbody(self);
            // get the spawn parms as they were at level start
            setspawnparms(self);
            // respawn
            PutClientInServer();
        } else if (deathmatch) {
            // make a copy of the dead body for appearances sake
            CopyToDeadbody(self);
            // set default spawn parms
            SetNewParms();
            // respawn
            PutClientInServer();
        } else { // restart the entire server
            localcmd("restart\n");
        }
};

/*
============
ClientKill

Player entered the suicide command
============
*/
void() PlayerDropStuff;

void() ClientKill = {
        if (intermission_running)
        return;

        if (self.suicide_time > time)
        return;

        stuffcmd(self, "chase_active 1\n");
        self.setup_death = #TRUE;
        self.health = 0;

        bprint2(PRINT_MEDIUM, self.netname, " suicides\n");
        PlayerDropStuff();
        set_suicide_frame();
        CTF_Flag_Drop();
        self.modelindex = modelindex_player;
        logfrag(self, self)
        self.frags = self.frags - 2; // extra penalty

        respawn();
};

/*
============
SelectSpawnPoint

Returns the entity to spawn at
============
*/
entity() SelectSpawnPoint = {
        local entity spot,
        thing;
        local float numspots,
        totalspots;
        local float pcount;
        local entity spots;

        if (coop) // coop spawning
        {
            if (!spotspawn) {
                spotspawn = 1;
                spot = find(world, classname, "info_player_start");
                if (spot)
                    return spot;
            }
            lastspawn = find(lastspawn, classname, "info_player_coop");
            if (lastspawn)
                return lastspawn;
        }

        if (!deathmatch) // single player spawning
        {
            if (serverflags) { // return with a rune to start
                spot = find(world, classname, "info_player_start2");
                if (spot)
                    return spot;
            }

            spot = find(world, classname, "info_player_start");
            if (spot)
                return spot;
        }

        // QuakeWorld style deathmatch spawning
        numspots = 0;
        totalspots = 0;

        // choose a info_player_deathmatch point
        // ok, find all spots that don't have players nearby
        spots = world;
        spot = find(world, classname, "info_player_deathmatch");
        while (spot) {
            totalspots = totalspots + 1;

            thing = findradius(spot.origin, 84);
            pcount = 0;
            while (thing) {
                if (thing.classname == "player")
                    pcount = pcount + 1;
                thing = thing.chain;
            }
            if (pcount == 0) {
                spot.goalentity = spots;
                spots = spot;
                numspots = numspots + 1;
            }

            // Get the next spot in the chain
            spot = find(spot, classname, "info_player_deathmatch");
        }
        totalspots = totalspots - 1;
        if (!numspots) {
            // ack, they are all full, just pick one at random
            totalspots = rint((random() * totalspots));
            spot = find(world, classname, "info_player_deathmatch");
            while (totalspots > 0) {
                totalspots = totalspots - 1;
                spot = find(spot, classname, "info_player_deathmatch");
            }
            return spot;
        }

        // We now have the number of spots available on the map in numspots
        // Generate a random number between 1 and numspots
        numspots = numspots - 1;
        numspots = rint((random() * numspots));

        spot = spots;
        while (numspots > 0) {
            spot = spot.goalentity;
            numspots = numspots - 1;
        }
        return spot;

};
void() DecodeLevelParms;
void() PlayerDie;

/*
===========
PutClientInServer

called each time a player enters a new level
============
*/
void() PutClientInServer = {
        Setup_Gametype(); //Rest is done In gametypes.qc
};

/*
=============================================================================

				QUAKED FUNCTIONS

=============================================================================
*/

/*QUAKED info_player_start (1 0 0) (-16 -16 -24) (16 16 24)
The normal starting point for a level.
*/
void() info_player_start = {};

/*QUAKED info_player_start2 (1 0 0) (-16 -16 -24) (16 16 24)
Only used on start map for the return point from an episode.
*/
void() info_player_start2 = {};

/*QUAKED info_player_deathmatch (1 0 1) (-16 -16 -24) (16 16 24)
potential spawning position for deathmatch games
*/
void() info_player_deathmatch = {};

/*QUAKED info_player_coop (1 0 1) (-16 -16 -24) (16 16 24)
potential spawning position for coop games
*/
void() info_player_coop = {};

/*
===============================================================================

RULES

===============================================================================
*/

/*
go to the next level for deathmatch
*/
void() NextLevel = {
        local entity o;

        if (nextmap != "")
        return; // already done

        if (mapname == "start") {
            if (!cvar("registered")) {
                mapname = "e1m1";
            } else if (!(serverflags & 1)) {
                mapname = "e1m1";
                serverflags = serverflags | 1;
            } else if (!(serverflags & 2)) {
                mapname = "e2m1";
                serverflags = serverflags | 2;
            } else if (!(serverflags & 4)) {
                mapname = "e3m1";
                serverflags = serverflags | 4;
            } else if (!(serverflags & 8)) {
                mapname = "e4m1";
                serverflags = serverflags - 7;
            }

            o = spawn();
            o.map = mapname;
        } else {
            // find a trigger changelevel
            o = find(world, classname, "trigger_changelevel");
            if (!o || mapname == "start") { // go back to same map if no trigger_changelevel
                o = spawn();
                o.map = mapname;
            }
        }

        nextmap = o.map;

        if (o.nextthink < time) {
            o.think = execute_changelevel;
            o.nextthink = time + 0.1;
        }
};

void() firefight_death_setup = {
        if (deathmatch == FIREFIGHT && self.health == 1) {

            //FIXME!
            if (F_LIVES < 0 && self.owner.ishuman == FALSE)
                self.health = 11;

            if (F_LIVES < 0 && bot_count > 0 && self.owner.ishuman == TRUE)
                self.health = 11;

            else if (F_LIVES < 0 && self.owner.ishuman == TRUE)
                localcmd("restart\n");
        }
};
/*
============
CheckRules

Exit deathmatch games upon conditions
============
*/
void() CheckRules = {
        if (deathmatch && teamplay && teamlimit)
            NextLevel();
        if (deathmatch && timelimit && time >= timelimit)
            NextLevel();
        if (deathmatch && fraglimit && self.frags >= fraglimit)
            NextLevel();
};

void() player_respawn_think = {
        local entity oself;

        if (self.owner.classname != "player" || self.owner == world || self.owner.health > 0) {
            remove(self);
            return;

        }
        firefight_death_setup();
        self.health -= 1;
        if (self.owner.ishuman == TRUE) {
            if (self.health > 0 && self.health < 4)
                stuffcmd(self.owner, "play player/beep1.wav\n");
            stuffcmd(self.owner, "cl_respawn ");
            stuffcmd(self.owner, ftos(self.health));
            stuffcmd(self.owner, " \n");
        }
        if (self.health < 1) {
            oself = self;

            self = self.owner;
            self.impulse = 0;
            self.button0 = 0;
            self.button1 = 0;
            self.button2 = 0;
            if (self.ishuman == TRUE)
                stuffcmd(self, "play player/beep2.wav\n");
            true_respawn();

            self = oself;
            remove(self);
            return;
        }

        self.nextthink = time + 1;
};

void() Player_SetupDeath = {
        local entity dt;

        dt = spawn();
        if (deathmatch == SWAT)
        dt.health = 5;
        else
        dt.health = 8;
        dt.owner = self;
        dt.think = player_respawn_think;
        dt.nextthink = time + 1;
        self.setup_death = #FALSE;
        self.weaponframe = 0;
};

//============================================================================

void() PlayerDeathThink = {
        local float forward;

        if (self.setup_death == #TRUE) {
            Player_SetupDeath();
        }
        if ((self.flags & FL_ONGROUND)) {
            forward = vlen(self.velocity);
            forward = forward - 20;
            if (forward <= 0)
                self.velocity = '0 0 0';
            else
                self.velocity = forward * normalize(self.velocity);
        }

        // wait for all buttons released
        if (self.deadflag == DEAD_DEAD) {
            if (self.button2 || self.button1 || self.button0)
                return;
            self.deadflag = DEAD_RESPAWNABLE;
            return;
        }

        // wait for any button down
        if (!self.button2 && !self.button1 && !self.button0)
            return;

        self.button0 = 0;
        self.button1 = 0;
        self.button2 = 0;
        respawn();
};

void() PlayerJump = {
        local float vjump;
        vjump = cvar("sol_jump");

        if (self.flags & FL_WATERJUMP)
        return;

        if (self.next_jump_time > time) {
            stuffcmd(self, "-jump\n");
            return;
        }

        if (self.waterlevel >= 2) {
            // play swiming sound
            if (self.swim_flag < time) {
                self.swim_flag = time + 1;
                if (random() < 0.5)
                    sound(self, CHAN_BODY, "misc/water1.wav", 1, ATTN_NORM);
                else
                    sound(self, CHAN_BODY, "misc/water2.wav", 1, ATTN_NORM);
            }

            return;
        }

        if (!(self.flags & FL_ONGROUND))
        return;

        if (!(self.flags & FL_JUMPRELEASED))
        return; // don't pogo stick

        self.flags = self.flags - (self.flags & FL_JUMPRELEASED);
        self.button2 = 0;

        // player jumping sound
        sound(self, CHAN_BODY, "player/plyrjmp8.wav", 1, ATTN_NORM);

        if (vjump) {
            self.velocity_z = self.velocity_z + vjump;
        } else {
#ifdef NETQUAKE
            self.flags = self.flags - FL_ONGROUND;
        self.velocity_z = self.velocity_z + 225;
#endif
        }
        self.jump_time = time + .15;
};

/*
===========
WaterMove

============
*/
void() WaterMove = {
        //dprint (ftos(self.waterlevel));
        if (self.movetype == MOVETYPE_NOCLIP)
        return;
        if (self.health < 0)
        return;

        if (self.waterlevel != 3) {
            if (self.air_finished < time)
                sound(self, CHAN_VOICE, "player/gasp2.wav", 1, ATTN_NORM);
            else if (self.air_finished < time + 9)
                sound(self, CHAN_VOICE, "player/gasp1.wav", 1, ATTN_NORM);
            self.air_finished = time + 12;
            self.waterdmg = 2;
        } else if (self.air_finished < time) { // drown!
            if (self.pain_finished < time) {
                self.waterdmg = self.waterdmg + 2;
                if (self.waterdmg > 15)
                    self.waterdmg = 10;
                T_Damage(self, world, world, self.waterdmg, MOD_DROWN);
                self.pain_finished = time + 1;
            }
        }

        if (!self.waterlevel) {
            if (self.flags & FL_INWATER) {
                // play leave water sound
                sound(self, CHAN_BODY, "misc/outwater.wav", 1, ATTN_NORM);
                self.flags = self.flags - FL_INWATER;
            }
            return;
        }

        if (!(self.flags & FL_INWATER)) {
            // player enter water sound
            switch (self.watertype) {
                case CONTENT_LAVA:
                    sound(self, CHAN_BODY, "player/inlava.wav", 1, ATTN_NORM);
                    break;
                case CONTENT_WATER:
                    sound(self, CHAN_BODY, "player/inh2o.wav", 1, ATTN_NORM);
                    break;
                case CONTENT_SLIME:
                    sound(self, CHAN_BODY, "player/slimbrn2.wav", 1, ATTN_NORM);
                    break;
            }

            self.flags = self.flags + FL_INWATER;
            self.dmgtime = 0;
        }

        if (self.watertype == CONTENT_LAVA) { // do damage
            if (self.dmgtime < time) {
                if (self.radsuit_finished > time)
                    self.dmgtime = time + 1;
                else
                    self.dmgtime = time + 0.2;

                T_Damage(self, world, world, 10 * self.waterlevel, MOD_LAVA);
            }
        } else if (self.watertype == CONTENT_SLIME) { // do damage
            if (self.dmgtime < time && self.radsuit_finished < time) {
                self.dmgtime = time + 1;
                T_Damage(self, world, world, 4 * self.waterlevel, MOD_SLIME);
            }
        }

};

void() CheckWaterJump = {
        local vector start,
        end;

        // check for a jump-out-of-water
        makevectors(self.angles);
        start = self.origin;
        start_z = start_z + 8;
        v_forward_z = 0;
        normalize(v_forward);
        end = start + v_forward * 24;
        traceline(start, end, TRUE, self);
        if (trace_fraction < 1) { // solid at waist
            start_z = start_z + self.maxs_z - 8;
            end = start + v_forward * 24;
            self.movedir = trace_plane_normal * -50;
            traceline(start, end, TRUE, self);
            if (trace_fraction == 1) { // open at eye level
                self.flags = self.flags | FL_WATERJUMP;
                self.velocity_z = 225;
                self.flags = self.flags - (self.flags & FL_JUMPRELEASED);
                self.teleport_time = time + 2; // safety net
                return;
            }
        }
};

void() CH_Red = {
        if (self.ishuman == FALSE)
        return;

        local vector src,
        dir;
        dir = aim(self, 100000);

        makevectors(self.v_angle);

        src = self.origin + v_forward * 10;
        src_z = self.absmin_z + self.size_z * 0.7;

        if (self.weapon == IT_SUPER_SHOTGUN)
        traceline(src, src + dir * 100, FALSE, self);
        else if (self.weapon == IT_SHOTGUN)
        traceline(src, src + dir * 1500, FALSE, self);
        else if (self.weapon == WEAPON_SNIPER)
        traceline(src, src + dir * 1800, FALSE, self);
        else if (self.weapon == IT_SUPER_NAILGUN)
        traceline(src, src + dir * 400, FALSE, self);
        else if (self.weapon == IT_NAILGUN)
        traceline(src, src + dir * 550, FALSE, self);
        else if (self.weapon == WEAPON_RL)
        traceline(src, src + dir * 800, FALSE, self);
        else if (self.weapon == IT_LIGHTNING)
        traceline(src, src + dir * 500, FALSE, self);
        else if (self.weapon == IT_BR)
        traceline(src, (src + (dir * 1500)), FALSE, self);
        else
        traceline(src, src + dir * 300, FALSE, self);
        puff_org = trace_endpos - dir * 4;

         if (trace_ent.takedamage)
         {
            stuffcmd (self, "cl_ch_red 1\n");
         } else if (!trace_ent.takedamage) {
            stuffcmd(self, "cl_ch_red 0\n");
        }

        if (self.canpick == 0){
            stuffcmd (self, "cl_ww 0\n");
        }

        crosshair_time = time + 0.1;

};

/*
================
PlayerPreThink

Called every frame before physics are run
================
*/
void() PlayerPreThink = {
    if (BotPreFrame()) // FrikBot
    return;
    if (intermission_running) {
        IntermissionThink(); // otherwise a button could be missed between
        return; // the think tics
    }

    // if intermission is running what is the point of this?
    //	if (self.view_ofs == '0 0 0')
    //		return;

    makevectors(self.v_angle); // is this still used

    CheckRules();
    WaterMove();
    /*
        if (self.waterlevel == 2)
            CheckWaterJump ();
    */

    if (self.deadflag >= DEAD_DEAD) {
        PlayerDeathThink();
        return;
    }
    if (self.slowmo_flags == SLOWMO_ABLE)
    Setup_Slowmo(self);

    if (self.deadflag == DEAD_DYING)
    return; // dying, so do nothing

    if (self.button2)
        PlayerJump();
    else
        self.flags = self.flags | FL_JUMPRELEASED;

    if (time > self.attack_finished && self.currentammo == 0 && self.weapon != IT_AXE) {
        W_WeaponSwitch(W_BestWeapon());
    }

    if (crosshair_time < time)
        CH_Red();

    /*
    sprint (self," ");
    sprint (self, ftos(self.medal_time));
    sprint (self, " \n");
    */

};
void() voice_play = {
    if (deathmatch == FIREFIGHT)
        sound(self.owner, CHAN_WEAPON, "firefight.wav", 1, ATTN_NONE);
    else if (deathmatch == SLAYER)
        sound(self.owner, CHAN_WEAPON, "slayer.wav", 1, ATTN_NONE);
    remove(self);
};

void() Voice_announcer = {
    local entity avoice;
    if (VOICE_COUNT == 1) {
        return;
    }
    avoice = spawn();
    VOICE_COUNT = 1;
    avoice.think = voice_play;
    avoice.nextthink = time + 0.7;
};

void() populate_bots = {
        if (deathmatch == 1 || deathmatch == 3) {
            if (teamplay) {
                // Team Slayer
                local float myteam = self.team;
                BotConnect(0, 0, cvar("skill"));
                BotConnect(0, 0, cvar("skill"));
                BotConnect(1, 0, cvar("skill"));

                BotConnect(0, 0, cvar("skill"));
                BotConnect(1, 0, cvar("skill"));

                BotConnect(0, 0, cvar("skill"));
                BotConnect(1, 0, cvar("skill"));
            } else {
                // Slayer & Swat
                BotConnect(0, 0, cvar("skill"));
                BotConnect(0, 0, cvar("skill"));
                BotConnect(0, 0, cvar("skill"));
            }
        }
        remove(self);
}
void() BotSpawner = {
        // add bots
        local entity botspawner;
        if (BOT_SPAWNER_COMPLETED)
        return;
        botspawner = spawn();
        BOT_SPAWNER_COMPLETED = 1;
        botspawner.think = populate_bots;
        botspawner.nextthink = time + 1.7;
}
/*
================
CheckPowerups

Check for turning off powerups
================
*/
void() CheckPowerups = {
    if (self.health <= 0)
        return;

    if (self.ishuman == FALSE)
        stuffcmd(self, "r_drawviewmodel 0\n");

    CheckModel();

    if (self.ishuman == TRUE) {
        Voice_announcer();
        BotSpawner();
    }
};

/*
================
PlayerPostThink

Called every frame after physics are run
================
*/
void() PlayerPostThink = {
    if (BotPostFrame()) // FrikBot
        return;
    //dprint ("post think\n");
    if (intermission_running)
        return;
    //	if (self.view_ofs == '0 0 0')
    //		return;
    if (self.deadflag)
        return;

    if (!self.flags & FL_ONGROUND)
    if (self.next_jump_time < time)
    self.next_jump_time = time + .05;

    self.jump_flag = self.velocity_z;

    CheckPowerups();

    W_WeaponFrame();
};

/*
===========
ClientConnect

called when a player connects to a server
============
*/
void() ClientConnect = {
    ClientInRankings(); // FrikBot
    bprint2(PRINT_HIGH, self.netname, " entered the game\n");

    // a client connecting during an intermission can cause problems
    if (intermission_running)
        GotoNextMap();
};

void() ClientDisconnect = {
    ClientDisconnected(); // FrikBot
    // let everyone else know
    bprint4(PRINT_HIGH, self.netname, " left the game with ", ftos(self.frags), " frags\n");
    sound(self, CHAN_BODY, "player/tornoff2.wav", 1, ATTN_NONE);
    set_suicide_frame();
};

void(entity playermedal, float howmany) killmedals = {
    if (playermedal.ishuman == FALSE)
        return;
    if (howmany == 10)
        centerprint(playermedal, "Killpocalypse!\n");
    else if (howmany == 9)
        centerprint(playermedal, "Killpocalypse!\n");
    else if (howmany == 8)
        centerprint(playermedal, "Killtastrophe!\n");
    else if (howmany == 7)
        centerprint(playermedal, "Killimanjaro!\n");
    else if (howmany == 6) {
        stuffcmd(playermedal, "cl_killmedals 5\n");
        Medal(playermedal);
    } else if (howmany == 5) {
        stuffcmd(playermedal, "play killtrocity.wav\n");
        stuffcmd(playermedal, "cl_killmedals 4\n");
        Medal(playermedal);
    } else if (howmany == 4) {
        stuffcmd(playermedal, "play killtacular.wav\n");
        stuffcmd(playermedal, "cl_killmedals 3\n");
        Medal(playermedal);
    } else if (howmany == 3) {
        stuffcmd(playermedal, "play triple.wav\n");
        stuffcmd(playermedal, "cl_killmedals 2\n");
        Medal(playermedal);
    } else if (howmany == 2) {
        stuffcmd(playermedal, "play double.wav\n");
        stuffcmd(playermedal, "cl_killmedals 1\n");
        Medal(playermedal);
    }
    return;
};
/*
===========
ClientObituary

called when a player dies
============
*/
void(entity targ, entity attacker, INTEGER mod) ClientObituary = {
    //Kill Medals
    if (attacker.kill_time >= time) {
        attacker.kill_amount = attacker.kill_amount + 1;
        killmedals(attacker, attacker.kill_amount);
    } else
    attacker.kill_amount = 1;
    if (targ.classname == "player" || targ.flags & FL_MONSTER)
    attacker.kill_time = time + 10;

    if (attacker.flags & FL_CLIENT) {
        if (attacker == targ) {
            SuicideMessage(targ.netname, mod);
            targ.frags = targ.frags - 1;
            logfrag(targ, targ)
            return;
        } // else if anything else

        if (OnSameTeam(targ, attacker)) {
            TeamKillMessage(targ.netname, attacker.netname, mod);
            logfrag(attacker, attacker)
            attacker.frags = attacker.frags - 1;
            return;
        }

        if (targ.flags & FL_CLIENT || targ.flags & FL_MONSTER) {
            KillMessage(targ.netname, attacker.netname, mod);
            attacker.frags = attacker.frags + 1;
            logfrag(attacker, targ)
        }
        return;
    } // else if attacker != player

    if (targ.flags & FL_CLIENT) {
        WorldKillMessage(targ.netname, mod);
        targ.frags = targ.frags - 1;
        logfrag(targ, targ)
    }
};