// TNT blocks (Doom's exploding barrels), the Quad Damage cube, and Minecraft food and armor for Doom's pickups.

// Shot or caught in a blast, a TNT block is primed like in Minecraft: it hisses, flashes white, swells, then blows,
// so barrels set each other off in a rolling chain.
class TNTBlock : ExplosiveBarrel replaces ExplosiveBarrel
{
	Default
	{
		Radius 16;
		Height 32;
		Health 20;
		DeathSound "mc/tntfuse";
		Obituary "%o was blown up by TNT.";
		Tag "TNT";
	}
	States
	{
	Spawn:
		TNTB A -1;
		Stop;
	Death:
		TNTB B 4 A_Prime;
		TNTB A 4;
		TNTB B 4;
		TNTB A 4;
		TNTB B 3;
		TNTB A 3;
		TNTB C 3 Bright;
		TNTB B 3 Bright;
		TNTB C 3 Bright;
		TNT1 A 0 A_TNTBlast;
		TNT1 A 1050 A_BarrelDestroy;
		TNT1 A 5 A_Respawn;
		Wait;
	}
	void A_Prime()
	{
		A_Scream();
		vel.z = 3; // the little hop of primed TNT
		MCFX.Squares(pos + (0, 0, height), "ffe0a0", 6, 1, 3, 20, 0.5, 0, true, 4);
	}
	void A_TNTBlast()
	{
		MCFX.Boom(self, 1.2);
		A_Explode(128, 160);
		let q = CatQuest(EventHandler.Find("CatQuest"));
		if (q) q.Blast(self);
	}
}

// Quake's Quad Damage as a glowing blue block: four times the damage for 30 seconds.
class QuadCube : PowerupGiver replaces Berserk
{
	Default
	{
		Inventory.PickupMessage "QUAD DAMAGE! Four times the cubes.";
		Inventory.PickupSound "mc/quad";
		Powerup.Type "PowerQuadDamage";
		Inventory.MaxAmount 0;
		+INVENTORY.AUTOACTIVATE
		+INVENTORY.ALWAYSPICKUP
		+INVENTORY.BIGPOWERUP
		+FLOATBOB
		Scale 1.3;
		Tag "Quad Damage";
	}
	States
	{
	Spawn:
		QUAD ABCD 5 Bright A_QuadGlow;
		Loop;
	}
	void A_QuadGlow()
	{
		A_AttachLight('quad', DynamicLight.PointLight, "4070ff", 72, 72);
		MCFX.Squares(pos + (0, 0, 16), "6090ff", 1, 0.5, 3, 30, 0.4, 0, true, 10);
	}
}

class QuadCube2 : QuadCube replaces BlurSphere {}

class PowerQuadDamage : PowerDamage
{
	Default
	{
		DamageFactor "Normal", 4;
		Powerup.Duration -30;
		Powerup.Color "3060FF", 0.08;
		SeeSound "mc/quad";
	}
	override void InitEffect()
	{
		super.InitEffect();
		let q = CatQuest(EventHandler.Find("CatQuest"));
		if (q) q.Earn("Quad Erat Demonstrandum: x4 Damage");
	}

	override void DoEffect()
	{
		super.DoEffect();
		if (Owner && level.maptime % 4 == 0)
			MCFX.Squares(Owner.pos + (0, 0, Owner.height * 0.5), "4070ff", 1, 0.6, 3, 20, 0.6, 0, true, 14);
	}
}

// Minecraft food and armor for Doom's health and armor pickups.
class MCApple : Stimpack replaces Stimpack
{
	Default { Scale 0.6; Inventory.PickupMessage "Ate an apple. (+10 health)"; Inventory.PickupSound "mc/pickup"; }
	States { Spawn: APPL A -1; Stop; }
}

class MCBread : Medikit replaces Medikit
{
	Default
	{
		Scale 0.8;
		Inventory.PickupMessage "Ate a loaf of bread. (+25 health)";
		Health.LowMessage 25, "Ate a loaf of bread you REALLY needed!";
		Inventory.PickupSound "mc/pickup";
	}
	States { Spawn: BRED A -1; Stop; }
}

class MCPotion : HealthBonus replaces HealthBonus
{
	Default { Scale 0.6; Inventory.PickupMessage "Drank a healing potion. (+1)"; Inventory.PickupSound "mc/pickup"; }
	States { Spawn: BOTL A -1; Stop; }
}

class MCCake : Soulsphere replaces Soulsphere
{
	Default { Inventory.PickupMessage "Ate a whole cake! (+100 health)"; Inventory.PickupSound "mc/levelup"; }
	States { Spawn: CAKE A -1; Stop; }
}

class MCIronChestplate : GreenArmor replaces GreenArmor
{
	Default { Inventory.PickupMessage "Equipped an iron chestplate."; Inventory.PickupSound "mc/pickup"; }
	States { Spawn: CHST A -1; Stop; }
}

class MCDiamondChestplate : BlueArmor replaces BlueArmor
{
	Default { Inventory.PickupMessage "Equipped a DIAMOND chestplate!"; Inventory.PickupSound "mc/levelup"; }
	States { Spawn: CHST B -1; Stop; }
}

class MCNails : Clip replaces Clip
{
	Default { Inventory.PickupMessage "Picked up a bundle of nails."; Inventory.PickupSound "mc/pickup"; }
	States { Spawn: ARRW A -1; Stop; }
}

class MCNailChest : ClipBox replaces ClipBox
{
	Default { Inventory.PickupMessage "Opened a chest of nails."; Inventory.PickupSound "mc/pickup"; }
	States { Spawn: SHBX A -1; Stop; }
}

class MCShellChest : ShellBox replaces ShellBox
{
	Default { Inventory.PickupMessage "Opened a chest of shells."; Inventory.PickupSound "mc/pickup"; }
	States { Spawn: SHBX A -1; Stop; }
}
