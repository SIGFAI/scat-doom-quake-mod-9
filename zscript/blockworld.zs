// The block world: every wall, floor and ceiling of the level becomes a Minecraft-style block (BLOCKMAP.txt maps
// Freedoom's textures; any other texture gets a block picked from its name), the sky becomes a blocky day sky, and
// steps whose top is grass get the grass-side block.
class BlockWorld : EventHandler
{
	Dictionary walls, flats;
	static const String WALL_POOL[] = { "MCCOBBL", "MCSTBRK", "MCSTONE", "MCPLANK", "MCBRICK", "MCMOSSY", "MCORE1", "MCPLANK2" };
	static const String FLAT_POOL[] = { "MCPLANK", "MCSTONE", "MCGRASS", "MCDIRT", "MCCOBBL", "MCGRAVEL" };

	override void WorldLoaded(WorldEvent e)
	{
		if (e.IsSaveGame) return; // the remapped textures are in the save already
		LoadTable();
		Remap();
		TextureID sky = TexMan.CheckForTexture("SKYMC", TexMan.Type_Any);
		if (sky.IsValid()) level.ChangeSky(sky, sky);
	}

	void LoadTable()
	{
		walls = Dictionary.Create();
		flats = Dictionary.Create();
		int lump = Wads.CheckNumForFullName("BLOCKMAP.txt");
		if (lump < 0) return;
		Array<String> lines;
		Wads.ReadLump(lump).Split(lines, "\n");
		bool inFlats = false;
		for (int i = 0; i < lines.Size(); i++)
		{
			String l = lines[i];
			l.Replace("\r", "");
			l.StripRight();
			if (l.Length() == 0) continue;
			if (l.Left(1) == "[") { inFlats = l.MakeUpper() == "[FLATS]"; continue; }
			Array<String> w;
			l.Split(w, " ", TOK_SKIPEMPTY);
			if (w.Size() < 2) continue;
			if (inFlats) flats.Insert(w[0].MakeUpper(), w[1]);
			else walls.Insert(w[0].MakeUpper(), w[1]);
		}
	}

	// A texture's block: the table first, then a block picked from the name, so any map turns into blocks.
	TextureID Block(TextureID t, bool flat)
	{
		String n = TexMan.GetName(t);
		n = n.MakeUpper();
		if (n.Left(2) == "MC" || n.Left(2) == "QK" || n.Left(3) == "SKY" || n == "F_SKY1") return t;
		String b = flat ? flats.At(n) : walls.At(n);
		if (b == "") b = Guess(n, flat);
		TextureID r = TexMan.CheckForTexture(b, TexMan.Type_Any);
		return r.IsValid() ? r : t;
	}

	String Guess(String n, bool flat)
	{
		if (n.IndexOf("NUKAGE") >= 0 || n.IndexOf("SLIME") >= 0) return "MCSLIM1";
		if (n.IndexOf("WATER") >= 0 || n.IndexOf("WFALL") >= 0) return "MCWATR1";
		if (n.IndexOf("LAVA") >= 0 || n.IndexOf("BLOOD") >= 0) return "MCLAVA1";
		if (n.IndexOf("GATE") >= 0) return "QKGATE1";
		if (n.Left(3) == "SW1") return "MCLAMP0";
		if (n.Left(3) == "SW2") return "MCLAMP1";
		if (n.IndexOf("DOOR") >= 0) return "MCDOOR";
		if (n.IndexOf("WOOD") >= 0 || n.IndexOf("CRATE") >= 0) return "MCPLANK";
		if (n.IndexOf("BRICK") >= 0) return "MCBRICK";
		if (n.IndexOf("LITE") >= 0 || n.IndexOf("LIGHT") >= 0) return "MCGLOW";
		if (n.IndexOf("GRASS") >= 0) return "MCGRASS";
		int h = 0;
		for (int i = 0; i < int(n.Length()); i++) h = (h * 31 + n.ByteAt(i)) & 0xFFFF;
		return flat ? FLAT_POOL[h % int(FLAT_POOL.Size())] : WALL_POOL[h % int(WALL_POOL.Size())];
	}

	// Lines that open a door (Doom's door types, translated by GZDoom to the Hexen door specials).
	static bool IsDoor(Line l)
	{
		int s = l.special;
		return (s >= 10 && s <= 14) || s == 202 || s == 249 || s == 105 || s == 106;
	}

	void Remap()
	{
		for (int i = 0; i < level.sectors.Size(); i++)
		{
			Sector s = level.sectors[i];
			for (int p = 0; p < 2; p++)
			{
				TextureID t = s.GetTexture(p);
				if (t.IsValid() && t != skyflatnum) s.SetTexture(p, Block(t, true));
			}
		}
		TextureID grass = TexMan.CheckForTexture("MCGRASS", TexMan.Type_Any);
		TextureID grassSide = TexMan.CheckForTexture("MCGRSSD", TexMan.Type_Any);
		TextureID door = TexMan.CheckForTexture("MCDOOR", TexMan.Type_Any);
		TextureID ironDoor = TexMan.CheckForTexture("MCDOORI", TexMan.Type_Any);
		TextureID iron = TexMan.CheckForTexture("MCIRON", TexMan.Type_Any);
		TextureID planks = TexMan.CheckForTexture("MCPLANK2", TexMan.Type_Any);
		for (int i = 0; i < level.lines.Size(); i++)
		{
			Line l = level.lines[i];
			bool twoSided = l.sidedef[1] != null;
			bool isDoor = IsDoor(l);
			for (int k = 0; k < 2; k++)
			{
				Side sd = l.sidedef[k];
				if (!sd) continue;
				for (int p = 0; p < 3; p++)
				{
					// See-through middles (grates, bars) of two-sided lines stay: a block there would look like a wall.
					if (twoSided && p == Side.mid) continue;
					TextureID t = sd.GetTexture(p);
					if (!t.IsValid() || t.IsNull()) continue;
					TextureID b = Block(t, false);
					// A Minecraft door only on lines that open; a door texture used as decoration becomes a plain block.
					if (isDoor && p == Side.top) b = (b == ironDoor || b == iron) ? ironDoor : door;
					else if (b == door) b = planks;
					else if (b == ironDoor) b = iron;
					sd.SetTexture(p, b);
				}
				// The face of a step under a grass floor shows the grass side, like a Minecraft hill.
				if (twoSided && grassSide.IsValid())
				{
					Sector other = l.sidedef[1 - k].sector;
					if (other && other.GetTexture(Sector.floor) == grass && other.floorplane.ZAtPoint(l.v1.p) > sd.sector.floorplane.ZAtPoint(l.v1.p))
						sd.SetTexture(Side.bottom, grassSide);
				}
			}
		}
	}
}
