// Quake's monsters as blocky Minecraft mobs. Hits flash them red; they die the Minecraft way (tip over, poof, XP orbs)
// or burst into cubes of meat when a blast overkills them (Quake gibs).
class MCMob : Actor
{
	int xpDrop;
	property XP: xpDrop;

	Default
	{
		Monster;
		+FLOORCLIP
		MCMob.XP 3;
		PainSound "mc/hurt";
	}

	void A_MCDie()
	{
		A_Scream();
		A_NoBlocking();
	}

	void A_MCPoof()
	{
		MCFX.Poof(self);
		MCFX.DropXP(self, xpDrop);
	}

	void A_MCGib()
	{
		A_XScream();
		A_NoBlocking();
		MCFX.Gibs(self, 10);
		MCFX.DropXP(self, xpDrop);
	}
}

// Quake's grunt as a Minecraft zombie with a shotgun.
class ZombieGrunt : MCMob replaces ZombieMan
{
	Default
	{
		Health 30;
		Radius 16;
		Height 56;
		Speed 8;
		Mass 100;
		PainChance 200;
		SeeSound "mob/zombie";
		DeathSound "mob/zombiedie";
		ActiveSound "mob/zombie";
		AttackSound "shotguy/attack";
		DropItem "Clip";
		Obituary "%o was shot by a Zombie Grunt.";
		Tag "Zombie Grunt";
		MCMob.XP 3;
	}
	States
	{
	Spawn:
		GRNZ A 10 A_Look;
		Loop;
	See:
		GRNZ AABBCCDD 3 A_Chase;
		Loop;
	Missile:
		GRNZ E 10 A_FaceTarget;
		GRNZ F 4 Bright A_GruntShot;
		GRNZ E 8;
		Goto See;
	Pain:
		GRNZ G 3;
		GRNZ G 4 A_Pain;
		Goto See;
	Death:
		GRNZ H 4 A_MCDie;
		GRNZ I 4;
		GRNZ J 24;
		TNT1 A 0 A_MCPoof;
		Stop;
	XDeath:
		TNT1 A 0 A_MCGib;
		Stop;
	}
	void A_GruntShot()
	{
		if (!target) return;
		A_StartSound(AttackSound, CHAN_WEAPON);
		A_FaceTarget();
		A_CustomBulletAttack(18, 3, 3, random(2, 4), "MCPuff", 0, CBAF_NORANDOM);
	}
}

// Quake's Enforcer as a blocky robot with a laser blaster.
class EnforcerBot : MCMob replaces ShotgunGuy
{
	Default
	{
		Health 50;
		Radius 16;
		Height 58;
		Speed 8;
		Mass 120;
		PainChance 170;
		SeeSound "mob/robot";
		DeathSound "mob/robotdie";
		ActiveSound "mob/robot";
		DropItem "Clip";
		Obituary "%o was zapped by an Enforcer Bot.";
		Tag "Enforcer Bot";
		MCMob.XP 4;
	}
	States
	{
	Spawn:
		ENFR A 10 A_Look;
		Loop;
	See:
		ENFR AABBCCDD 3 A_Chase;
		Loop;
	Missile:
		ENFR E 10 A_FaceTarget;
		ENFR F 4 Bright A_Bolt;
		ENFR E 6 A_FaceTarget;
		ENFR F 4 Bright A_Bolt;
		ENFR E 6;
		Goto See;
	Pain:
		ENFR G 3;
		ENFR G 4 A_Pain;
		Goto See;
	Death:
		ENFR H 4 A_MCDie;
		ENFR I 4;
		ENFR J 24;
		TNT1 A 0 A_MCPoof;
		Stop;
	XDeath:
		TNT1 A 0 A_MCGib;
		Stop;
	}
	void A_Bolt()
	{
		A_StartSound("mc/laser", CHAN_WEAPON, CHANF_OVERLAP, 0.7, pitch: 1.3);
		A_SpawnProjectile("EnforcerBolt", 34, 6);
	}
}

class EnforcerBolt : Actor
{
	Default
	{
		Projectile;
		Radius 5; Height 8; Speed 20; FastSpeed 28;
		Damage 3;
		+BRIGHT +FORCEXYBILLBOARD
		DeathSound "mc/nailhit";
		Scale 1.3;
	}
	States
	{
	Spawn:
		BOLT AB 2 A_BoltTrail;
		Loop;
	Death:
		TNT1 A 1 A_BoltHit;
		Stop;
	}
	void A_BoltTrail()
	{
		A_AttachLight('bolt', DynamicLight.PointLight, "ffb030", 40, 40);
		MCFX.Squares(pos, "ffc040", 1, 0.3, 3, 8, 0, 0, true, 0);
	}
	void A_BoltHit()
	{
		A_StartSound(DeathSound, CHAN_AUTO);
		MCFX.Squares(pos, "ffd060", 8, 3, 3, 12, 0.5, -0.2, true, 0);
	}
}

// Quake's Ogre, Minecraft-sized: a chainsaw up close, TNT lobbed from afar.
class ChainsawOgre : MCMob replaces Demon
{
	Default
	{
		Health 200;
		Radius 26;
		Height 70;
		Speed 9;
		Mass 500;
		PainChance 120;
		MeleeRange 70;
		MinMissileChance 160;
		SeeSound "mob/ogre";
		DeathSound "mob/ogredie";
		ActiveSound "mob/ogre";
		Obituary "%o was sawed in half by a Chainsaw Ogre.";
		HitObituary "%o was sawed in half by a Chainsaw Ogre.";
		Tag "Chainsaw Ogre";
		MCMob.XP 8;
	}
	States
	{
	Spawn:
		OGRE A 10 A_Look;
		Loop;
	See:
		OGRE AABBCCDD 3 A_Chase;
		Loop;
	Melee:
		OGRE E 6 A_SawRev;
		OGRE F 4 A_Saw;
		OGRE E 3;
		OGRE F 4 A_Saw;
		OGRE E 5;
		Goto See;
	Missile:
		OGRE A 0 A_JumpIfCloser(256, "See");
		OGRE G 12 A_FaceTarget;
		OGRE G 6 A_OgreLob;
		OGRE A 8;
		Goto See;
	Pain:
		OGRE H 3;
		OGRE H 5 A_Pain;
		Goto See;
	Death:
		OGRE I 5 A_MCDie;
		OGRE J 5;
		OGRE K 26;
		TNT1 A 0 A_MCPoof;
		Stop;
	XDeath:
		TNT1 A 0 A_MCGib;
		Stop;
	}
	void A_SawRev()
	{
		A_FaceTarget();
		A_StartSound("mob/chainsaw", CHAN_WEAPON);
	}
	void A_Saw()
	{
		A_FaceTarget();
		if (target && CheckMeleeRange())
		{
			Vector3 at = target.pos + (0, 0, target.height * 0.6);
			MCFX.Squares(at, "ffe070", 6, 4, 2, 8, 0.5, -0.2, true, 4);
		}
		A_CustomMeleeAttack(random(3, 8) * 3, "mob/chainsaw", "mc/swing");
	}
	void A_OgreLob()
	{
		if (!target) return;
		A_StartSound("mc/swing", CHAN_WEAPON);
		SuperIntelligentCat.Lob(self, "OgreTNT", target, 56);
	}
}

class OgreTNT : CatTNT
{
	Default { Obituary "%o caught a Chainsaw Ogre's TNT."; }
}

// Minecraft's creeper with Quake's Fiend in it: it leaps at you from afar, and up close it hisses, swells, and blows.
class CreeperFiend : MCMob replaces DoomImp
{
	bool leapHit;
	int leapAt;

	Default
	{
		Health 60;
		Radius 16;
		Height 52;
		Speed 9;
		Mass 100;
		PainChance 160;
		MeleeRange 72;
		MinMissileChance 180;
		SeeSound "mob/fiend";
		DeathSound "mob/fienddie";
		ActiveSound "mob/fiend";
		Obituary "%o was blown up by a Creeper Fiend.";
		HitObituary "%o was mauled by a leaping Creeper Fiend.";
		Tag "Creeper Fiend";
		MCMob.XP 5;
	}
	States
	{
	Spawn:
		CRPF A 10 A_Look;
		Loop;
	See:
		CRPF AABBCCDD 3 A_Chase;
		Loop;
	Missile:
		CRPF A 0 A_JumpIfCloser(160, "See");
		CRPF E 8 A_FaceTarget;
		CRPF F 2 A_Leap;
	Leaping:
		CRPF F 1 A_LeapTick;
		Loop;
	Melee:
		CRPF G 0 A_StartSound("mob/crphiss", CHAN_VOICE);
		CRPF G 5 A_FaceTarget;
		CRPF A 4;
		CRPF G 5 A_FaceTarget;
		CRPF A 3;
		CRPF G 4 A_FaceTarget;
		CRPF A 2;
		CRPF G 3;
		CRPF A 2;
		CRPF G 2;
		CRPF G 2 Bright;
		CRPF G 2 Bright;
		TNT1 A 0 A_CreeperBoom;
		Stop;
	Pain:
		CRPF H 3;
		CRPF H 4 A_Pain;
		Goto See;
	Death:
		CRPF I 4 A_MCDie;
		CRPF J 4;
		CRPF K 24;
		TNT1 A 0 A_MCPoof;
		Stop;
	XDeath:
		TNT1 A 0 A_MCGib;
		Stop;
	}

	// Quake's Fiend jump: up and at the target; a hit on the way claws it.
	void A_Leap()
	{
		if (!target) return;
		A_FaceTarget();
		A_StartSound(SeeSound, CHAN_VOICE);
		double d = Distance2D(target);
		VelFromAngle(clamp(d / 14., 10, 20));
		vel.z = 7;
		leapHit = false;
		leapAt = level.maptime;
	}

	void A_LeapTick()
	{
		if (target && !leapHit && Distance3D(target) < radius + target.radius + 14)
		{
			leapHit = true;
			target.DamageMobj(self, self, random(10, 20), 'Melee');
			target.Thrust(6, angle);
			A_StartSound("mc/hurt", CHAN_WEAPON);
		}
		if (level.maptime - leapAt > 4 && (pos.z <= floorz || vel.Length() < 1)) SetStateLabel("See");
		else if (level.maptime - leapAt > 70) SetStateLabel("See");
	}

	// Creepers blow up: a TNT blast that hurts everyone near, other mobs included.
	void A_CreeperBoom()
	{
		MCFX.Boom(self, 1.1);
		A_Explode(72, 150, XF_HURTSOURCE);
		let q = CatQuest(EventHandler.Find("CatQuest"));
		if (q) q.Blast(self);
		bShootable = true;
		DamageMobj(self, self, health + 500, 'Explosion', DMG_FORCED | DMG_THRUSTLESS);
	}
}

// The Cat's minions: tiny cube kittens with jetpacks that dive-bite you.
class JetpackKitten : MCMob replaces LostSoul
{
	Default
	{
		Health 40;
		Radius 12;
		Height 28;
		Speed 11;
		Mass 50;
		Damage 3;
		PainChance 220;
		+FLOAT +NOGRAVITY +DONTFALL +NOICEDEATH
		-FLOORCLIP
		SeeSound "kitten/meow";
		AttackSound "kitten/meow";
		DeathSound "kitten/die";
		ActiveSound "kitten/meow";
		Obituary "%o was bitten by a Jetpack Kitten.";
		Tag "Jetpack Kitten";
		MCMob.XP 2;
	}
	States
	{
	Spawn:
		KITN AB 5 A_Look;
		Loop;
	See:
		KITN AABB 2 A_KittenChase;
		Loop;
	Missile:
		KITN C 10 A_FaceTarget;
		KITN C 4 A_SkullAttack(16);
		KITN C 4;
		Goto Missile + 2;
	Pain:
		KITN D 3;
		KITN D 4 A_Pain;
		Goto See;
	Death:
		KITN E 4 A_MCDie;
		KITN F 20;
		TNT1 A 0 A_MCPoof;
		Stop;
	XDeath:
		TNT1 A 0 A_MCGib;
		Stop;
	}
	void A_KittenChase()
	{
		A_Chase();
		if (level.maptime % 2 == 0) MCFX.Squares(pos + (0, 0, 4), "ffa020", 1, 1, 3, 8, -2, 0, true, 4);
	}
}
