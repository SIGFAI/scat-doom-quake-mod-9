// The SuperIntelligent Cat: a jetpack boss with a glass-domed brain. It lasers you with its laser pointer, lobs TNT,
// calls jetpack kittens through slipgates, and has nine lives: each "death" knocks it out, a ghost life floats away,
// and it warps back through a Quake slipgate with full health. The ninth death is the real one.
class SuperIntelligentCat : Actor
{
	const MAX_LIVES = 9;
	int lives;
	bool knocked;
	int kittensMade;

	Default
	{
		Monster;
		Health 220;
		Radius 30;
		Height 110;
		Scale 1.2;
		Speed 9;
		FloatSpeed 3;
		Mass 1200;
		PainChance 70;
		MinMissileChance 100;
		+FLOAT +NOGRAVITY +DONTMORPH +NOINFIGHTSPECIES +FLOORCLIP +DONTGIB +BRIGHT
		SeeSound "cat/sight";
		PainSound "cat/hiss";
		DeathSound "cat/die";
		ActiveSound "cat/meow1";
		Obituary "%o was outsmarted by the SuperIntelligent Cat.";
		Tag "The SuperIntelligent Cat";
	}
	States
	{
	Spawn:
		SCAT AB 6 A_Look;
		Loop;
	See:
		SCAT AABB 3 A_CatChase;
		Loop;
	Missile:
		SCAT A 0 A_CatPlan;
		Goto Laser;
	Laser:
		SCAT C 10 A_FaceTarget;
		SCAT C 3 Bright A_CatLaser;
		SCAT C 3 Bright A_CatLaser;
		SCAT C 3 Bright A_CatLaser;
		SCAT C 3 Bright A_CatLaser;
		SCAT A 8;
		Goto See;
	Lob:
		SCAT C 8 A_FaceTarget;
		SCAT C 6 A_CatTNT;
		SCAT A 8 A_FaceTarget;
		SCAT C 6 A_CatTNT;
		SCAT A 6;
		Goto See;
	Summon:
		SCAT B 6 A_FaceTarget;
		SCAT B 14 A_CatSummon;
		Goto See;
	Pain:
		SCAT D 3;
		SCAT D 7 A_Pain;
		Goto See;
	KnockedOut:
		SCAT E 4 A_CatKnocked;
		SCAT E 4 A_Dazed;
		SCAT E 4 A_Dazed;
		SCAT E 4 A_Dazed;
		SCAT E 4 A_Dazed;
		SCAT E 4 A_Dazed;
		SCAT E 4 A_Dazed;
		SCAT E 4 A_Dazed;
		SCAT E 4 A_Dazed;
		SCAT E 4 A_Dazed;
		SCAT E 4 A_Dazed;
		SCAT E 4 A_Dazed;
		SCAT E 1 A_CatWarpOut;
		TNT1 A 30;
		SCAT B 1 A_CatWarpIn;
		Goto See;
	Relocate:
		SCAT B 1 A_CatWarpOut;
		TNT1 A 24;
		SCAT B 1 A_CatWarpIn(false);
		Goto See;
	Death:
		SCAT D 6 A_Scream;
		SCAT E 4 A_CatFinale;
		SCAT E 4 A_Dazed;
		SCAT E 4 A_Dazed;
		SCAT E 4 A_Dazed;
		SCAT E 4 A_Dazed;
		SCAT E 4 A_Dazed;
		SCAT E 4 A_Dazed;
		SCAT E 4 A_Dazed;
		SCAT E 4 A_Dazed;
		SCAT E 4 A_Dazed;
		SCAT E 1 A_CatGone;
		Stop;
	}

	override void BeginPlay()
	{
		super.BeginPlay();
		lives = MAX_LIVES;
		bBuddha = true; // a lethal hit only knocks out one life (see DamageMobj)
	}

	override void PostBeginPlay()
	{
		super.PostBeginPlay();
		let q = CatQuest(EventHandler.Find("CatQuest"));
		if (q) q.CatArrived(self);
		Actor.Spawn("Slipgate", pos);
	}

	override int DamageMobj(Actor inflictor, Actor source, int damage, Name mod, int flags, double angle)
	{
		if (knocked) return 0;
		int r = super.DamageMobj(inflictor, source, damage, mod, flags, angle);
		if (health <= 1 && lives > 1 && !knocked) LoseLife(source);
		return r;
	}

	void LoseLife(Actor by)
	{
		knocked = true;
		lives--;
		bBuddha = lives > 1;
		bShootable = false;
		bNoGravity = false; // it drops out of the air, dazed
		SetStateLabel("KnockedOut");
		let q = CatQuest(EventHandler.Find("CatQuest"));
		if (q) q.CatLostLife(self, by);
	}

	int unseen;

	void A_CatChase()
	{
		A_Chase();
		// Lost sight of its prey for four seconds: it slipgates to a spot in front of it. Cats always find you.
		if (target && !CheckSight(target)) unseen++;
		else unseen = 0;
		if (unseen > 35 * 4 / 3)
		{
			unseen = 0;
			SetStateLabel("Relocate");
			return;
		}
		// The jetpack keeps it about a block and a half off the floor.
		if (pos.z - floorz < 40) vel.z = min(vel.z + 0.6, 2);
		else if (pos.z - floorz > 80) vel.z = max(vel.z - 0.4, -2);
		if (level.maptime % 3 == 0)
			MCFX.Squares(pos + (0, 0, 6), "ffa020", 2, 1.2, 4, 10, -2.5, 0, true, 14);
	}

	void A_CatPlan()
	{
		int r = random(0, 99);
		let q = CatQuest(EventHandler.Find("CatQuest"));
		int alive = q ? q.KittensAlive() : 0;
		if (alive < 2 && r < 25) SetStateLabel("Summon");
		else if (r < 62) SetStateLabel("Laser");
		else SetStateLabel("Lob");
	}

	// The laser pointer: a thin red beam, a red dot where it lands.
	void A_CatLaser()
	{
		A_StartSound("mc/laser", CHAN_WEAPON, CHANF_OVERLAP, 0.8);
		A_CustomRailgun(5, 0, "ff1010", 0, RGF_SILENT | RGF_FULLBRIGHT | RGF_NOPIERCING, 1, 0, "LaserDot", 1.5, 1.5, 4096, 8, 0.25, 0, null, 18);
		if (!target) return;
		// A chunky beam of red squares, so the laser pointer reads from across the room.
		Vector3 from = pos + (0, 0, 76);
		Vector3 to = target.pos + (0, 0, target.height * 0.5);
		Vector3 d = to - from;
		double len = d.Length();
		FLineTraceData hit;
		if (LineTrace(AngleTo(target), len, -atan2(d.z, d.xy.Length()), TRF_THRUACTORS, 64, data: hit)) len = hit.Distance;
		Vector3 u = d.Unit();
		for (double s = 24; s < len - 56; s += 9) // stops short of the victim: squares at the camera would fill the screen
			MCFX.Squares(from + u * s, "ff2020", 1, 0, 3.5, 5, 0, 0, true, 0);
		A_AttachLight('laser', DynamicLight.PointLight, "ff2020", 48, 48, 0, (0, 0, 64));
	}

	void A_CatTNT()
	{
		if (!target) return;
		A_StartSound("mc/swing", CHAN_WEAPON);
		Lob(self, "CatTNT", target, 64);
	}

	// Throws an arcing projectile so that it lands near the target (gravity g per tic, about 30 tics of flight).
	static void Lob(Actor from, Class<Actor> what, Actor at, double zofs)
	{
		let m = Actor.Spawn(what, from.pos + (0, 0, zofs));
		if (!m) return;
		m.target = from;
		double d = from.Distance2D(at);
		double tics = clamp(d / 16., 14, 40);
		double g = m.GetGravity();
		double ang = from.AngleTo(at) + frandom(-6, 6);
		m.Vel.XY = Actor.AngleToVector(ang, d / tics);
		m.Vel.Z = (at.pos.z - m.pos.z) / tics + 0.5 * g * tics;
	}

	void A_CatSummon()
	{
		A_StartSound("cat/meow2", CHAN_VOICE);
		for (int i = 0; i < 2; i++)
		{
			Vector3 p = Vec3Angle(80, angle + (i ? 70 : -70), 24);
			let k = Actor.Spawn("JetpackKitten", p);
			if (!k) continue;
			if (!k.TestMobjLocation()) { k.Destroy(); continue; }
			Actor.Spawn("Slipgate", k.pos).scale = (0.5, 0.5);
			k.target = target;
			k.SetStateLabel("See");
			kittensMade++;
		}
		let q = CatQuest(EventHandler.Find("CatQuest"));
		if (q) q.CatSays(q.SUMMON_LINES[random(0, q.SUMMON_LINES.Size() - 1)]);
	}

	void A_CatKnocked()
	{
		A_StartSound("cat/die", CHAN_VOICE);
		let g = Actor.Spawn("CatLife", pos + (0, 0, 40));
		MCFX.Squares(pos + (0, 0, 60), "ffff60", 16, 3, 4, 30, 1, 0, true, 16);
	}

	// Cartoon stars circling its head.
	void A_Dazed()
	{
		double a = level.maptime * 24;
		for (int i = 0; i < 3; i++)
		{
			double t = a + i * 120;
			MCFX.Squares(pos + (cos(t) * 22, sin(t) * 22, 62), "ffe040", 1, 0, 4, 6, 0, 0, true, 0);
		}
	}

	void A_CatWarpOut()
	{
		Actor.Spawn("Slipgate", pos);
		bInvisible = true;
		A_StartSound("mc/teleport", CHAN_BODY);
	}

	// Back through a slipgate somewhere in view of its target, with a fresh life.
	void A_CatWarpIn(bool fresh = true)
	{
		Actor t = target ? target : Actor(players[consoleplayer].mo);
		if (t)
		{
			Vector3 old = pos;
			for (int i = 0; i < 48; i++)
			{
				// In front of the target first, then anywhere it can see.
				Vector2 xy = i < 24 ? t.Vec2Angle(frandom(300, 540), t.angle + frandom(-50, 50)) : t.Vec2Angle(frandom(200, 480), frandom(0, 360));
				double z = level.PointInSector(xy).floorplane.ZatPoint(xy) + 48;
				SetOrigin((xy, z), false);
				if (TestMobjLocation() && CheckSight(t) && abs(z - t.pos.z) < 200) break;
				SetOrigin(old, false);
			}
		}
		Actor.Spawn("Slipgate", pos);
		bInvisible = false;
		bShootable = true;
		bNoGravity = true;
		knocked = false;
		A_StartSound("cat/meow2", CHAN_VOICE);
		if (target) angle = AngleTo(target);
		if (!fresh) return;
		A_SetHealth(SpawnHealth());
		let q = CatQuest(EventHandler.Find("CatQuest"));
		if (q) q.CatSays(q.RETURN_LINES[random(0, q.RETURN_LINES.Size() - 1)]);
	}

	// The ninth life: a shower of XP, and the Cat is just a cat again.
	void A_CatFinale()
	{
		A_NoBlocking();
		MCFX.DropXP(self, 40);
		MCFX.Squares(pos + (0, 0, 50), "ff60ff", 30, 5, 5, 40, 1, -0.2, true, 20);
		Actor.Spawn("CatLife", pos + (0, 0, 40));
		let q = CatQuest(EventHandler.Find("CatQuest"));
		if (q) q.CatDefeated(self);
	}

	void A_CatGone()
	{
		MCFX.Poof(self);
		let k = Actor.Spawn("PlainKitten", pos);
	}
}

// The Cat's TNT: bounces, hisses, blows after two seconds (or on hitting someone).
class CatTNT : Actor
{
	Default
	{
		Projectile;
		-NOGRAVITY
		Radius 8; Height 12; Speed 0; Gravity 0.7; Damage 0;
		BounceType "Doom"; BounceFactor 0.4; WallBounceFactor 0.5; BounceCount 6;
		+ROLLSPRITE +ROLLCENTER -BOUNCEAUTOOFF +EXPLODEONWATER +CANBOUNCEWATER
		Scale 0.45;
		SeeSound "mc/tntfuse";
		Obituary "%o caught the Cat's TNT.";
	}
	States
	{
	Spawn:
		TNTB A 3 A_Fuse;
		TNTB B 3 A_Fuse;
		Loop;
	Death:
		TNT1 A 0 A_TNTPop;
		TNT1 A 10;
		Stop;
	}
	void A_Fuse()
	{
		roll += 23;
		MCFX.Squares(pos + (0, 0, 8), "ffd060", 1, 1, 2, 10, 0.5, 0, true, 2);
		if (GetAge() > 60) SetStateLabel("Death");
	}
	void A_TNTPop()
	{
		bNoGravity = true;
		vel = (0, 0, 0);
		roll = 0;
		MCFX.Boom(self, 0.8);
		A_Explode(48, 128);
	}
	override int SpecialMissileHit(Actor victim)
	{
		// Bounces off walls and floors, blows up on the first creature it touches (not its thrower).
		if (victim == target || !victim.bShootable) return 1;
		SetStateLabel("Death");
		return 1;
	}
}

// Where the laser pointer lands: a bright red dot and a sizzle.
class LaserDot : Actor
{
	Default { +NOINTERACTION +NOBLOCKMAP +PUFFONACTORS +ALWAYSPUFF RenderStyle "None"; }
	States
	{
	Spawn:
		TNT1 A 1 NoDelay A_Dot;
		Stop;
	}
	void A_Dot()
	{
		MCFX.Squares(pos, "ff2020", 6, 1.5, 3, 14, 0.5, 0, true, 2);
		MCFX.Squares(pos, "ffd0d0", 2, 0.5, 4, 8, 0, 0, true, 0);
	}
}

// One of the Cat's nine lives, leaving as a ghostly cat that floats up and fades.
class CatLife : Actor
{
	Default
	{
		+NOINTERACTION +NOBLOCKMAP +NOGRAVITY +BRIGHT
		RenderStyle "AddStencil"; StencilColor "a0e8ff"; Alpha 0.8; Scale 0.9;
	}
	States
	{
	Spawn:
		SCAT A 1 A_Float;
		Loop;
	}
	void A_Float()
	{
		vel.z = 1.1;
		vel.xy = (sin(GetAge() * 8) * 1.2, 0);
		if (GetAge() % 3 == 0) MCFX.Squares(pos + (0, 0, 30), "e0f8ff", 1, 0.5, 3, 20, 0.5, 0, true, 14);
		if (GetAge() > 60) { A_FadeOut(0.03); }
	}
}

// A Quake slipgate opening and closing: the swirling portal grows, spins, shrinks.
class Slipgate : Actor
{
	Default { +NOINTERACTION +NOBLOCKMAP +NOGRAVITY +BRIGHT +FORCEYBILLBOARD RenderStyle "Normal"; }
	States
	{
	Spawn:
		SGAT ABCD 3 A_Gate;
		Loop;
	}
	double full;
	override void PostBeginPlay()
	{
		super.PostBeginPlay();
		full = scale.x;
		scale = (0.05, 0.05) * full;
		A_StartSound("mc/teleport", CHAN_BODY);
	}
	void A_Gate()
	{
		int t = GetAge();
		double s = t < 10 ? t / 10. : (t > 40 ? max(0, (55 - t) / 15.) : 1.0);
		if (s <= 0.02) { Destroy(); return; }
		scale = (s, s) * full;
		A_AttachLight('gate', DynamicLight.PointLight, "9050ff", int(140 * s * full), int(140 * s * full));
		MCFX.Squares(pos + (0, 0, 45 * full), "a070ff", 3, 2, 4, 20, 0.3, 0, true, 26 * full);
	}
}

// What is left after the ninth life: a regular, tiny, harmless kitten.
class PlainKitten : Actor
{
	Default
	{
		Radius 10; Height 24; Speed 4; Health 100;
		+FRIENDLY +NOTARGET -COUNTKILL +NOBLOOD +INVULNERABLE +NEVERTARGET
		Monster;
		-SHOOTABLE
		ActiveSound "cat/meow1";
		Tag "Just a Cat";
	}
	States
	{
	Spawn:
		KITN AB 8 A_Wander;
		Loop;
	}
}
