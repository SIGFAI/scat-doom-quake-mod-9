// The stream demo, timed on the map's clock (console "wait" lines in demo.cfg run before the map is loaded):
// demo.cfg sets mc_demo 1, the director then stages each moment of the clip in front of the player.
class MCDirector : EventHandler
{
	override void WorldTick()
	{
		int t = level.maptime;
		if (mc_shots > 0 && t > 0 && t % mc_shots == 0) Console.PrintfEx(PRINT_NONOTIFY, "SIGF_SHOT %d", t);
		if (mc_demo <= 0) return;
		let p = players[consoleplayer].mo;
		if (!p) return;
		p.player.cheats |= CF_GODMODE;
		// The demo player only uses the block weapons, and never runs dry.
		let w = p.player.ReadyWeapon;
		if (t % 10 == 0 && w && !(w is "Nailgun") && !(w is "TNTLauncher") && !(w is "Pickaxe")) Arm(p, "Nailgun", 100);
		if (t % 35 == 0) { p.GiveInventory("Clip", 20); p.GiveInventory("RocketAmmo", 2); }
		int s = t / 35, f = t % 35;
		if (f != 0) return;
		switch (s)
		{
		// 1. The block world, and mobs to nail.
		case 1:
			Arm(p, "Nailgun", 150);
			Ahead(p, "CreeperFiend", 300, -15);
			Ahead(p, "ZombieGrunt", 340, 15);
			break;
		case 6:
			Ahead(p, "CreeperFiend", 300, 10);
			Ahead(p, "EnforcerBot", 360, -12);
			break;
		// 2. TNT blocks by an ogre: the launcher sets off the chain.
		case 12:
			Arm(p, "TNTLauncher", 30);
			TNTRow(p, 330);
			Ahead(p, "ChainsawOgre", 470, 0);
			Ahead(p, "CreeperFiend", 420, 16);
			break;
		// 3. The Cat warps in.
		case 21:
			Cat(p);
			break;
		case 25:
			p.GiveInventory("PowerQuadDamage", 1);
			p.A_StartSound("mc/quad", CHAN_AUTO, CHANF_UI);
			break;
		}
		// Then a wave every six seconds, so the player always has something to fight.
		if (s >= 32 && s % 6 == 2)
		{
			switch ((s / 6) % 5)
			{
			case 0: Arm(p, "Nailgun", 150); Ahead(p, "CreeperFiend", 420, -12); Ahead(p, "ZombieGrunt", 460, 12); break;
			case 1: Arm(p, "TNTLauncher", 20); TNTRow(p, 320); Ahead(p, "CreeperFiend", 440, 0); break;
			case 2: Ahead(p, "EnforcerBot", 470, -14); Ahead(p, "JetpackKitten", 380, 14); break;
			case 3: Arm(p, "SuperNailgun", 150); Ahead(p, "ChainsawOgre", 460, 0); break;
			case 4: p.GiveInventory("PowerQuadDamage", 1); p.A_StartSound("mc/quad", CHAN_AUTO, CHANF_UI); Ahead(p, "CreeperFiend", 400, 15); Ahead(p, "CreeperFiend", 450, -15); break;
			}
		}
		if (s > 21 && s % 12 == 0) Cat(p); // if it is gone, it comes back
	}

	void Arm(PlayerPawn p, Class<Weapon> w, int ammo)
	{
		p.GiveInventory(w, 1);
		let wp = Weapon(p.FindInventory(w));
		if (wp && wp.AmmoType1) p.GiveInventory(wp.AmmoType1, ammo);
		p.A_SelectWeapon(w);
	}

	// Spawns a mob on the floor, in view, about dist ahead of the player (angle offset in degrees), with a slipgate burst.
	Actor Ahead(PlayerPawn p, Class<Actor> cls, double dist, double ofs)
	{
		for (int i = 0; i < 40; i++)
		{
			double a = p.angle + ofs + (i ? frandom(-40, 40) : 0);
			double d = dist * (i ? frandom(0.7, 1.1) : 1.0);
			Vector2 xy = i < 20 ? p.Vec2Angle(d, a) : p.Vec2Angle(frandom(220, dist), frandom(0, 360)); // then anywhere in view
			double z = level.PointInSector(xy).floorplane.ZatPoint(xy);
			if (abs(z - p.pos.z) > 96) continue;
			let m = Actor.Spawn(cls, (xy, z));
			if (!m) continue;
			if (!m.TestMobjLocation() || !m.CheckSight(p)) { m.Destroy(); continue; }
			m.angle = m.AngleTo(p);
			if (m.bIsMonster) { m.target = p; if (m.SeeState) m.SetState(m.SeeState); Actor.Spawn("TeleportFog", m.pos, ALLOW_REPLACE); }
			return m;
		}
		return null;
	}

	// A row of TNT blocks across the player's view: one hit and they go off one after another.
	void TNTRow(PlayerPawn p, double dist)
	{
		for (int i = -2; i <= 2; i++)
		{
			Vector2 xy = p.Vec2Angle(dist, p.angle) + Actor.AngleToVector(p.angle + 90, i * 36);
			double z = level.PointInSector(xy).floorplane.ZatPoint(xy);
			if (abs(z - p.pos.z) > 64) continue;
			let b = Actor.Spawn("TNTBlock", (xy, z));
			if (b && !b.TestMobjLocation()) b.Destroy();
			else if (b) Actor.Spawn("TeleportFog", b.pos, ALLOW_REPLACE);
		}
	}

	void Cat(PlayerPawn p)
	{
		let q = CatQuest(EventHandler.Find("CatQuest"));
		if (q && q.cat && q.cat.health > 0) return;
		if (q && q.catBeaten) return;
		let c = Ahead(p, "SuperIntelligentCat", 460, 0);
		if (c) c.SetOrigin(c.pos + (0, 0, 40), false);
	}
}
