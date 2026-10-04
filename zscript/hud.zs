// A Minecraft HUD for Doom: hotbar (weapons in their slots, ammo as the stack count), hearts, armor, XP bar and level,
// plus the Cat's boss bar, the chat, advancement toasts and the quest line. Virtual screen 640x360, 1 art px = 1 px.
class BlockHUD : BaseStatusBar
{
	HUDFont small, big;

	override void Init()
	{
		super.Init();
		SetSize(0, 640, 360);
		small = HUDFont.Create(SmallFont);
		big = HUDFont.Create(BigFont);
	}

	override void Draw(int state, double TicFrac)
	{
		super.Draw(state, TicFrac);
		if (state == HUD_None || state == HUD_AltHUD) return;
		BeginHUD(1, true, 640, 360);
		let q = CatQuest(EventHandler.Find("CatQuest"));
		DrawCrosshair();
		DrawHotbar();
		DrawBars();
		if (q)
		{
			DrawBoss(q);
			DrawChat(q);
			DrawToast(q);
			DrawQuest(q);
			DrawBig(q);
		}
	}

	void DrawCrosshair()
	{
		DrawImage("HUDCROS", (0, 0), DI_SCREEN_CENTER | DI_ITEM_CENTER, 0.85, scale: (0.5, 0.5));
	}

	// The weapon a hotbar slot shows: the ready one if it sits there, else the first one owned.
	Weapon SlotWeapon(int slot)
	{
		Weapon best = null;
		for (let it = CPlayer.mo.Inv; it; it = it.Inv)
		{
			let w = Weapon(it);
			if (!w) continue;
			bool found; int s, idx;
			[found, s, idx] = CPlayer.weapons.LocateWeapon(w.GetClass());
			if (!found || s != slot) continue;
			if (w == CPlayer.ReadyWeapon) return w;
			if (!best) best = w;
		}
		return best;
	}

	void DrawHotbar()
	{
		int f = DI_SCREEN_CENTER_BOTTOM | DI_ITEM_LEFT_TOP;
		int sel = -1;
		for (int i = 0; i < 9; i++)
		{
			DrawImage("HUDSLOT", (-91 + 20 * i, -23), f, 1, scale: (0.5, 0.5));
			let w = SlotWeapon(i + 1);
			if (!w) continue;
			if (w == CPlayer.ReadyWeapon) sel = i;
			TextureID icon = GetInventoryIcon(w, DI_ALTICONFIRST);
			if (icon.IsValid()) DrawTexture(icon, (-91 + 20 * i + 11, -23 + 11), DI_SCREEN_CENTER_BOTTOM | DI_ITEM_CENTER, 1, (16, 16));
			if (w.Ammo1)
				DrawString(small, String.Format("%d", w.Ammo1.Amount), (-91 + 20 * i + 21, -23 + 13), DI_SCREEN_CENTER_BOTTOM | DI_TEXT_ALIGN_RIGHT, Font.CR_WHITE);
		}
		if (sel >= 0) DrawImage("HUDSEL", (-92 + 20 * sel, -24), f, 1, scale: (0.5, 0.5));
		let quad = Powerup(CPlayer.mo.FindInventory("PowerQuadDamage"));
		if (quad)
		{
			DrawImage("QUADA0", (110, -14), DI_SCREEN_CENTER_BOTTOM | DI_ITEM_CENTER, 1, (16, 16));
			DrawString(small, String.Format("QUAD DAMAGE %ds", quad.EffectTics / 35), (122, -18), DI_SCREEN_CENTER_BOTTOM, Font.CR_LIGHTBLUE);
		}
	}

	void DrawBars()
	{
		int f = DI_SCREEN_CENTER_BOTTOM | DI_ITEM_LEFT_TOP;
		// XP bar and level.
		double frac;
		int lvl = MCXP.LevelOf(CPlayer.mo.CountInv("MCXP"), frac);
		DrawImage("HUDXPBG", (-91, -30), f, 1, scale: (0.5, 0.5));
		if (frac > 0) DrawImage("HUDXPFL", (-91, -30), f, 1, scale: (0.5, 0.5), clipwidth: 182 * frac);
		if (lvl > 0)
		{
			String l = String.Format("%d", lvl);
			for (int dx = -1; dx <= 1; dx++) for (int dy = -1; dy <= 1; dy++)
				if (dx || dy) DrawString(small, l, (dx, -39 + dy), DI_SCREEN_CENTER_BOTTOM | DI_TEXT_ALIGN_CENTER, Font.CR_BLACK);
			DrawString(small, l, (0, -39), DI_SCREEN_CENTER_BOTTOM | DI_TEXT_ALIGN_CENTER, Font.CR_GREEN);
		}
		let q = CatQuest(EventHandler.Find("CatQuest"));
		if (q && level.maptime - q.levelUpAt < 70 && q.levelUpAt > 0)
			DrawString(small, "LEVEL UP!", (0, -50), DI_SCREEN_CENTER_BOTTOM | DI_TEXT_ALIGN_CENTER, Font.CR_GREEN);
		// Hearts: 10 for 100 health, a second row above for overheal; they shake when you are low.
		int hp = CPlayer.health;
		for (int row = 0; row < 2; row++)
		{
			int base = row * 100;
			if (row == 1 && hp <= 100) break;
			for (int i = 0; i < 10; i++)
			{
				double y = -40 - row * 10;
				if (hp <= 25 && (level.maptime / 2 + i) % 3 == 0) y -= 1;
				Vector2 p = (-91 + 8 * i, y);
				DrawImage("HUDHRTE", p, f, 1, scale: (0.5, 0.5));
				int h = hp - base;
				if (h >= 10 * (i + 1)) DrawImage("HUDHRTF", p, f, 1, scale: (0.5, 0.5));
				else if (h >= 10 * i + 5) DrawImage("HUDHRTH", p, f, 1, scale: (0.5, 0.5));
			}
		}
		// Armor: chestplates, only while you wear some.
		let armor = CPlayer.mo.FindInventory("BasicArmor");
		int ap = armor ? armor.Amount : 0;
		if (ap > 0)
		{
			for (int i = 0; i < 10; i++)
			{
				Vector2 p = (10 + 8 * i, -40);
				String t = ap >= 10 * (i + 1) ? "HUDARMF" : (ap >= 10 * i + 5 ? "HUDARMH" : "HUDARME");
				DrawImage(t, p, f, 1, scale: (0.5, 0.5));
			}
		}
	}

	// Minecraft's boss bar, with the Cat's nine lives as hearts.
	void DrawBoss(CatQuest q)
	{
		let c = q.cat;
		if (!c || (c.health <= 0 && q.catLives <= 0) || q.catBeaten) return;
		int f = DI_SCREEN_CENTER_TOP;
		DrawString(small, "The SuperIntelligent Cat", (0, 6), f | DI_TEXT_ALIGN_CENTER, Font.CR_WHITE);
		double hp = c.knocked ? 0 : clamp(c.health / double(c.SpawnHealth()), 0, 1);
		Fill(Color(255, 40, 10, 40), -92, 16, 184, 7, f);
		Fill(Color(255, 90, 20, 90), -91, 17, 182, 5, f);
		if (hp > 0) Fill(Color(255, 236, 64, 220), -91, 17, 182 * hp, 5, f);
		for (int i = 0; i < 9; i++)
			DrawImage(i < q.catLives ? "HUDHRTF" : "HUDHRTE", (-36 + 8 * i, 25), f | DI_ITEM_LEFT_TOP, 1, scale: (0.5, 0.5));
		DrawString(small, String.Format("Lives: %d/9", q.catLives), (0, 36), f | DI_TEXT_ALIGN_CENTER, Font.CR_PURPLE);
	}

	// Chat, bottom left: kill feed and the Cat's taunts, fading out.
	void DrawChat(CatQuest q)
	{
		int n = q.chat.Size();
		int y = -64;
		for (int i = n - 1; i >= 0 && i >= n - 6; i--)
		{
			int age = level.maptime - q.chatAt[i];
			if (age > q.CHAT_TICS) continue;
			double a = age > q.CHAT_TICS - 35 ? (q.CHAT_TICS - age) / 35. : 1.;
			String s = q.chat[i];
			int w = small.mFont.StringWidth(s);
			Fill(Color(int(110 * a), 0, 0, 0), 2, y - 1, w + 6, 10, DI_SCREEN_LEFT_BOTTOM);
			int cr = s.Left(1) == "<" ? Font.CR_PURPLE : Font.CR_WHITE;
			DrawString(small, s, (5, y), DI_SCREEN_LEFT_BOTTOM, cr, a);
			y -= 11;
		}
	}

	// "Advancement Made!" toast, top right, slides in and out.
	void DrawToast(CatQuest q)
	{
		int n = q.toastTitle.Size();
		if (!n) return;
		int age = level.maptime - q.toastAt[n - 1];
		if (age > 35 * 5) return;
		double slide = age < 8 ? (8 - age) / 8. : (age > 35 * 5 - 8 ? (age - (35 * 5 - 8)) / 8. : 0);
		String t = q.toastTitle[n - 1];
		int w = max(150, small.mFont.StringWidth(t) + 34);
		double x = -w - 4 + slide * (w + 8);
		int f = DI_SCREEN_RIGHT_TOP;
		Fill(Color(255, 20, 20, 20), x - 1, 3, w + 2, 30, f);
		Fill(Color(255, 90, 90, 90), x, 4, w, 28, f);
		Fill(Color(255, 33, 33, 33), x + 1, 5, w - 2, 26, f);
		DrawImage("XPORA0", (x + 13, 18), f | DI_ITEM_CENTER, 1, (12, 12));
		DrawString(small, "Advancement Made!", (x + 26, 8), f, Font.CR_YELLOW);
		DrawString(small, t, (x + 26, 19), f, Font.CR_WHITE);
	}

	void DrawQuest(CatQuest q)
	{
		String s;
		if (q.catBeaten) s = "QUEST COMPLETE: the Cat is just a cat again";
		else if (q.catCame) s = String.Format("QUEST: take all 9 lives of the Cat (%d left)", q.catLives);
		else s = String.Format("QUEST: kill mobs to lure out the Cat (%d/%d)", min(q.kills, q.LURE_KILLS), q.LURE_KILLS);
		DrawString(small, s, (-4, 40), DI_SCREEN_RIGHT_TOP | DI_TEXT_ALIGN_RIGHT, Font.CR_GOLD);
	}

	void DrawBig(CatQuest q)
	{
		int age = level.maptime - q.bigMsgAt;
		if (q.bigMsg == "" || age > 35 * 3) return;
		double a = age > 35 * 2 ? (35 * 3 - age) / 35. : 1.;
		DrawString(big, q.bigMsg, (0, -60), DI_SCREEN_CENTER | DI_TEXT_ALIGN_CENTER, Font.CR_GOLD, a, scale: (0.75, 0.75));
	}
}
