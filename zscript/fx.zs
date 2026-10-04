// Shared effects: Minecraft-style square particles, block debris, blocky gibs, XP orbs, the death poof, TNT blasts.
class MCFX play
{
	static TextureID Square()
	{
		return TexMan.CheckForTexture("MCSQR", TexMan.Type_Any);
	}

	// n square particles of colour c around a point; speed in units/tic, size in units.
	static void Squares(Vector3 at, Color c, int n, double speed, double size, int life = 30, double up = 0, double grav = -0.35, bool bright = false, double spread = 6)
	{
		FSpawnParticleParams p;
		p.color1 = c;
		p.texture = Square();
		p.style = STYLE_Normal;
		p.flags = SPF_REPLACE | (bright ? SPF_FULLBRIGHT : 0);
		p.startalpha = 1;
		p.fadestep = -1;
		for (int i = 0; i < n; i++)
		{
			p.lifetime = int(life * frandom(0.6, 1.2));
			p.size = size * frandom(0.6, 1.3);
			p.sizestep = -p.size / (p.lifetime * 1.5);
			p.pos = at + (frandom(-spread, spread), frandom(-spread, spread), frandom(-spread, spread));
			double a = frandom(0, 360), pt = frandom(-80, 30);
			double s = speed * frandom(0.4, 1.0);
			p.vel = (cos(a) * cos(pt) * s, sin(a) * cos(pt) * s, -sin(pt) * s + up);
			p.accel = (0, 0, grav);
			level.SpawnParticle(p);
		}
	}

	// Minecraft's death poof: grey-white puffs drifting up.
	static void Poof(Actor a)
	{
		Squares(a.pos + (0, 0, a.height * 0.4), "dddddd", 14, 1.2, 9, 35, 0.6, 0.02, false, a.radius);
		Squares(a.pos + (0, 0, a.height * 0.4), "999999", 8, 1.0, 7, 30, 0.5, 0.02, false, a.radius);
	}

	static void DropXP(Actor a, int n)
	{
		for (int i = 0; i < n; i++)
		{
			let o = Actor.Spawn("XPOrb", a.pos + (0, 0, a.height * 0.5));
			if (o) o.vel = (frandom(-4, 4), frandom(-4, 4), frandom(4, 8));
		}
	}

	// Quake gibs, Minecraft style: cubes of meat and blood squares.
	static void Gibs(Actor a, int n)
	{
		for (int i = 0; i < n; i++)
		{
			let g = Actor.Spawn("BlockGib", a.pos + (frandom(-8, 8), frandom(-8, 8), frandom(8, a.height)));
			if (g) g.vel = (frandom(-5, 5), frandom(-5, 5), frandom(4, 9));
		}
		Squares(a.pos + (0, 0, a.height * 0.5), "aa1010", 24, 6, 5, 40);
		Squares(a.pos + (0, 0, a.height * 0.5), "e03030", 12, 5, 4, 30);
		a.A_StartSound("mc/break", CHAN_AUTO, pitch: 0.7);
	}

	static void Debris(Vector3 at, int n, double force)
	{
		for (int i = 0; i < n; i++)
		{
			let d = Actor.Spawn("BlockDebris", at + (frandom(-8, 8), frandom(-8, 8), frandom(0, 16)));
			if (d) d.vel = (frandom(-force, force), frandom(-force, force), frandom(force * 0.5, force * 1.4));
		}
	}

	// A TNT blast: flash, white smoke cubes, fire squares, flying blocks, a shake. Damage is the caller's A_Explode.
	static void Boom(Actor a, double size = 1.0)
	{
		Vector3 c = a.pos + (0, 0, 8);
		a.A_StartSound("mc/boom", CHAN_AUTO, attenuation: 0.6);
		a.A_QuakeEx(2 * size, 2 * size, 1.5 * size, 18, 0, 700 * size, "", QF_SCALEDOWN);
		Squares(c, "ffffff", int(22 * size), 3.5 * size, 18 * size, 45, 1.0, 0.0, false, 20 * size);
		Squares(c, "b4b4b4", int(18 * size), 3.0 * size, 15 * size, 50, 0.8, 0.0, false, 24 * size);
		Squares(c, "ffb030", int(20 * size), 7.0 * size, 7, 18, 1.0, -0.2, true, 10 * size);
		Squares(c, "ff5010", int(14 * size), 9.0 * size, 5, 14, 1.0, -0.2, true, 10 * size);
		Debris(c, int(9 * size), 6 * size);
		let l = Actor.Spawn("BoomLight", c);
		if (l) l.scale = (size, size);
	}
}

// The flash of an explosion: a light that fades in a third of a second.
class BoomLight : Actor
{
	Default { +NOINTERACTION +NOBLOCKMAP +NOGRAVITY RenderStyle "None"; }
	States
	{
	Spawn:
		TNT1 A 12;
		Stop;
	}
	override void Tick()
	{
		super.Tick();
		int r = int(320 * scale.x * (1.0 - GetAge() / 12.0));
		if (r > 8) A_AttachLight('boom', DynamicLight.PointLight, "ffb060", r, r);
		else A_RemoveLight('boom');
	}
}

// A small block flying out of a blast, spinning, bouncing, then sinking away.
class BlockDebris : Actor
{
	double spin;
	Default
	{
		Radius 3; Height 4; Gravity 0.8; BounceType "Doom"; BounceFactor 0.35; WallBounceFactor 0.4;
		+NOBLOCKMAP +DROPOFF +NOTELEPORT +MISSILE +THRUACTORS +ROLLSPRITE +ROLLCENTER +BOUNCEONACTORS -BOUNCEAUTOOFF
		+FORCEXYBILLBOARD +NOTRIGGER
		Scale 1.3;
	}
	States
	{
	Spawn:
		BLKD # 1 A_Spin;
		Loop;
	Death:
		BLKD # 60;
		BLKD # 2 A_FadeOut(0.1);
		Wait;
	Precache:
		BLKD ABCDEFGH 0;
		Stop;
	}
	override void PostBeginPlay()
	{
		super.PostBeginPlay();
		frame = random(0, 7);
		spin = frandom(-25, 25);
		scale *= frandom(0.8, 1.4);
	}
	// A chunk that flies into the camera would cover the screen: it vanishes instead.
	bool NearCamera()
	{
		let p = players[consoleplayer].mo;
		return p && Distance3D(p) < 56;
	}

	void A_Spin()
	{
		if (NearCamera()) { Destroy(); return; }
		roll += spin;
		if (GetAge() > 90) SetStateLabel("Death");
	}
}

// A blocky meat gib (Quake's gibs, made of cubes).
class BlockGib : BlockDebris
{
	Default { Scale 1.1; BounceFactor 0.25; }
	States
	{
	Spawn:
		GIBC # 1 A_GibSpin;
		Loop;
	Death:
		GIBC # 80;
		GIBC # 2 A_FadeOut(0.1);
		Wait;
	Precache:
		GIBC ABCDE 0;
		Stop;
	}
	override void PostBeginPlay()
	{
		super.PostBeginPlay();
		frame = random(0, 4);
	}
	void A_GibSpin()
	{
		if (NearCamera()) { Destroy(); return; }
		roll += spin;
		if (level.maptime % 3 == 0) MCFX.Squares(pos, "991010", 1, 0.3, 3, 25, 0, -0.3, false, 1);
		if (GetAge() > 100) SetStateLabel("Death");
	}
}

// Experience orb: pops out of a dead mob, then flies into the nearest player and fills the XP bar.
class XPOrb : Actor
{
	Default
	{
		Radius 4; Height 8; Gravity 0.6; BounceType "Doom"; BounceFactor 0.5; Scale 1.2;
		+NOBLOCKMAP +DROPOFF +NOTELEPORT +FORCEXYBILLBOARD +BRIGHT +NOTRIGGER
	}
	States
	{
	Spawn:
		XPOR ABCDCB 3 A_Orb;
		Loop;
	}
	void A_Orb()
	{
		if (GetAge() < 18) return;
		Actor p = null;
		double best = 500;
		for (int i = 0; i < MAXPLAYERS; i++)
		{
			if (!playeringame[i] || !players[i].mo || players[i].mo.health <= 0) continue;
			double d = Distance3D(players[i].mo);
			if (d < best) { best = d; p = players[i].mo; }
		}
		if (!p) { if (GetAge() > 35 * 30) Destroy(); return; }
		// Aim at the player's knees: the orbs stream in under the view instead of flying into the camera.
		Vector3 to = p.pos + (0, 0, 12) - pos;
		if (to.Length() < 40)
		{
			MCXP.Add(p, random(1, 3));
			A_StartSound("mc/xp", CHAN_AUTO, CHANF_OVERLAP, 0.7, pitch: frandom(0.8, 1.3));
			Destroy();
			return;
		}
		bNoGravity = true;
		vel = vel * 0.75 + to.Unit() * (4 + (500 - best) / 50.);
	}
}

// The player's experience: points in an inventory item, levels like Minecraft (each level needs 7 + 2L points).
class MCXP : Inventory
{
	Default { Inventory.MaxAmount 999999; +INVENTORY.UNDROPPABLE +INVENTORY.UNTOSSABLE }

	static clearscope int LevelOf(int pts, out double frac)
	{
		int l = 0;
		while (pts >= 7 + 2 * l) { pts -= 7 + 2 * l; l++; }
		frac = pts / double(7 + 2 * l);
		return l;
	}

	static void Add(Actor p, int n)
	{
		double f;
		int before = LevelOf(p.CountInv("MCXP"), f);
		p.GiveInventory("MCXP", n);
		int after = LevelOf(p.CountInv("MCXP"), f);
		if (after > before)
		{
			p.A_StartSound("mc/levelup", CHAN_AUTO, CHANF_OVERLAP);
			let q = CatQuest(EventHandler.Find("CatQuest"));
			if (q) q.LevelUp(after);
		}
	}
}

// Blood is blocky: red squares and the odd meat cube.
class MCBlood : Blood replaces Blood
{
	States
	{
	Spawn:
		TNT1 A 1 NoDelay A_Bleed;
		Stop;
	}
	void A_Bleed()
	{
		MCFX.Squares(pos, "b01818", 7, 3, 4, 26, 1.5);
		MCFX.Squares(pos, "e83a3a", 3, 2.5, 3, 20, 1.5);
	}
}

// Bullets chip the blocks: grey chips and a spark.
class MCPuff : BulletPuff replaces BulletPuff
{
	States
	{
	Spawn:
		TNT1 A 1 NoDelay A_Chip;
		Stop;
	}
	void A_Chip()
	{
		MCFX.Squares(pos, "8a8a8a", 5, 2.5, 4, 24, 1.0);
		MCFX.Squares(pos, "ffe080", 3, 4, 2, 8, 0, 0, true);
		if (random(0, 3) == 0) A_StartSound("mc/dig", CHAN_AUTO, CHANF_OVERLAP, 0.5);
	}
}

// Teleporting (Doom's teleporters, the waves, the Cat): a Quake slipgate burst in purple squares.
class MCTeleFog : TeleportFog replaces TeleportFog
{
	States
	{
	Spawn:
		TNT1 A 1 NoDelay A_Warp;
		TNT1 A 20;
		Stop;
	}
	void A_Warp()
	{
		A_StartSound("mc/teleport", CHAN_AUTO);
		MCFX.Squares(pos + (0, 0, 28), "8040ff", 26, 3, 6, 30, 0.6, 0, true, 16);
		MCFX.Squares(pos + (0, 0, 28), "d0b0ff", 12, 2, 4, 30, 0.8, 0, true, 16);
	}
}
