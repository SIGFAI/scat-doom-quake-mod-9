// The story: a SuperIntelligent Cat knocked a Quake slipgate off the desk and Doom fell into a world of blocks.
// Kill enough mobs and the Cat notices you and warps in. Take all nine of its lives.
// Everything the HUD shows (chat lines, advancement toasts, the quest, the boss bar) lives here.
class CatQuest : EventHandler
{
	const LURE_KILLS = 8;
	const CHAT_TICS = 35 * 9;

	SuperIntelligentCat cat;
	int catLives;
	bool catCame, catBeaten;
	int kills;
	Array<String> chat;
	Array<int> chatAt;
	Array<String> toastTitle;
	Array<int> toastAt;
	Array<String> earned;
	int levelUpAt, levelShown;
	int bigMsgAt;
	String bigMsg;
	Array<JetpackKitten> kittens;

	static const String ARRIVE_LINES[] = {
		"Meow. I have computed 9,000 ways to delete you. All of them are cubes.",
		"You broke my minions. I calculated that you would. Purr.",
		"I knocked the Quake slipgate off the desk. On purpose. Obviously."
	};
	static const String SUMMON_LINES[] = {
		"Kittens! Deploy the jetpacks.",
		"My minions are cute AND tactically optimal.",
		"Distraction protocol: kittens."
	};
	static const String LIFE_LINES[] = {
		"Ow. That was one life. I have backups.",
		"Statistically irrelevant. I am a cat.",
		"You hit me? I will knock your coffee off a table. In another dimension.",
		"Fine. Rebooting brain... done.",
		"This is why I knock things off desks.",
		"Hiss. My dome needs a polish now.",
		"I am no longer amused. Slightly amused. No.",
		"Last-but-one life. I may be in some danger."
	};
	static const String RETURN_LINES[] = {
		"Slipgate recalibrated. Hello again.",
		"Did you miss me? Your aim did.",
		"Teleported. With style.",
		"Back. My brain is still bigger than your gun."
	};
	static const String IDLE_LINES[] = {
		"Fun fact: Quake is Doom with more brown. I fixed it. With blocks.",
		"I can see your hitbox. It is a cube now.",
		"The red dot is not a toy. Mostly.",
		"My IQ is 9,000. My lives are 9. Coincidence? No."
	};

	// Doom's start items are given by exact class: swap the fist and pistol for the pickaxe and nailgun.
	override void PlayerEntered(PlayerEvent e)
	{
		let p = players[e.PlayerNumber].mo;
		if (!p) return;
		if (p.FindInventory("Fist")) { p.TakeInventory("Fist", 1); p.GiveInventory("Pickaxe", 1); }
		if (p.FindInventory("Pistol"))
		{
			bool ready = p.player.ReadyWeapon is "Pistol" && !(p.player.ReadyWeapon is "Nailgun");
			p.TakeInventory("Pistol", 1);
			p.GiveInventory("Nailgun", 1);
			if (ready) p.A_SelectWeapon("Nailgun");
		}
	}

	override void WorldLoaded(WorldEvent e)
	{
		if (e.IsSaveGame) return;
		BigMessage("A CAT TURNED DOOM INTO BLOCKS");
		Say("The SuperIntelligent Cat knocked a Quake slipgate off the desk.");
		Say("Now Doom is made of blocks. Kill mobs until the Cat notices you.");
	}

	override void WorldTick()
	{
		int t = level.maptime;
		if (cat && cat.health > 0 && !cat.knocked && t % (35 * 22) == 0) CatSays(IDLE_LINES[random(0, IDLE_LINES.Size() - 1)]);
		for (int i = kittens.Size() - 1; i >= 0; i--) if (!kittens[i] || kittens[i].health <= 0) kittens.Delete(i);
		if (cat) catLives = cat.lives;
	}

	override void WorldThingSpawned(WorldEvent e)
	{
		let k = JetpackKitten(e.Thing);
		if (k) kittens.Push(k);
	}

	override void WorldThingDied(WorldEvent e)
	{
		let m = e.Thing;
		if (!m || !m.bIsMonster || m is "SuperIntelligentCat") return;
		kills++;
		String who = m.GetTag();
		String how = KillVerb(e.Inflictor, m);
		Say(String.Format("%s %s", who, how));
		if (e.Inflictor is "NailShot") Earn("Nailed It!");
		if (m.health < -m.GetGibHealth() || m.health < -40) Earn("Overkill: Cubed Gibs");
		if (!catCame && kills >= LURE_KILLS && level.maptime > 35 * 20) SummonCat();
	}

	String KillVerb(Actor inf, Actor m)
	{
		String p = PlayerName();
		if (inf is "NailShot") return "was nailed by " .. p;
		if (inf is "TNTGrenade") return "was blown up by " .. p .. "'s TNT";
		if (inf is "TNTBlock") return "was blown up by TNT";
		if (inf is "CreeperFiend") return "was blown up by a Creeper Fiend";
		if (inf is "CatTNT") return "was blown up by the Cat. Friendly fire!";
		if (inf && inf.player) return "was slain by " .. p;
		return "was slain";
	}

	clearscope String PlayerName()
	{
		String n = players[consoleplayer].GetUserName();
		return (n == "" || n ~== "Player") ? "Doomguy" : n;
	}

	void Say(String s)
	{
		chat.Push(s);
		chatAt.Push(level.maptime);
		if (chat.Size() > 7) { chat.Delete(0); chatAt.Delete(0); }
		Console.PrintfEx(PRINT_NONOTIFY, "MC_CHAT %s", s);
	}

	void CatSays(String s)
	{
		Say("<SuperIntelligentCat> " .. s);
	}

	void Earn(String title)
	{
		if (earned.Find(title) != earned.Size()) return;
		earned.Push(title);
		toastTitle.Push(title);
		toastAt.Push(level.maptime);
		S_StartSound("mc/levelup", CHAN_AUTO, CHANF_UI, 0.6);
	}

	void BigMessage(String s)
	{
		bigMsg = s;
		bigMsgAt = level.maptime;
	}

	void LevelUp(int l)
	{
		levelUpAt = level.maptime;
		levelShown = l;
		if (l >= 5) Earn("Big Brain Energy (level 5)");
	}

	void Blast(Actor tnt)
	{
		Earn("That's a Nice Doom You Have There");
	}

	int KittensAlive() { return kittens.Size(); }

	// The Cat warps in through a slipgate in front of the player.
	void SummonCat()
	{
		let p = players[consoleplayer].mo;
		if (!p || catCame) return;
		for (int i = 0; i < 30; i++)
		{
			Vector2 xy = p.Vec2Angle(frandom(300, 520), p.angle + frandom(-35, 35));
			double z = level.PointInSector(xy).floorplane.ZatPoint(xy);
			if (abs(z - p.pos.z) > 128) continue;
			let c = Actor.Spawn("SuperIntelligentCat", (xy, z + 40));
			if (!c) continue;
			if (!c.TestMobjLocation() || !c.CheckSight(p)) { c.Destroy(); continue; }
			c.target = p;
			c.angle = c.AngleTo(p);
			c.SetStateLabel("See");
			return;
		}
	}

	void CatArrived(SuperIntelligentCat c)
	{
		cat = c;
		catCame = true;
		catLives = c.lives;
		BigMessage("THE SUPERINTELLIGENT CAT HAS ARRIVED");
		CatSays(ARRIVE_LINES[random(0, ARRIVE_LINES.Size() - 1)]);
	}

	void CatLostLife(SuperIntelligentCat c, Actor by)
	{
		catLives = c.lives;
		BigMessage(String.Format("ONE LIFE DOWN!  %d LIVES LEFT", c.lives));
		CatSays(LIFE_LINES[clamp(8 - c.lives, 0, LIFE_LINES.Size() - 1)]);
		Earn("Curiosity Killed the Cat (1/9)");
		if (c.lives == 1) Earn("Eight Down, One to Go");
	}

	void CatDefeated(SuperIntelligentCat c)
	{
		catLives = 0;
		catBeaten = true;
		BigMessage("THE CAT IS OUT OF LIVES!");
		CatSays("Meow. (It is just a regular cat now.)");
		Earn("Nine Lives, Zero Left: Cat Defeated");
	}
}
