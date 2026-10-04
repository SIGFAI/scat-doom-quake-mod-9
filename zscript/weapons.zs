// Quake's arsenal, built from blocks: a diamond pickaxe (Quake's axe), the nailgun and super nailgun, and a grenade
// launcher that lobs bouncing TNT blocks.

class Pickaxe : Fist replaces Fist
{
	Default
	{
		Weapon.SlotNumber 1;
		Weapon.Kickback 120;
		Inventory.Icon "ICONAX";
		Tag "Diamond Pickaxe";
		Obituary "%o was mined by %k's pickaxe.";
		+WEAPON.MELEEWEAPON
	}
	States
	{
	Ready:
		PAXE A 1 A_WeaponReady;
		Loop;
	Deselect:
		PAXE A 1 A_Lower;
		Loop;
	Select:
		PAXE A 1 A_Raise;
		Loop;
	Fire:
		PAXE B 4;
		PAXE C 3 A_PickSwing;
		PAXE D 5;
		PAXE A 4;
		PAXE A 2 A_ReFire;
		Goto Ready;
	}
	action void A_PickSwing()
	{
		A_StartSound("mc/swing", CHAN_WEAPON);
		A_CustomPunch(random(14, 26), true, 0, "PickPuff", 80);
	}
}

// What the pickaxe hits: a chunk of block flies off the wall, a thud on a creature.
class PickPuff : BulletPuff
{
	Default { +PUFFONACTORS AttackSound "mc/dig"; SeeSound "mc/hurt"; }
	States
	{
	Spawn:
		TNT1 A 1 NoDelay A_Mine;
		Stop;
	}
	void A_Mine()
	{
		MCFX.Squares(pos, "8a7a6a", 9, 3, 4, 26, 1.5);
		if (!tracer) MCFX.Debris(pos, 2, 3);
	}
}

class Nailgun : Pistol replaces Pistol
{
	Default
	{
		Weapon.SlotNumber 2;
		Weapon.AmmoType "Clip";
		Weapon.AmmoUse 1;
		Weapon.AmmoGive 30;
		Inventory.Icon "ICONNG";
		Inventory.PickupMessage "You got the Nailgun!";
		Tag "Nailgun";
	}
	States
	{
	Spawn:
		NAGP A -1;
		Stop;
	Ready:
		NAGN A 1 A_WeaponReady;
		Loop;
	Deselect:
		NAGN A 1 A_Lower;
		Loop;
	Select:
		NAGN A 1 A_Raise;
		Loop;
	Fire:
		NAGN A 3 A_FireNail(-3);
		NAGN B 3 A_FireNail(3);
		NAGN A 0 A_ReFire;
		NAGN B 4;
		Goto Ready;
	Flash:
		NAGF A 2 Bright A_Light1;
		Goto LightDone;
	}
	action void A_FireNail(double side, int n = 1)
	{
		A_GunFlash();
		A_StartSound("mc/nailgun", CHAN_WEAPON, CHANF_OVERLAP, 0.9, pitch: frandom(0.95, 1.05));
		for (int i = 0; i < n; i++)
			A_FireProjectile("NailShot", frandom(-1.2, 1.2) + (n > 1 ? (i ? 2 : -2) : 0), i == 0, side, 0, 0, frandom(-0.6, 0.6));
		A_WeaponOffset(frandom(-1.5, 1.5), 32 + frandom(1, 3));
	}
}

class SuperNailgun : Nailgun replaces Chaingun
{
	Default
	{
		Weapon.SlotNumber 4;
		Weapon.AmmoGive 40;
		Inventory.PickupMessage "You got the Super Nailgun!";
		Tag "Super Nailgun";
	}
	States
	{
	Fire:
		NAGN A 2 A_FireNail(-4, 2);
		NAGN B 2 A_FireNail(4, 2);
		NAGN A 0 A_ReFire;
		NAGN B 4;
		Goto Ready;
	}
}

// A nail: fast, a grey streak, sparks on walls, a metallic tink.
class NailShot : Actor
{
	Default
	{
		Projectile;
		Radius 3; Height 4; Speed 48;
		DamageFunction (random(5, 10));
		+BLOODSPLATTER +BRIGHT +FORCEXYBILLBOARD
		Scale 2.4;
		DeathSound "mc/nailhit";
		Obituary "%o was nailed by %k.";
		Decal "BulletChip";
	}
	States
	{
	Spawn:
		NAIL AB 1 A_NailTrail;
		Loop;
	Death:
		TNT1 A 1 A_NailSpark;
		Stop;
	XDeath:
		TNT1 A 1;
		Stop;
	}
	void A_NailTrail()
	{
		bool quad = target && target.FindInventory("PowerQuadDamage");
		MCFX.Squares(pos, quad ? Color(255, 80, 120, 255) : Color(255, 200, 200, 210), 2, 0.2, 3, 9, 0, 0, quad, 0);
	}
	void A_NailSpark()
	{
		A_StartSound(DeathSound, CHAN_AUTO, CHANF_OVERLAP, 0.6, pitch: frandom(0.9, 1.2));
		MCFX.Squares(pos, "ffe070", 4, 3.5, 2, 9, 0.5, -0.2, true, 0);
		MCFX.Squares(pos, "7a7a7a", 3, 2, 3, 20, 1, -0.3, false, 0);
	}
}

class TNTLauncher : RocketLauncher replaces RocketLauncher
{
	Default
	{
		Weapon.SlotNumber 5;
		Weapon.AmmoType "RocketAmmo";
		Weapon.AmmoUse 1;
		Weapon.AmmoGive 8;
		Inventory.Icon "ICONTL";
		Inventory.PickupMessage "You got the TNT Launcher!";
		Tag "TNT Launcher";
		-WEAPON.NOAUTOFIRE
	}
	States
	{
	Spawn:
		TNLP A -1;
		Stop;
	Ready:
		TNLG A 1 A_WeaponReady;
		Loop;
	Deselect:
		TNLG A 1 A_Lower;
		Loop;
	Select:
		TNLG A 1 A_Raise;
		Loop;
	Fire:
		TNLG B 3 A_FireTNT;
		TNLG B 5;
		TNLG A 10;
		TNLG A 0 A_ReFire;
		Goto Ready;
	Flash:
		TNLF A 3 Bright A_Light2;
		TNLF A 2 Bright A_Light1;
		Goto LightDone;
	}
	action void A_FireTNT()
	{
		A_GunFlash();
		A_StartSound("mc/tntfuse", CHAN_WEAPON, CHANF_OVERLAP, 0.7);
		A_StartSound("weapons/rocklf", CHAN_AUTO, CHANF_OVERLAP, 0.6);
		A_FireProjectile("TNTGrenade", 0, true, 6, -4, 0, -7);
	}
}

// Quake's grenade as a TNT block: bounces off walls and floors, blows on the first creature it touches,
// or after two and a half seconds.
class TNTGrenade : Actor
{
	Default
	{
		Projectile;
		-NOGRAVITY
		Radius 8; Height 12; Speed 26; Gravity 0.55; Damage 0;
		BounceType "Doom"; BounceFactor 0.45; WallBounceFactor 0.6; BounceCount 8;
		+ROLLSPRITE +ROLLCENTER -BOUNCEAUTOOFF +CANBOUNCEWATER
		Scale 0.45;
		BounceSound "mc/dig";
		Obituary "%o was blown up by %k's TNT.";
	}
	States
	{
	Spawn:
		TNTB A 3 A_Fly;
		TNTB B 3 A_Fly;
		Loop;
	Death:
		TNT1 A 0 A_Blast;
		TNT1 A 10;
		Stop;
	}
	void A_Fly()
	{
		roll += 30;
		MCFX.Squares(pos + (0, 0, 8), "ffd060", 1, 1, 2, 8, 0.5, 0, true, 2);
		MCFX.Squares(pos + (0, 0, 6), "8a8a8a", 1, 0.3, 4, 18, 0.4, 0, false, 2);
		if (GetAge() > 88) SetStateLabel("Death");
	}
	void A_Blast()
	{
		bNoGravity = true;
		vel = (0, 0, 0);
		roll = 0;
		MCFX.Boom(self, 1.0);
		A_Explode(128, 170);
		let q = CatQuest(EventHandler.Find("CatQuest"));
		if (q) q.Blast(self);
	}
	override int SpecialMissileHit(Actor victim)
	{
		if (victim == target || !victim.bShootable) return 1;
		SetStateLabel("Death");
		return 1;
	}
}

// Doom's shotgun pickups (and the shotguns monsters drop) give a Super Nailgun in slot 3: the arsenal stays blocky.
class NailShotgun : SuperNailgun replaces Shotgun
{
	Default
	{
		Weapon.SlotNumber 3;
		Weapon.AmmoType "Clip";
		Weapon.AmmoGive 30;
		Inventory.PickupMessage "You got a Super Nailgun!";
	}
}
