// Doom's level props as Minecraft blocks: trees, torches on fence posts, glowstone lamp posts, obsidian pillars.
class MCOakTree : BigTree replaces BigTree
{
	Default { Radius 24; Height 150; Scale 0.75; }
	States { Spawn: MCTR A -1; Stop; }
}

class MCBirchTree : TorchTree replaces TorchTree
{
	Default { Radius 16; Height 110; Scale 0.8; }
	States { Spawn: MCTR B -1; Stop; }
}

class MCTorch : ShortRedTorch replaces ShortRedTorch
{
	Default { Radius 8; Height 48; Scale 0.9; }
	States { Spawn: MCTO ABC 5; Loop; }
	override void PostBeginPlay()
	{
		super.PostBeginPlay();
		A_AttachLight('torch', DynamicLight.FlickerLight, "ffb050", 96, 112, 0, (0, 0, 60), 0.4);
	}
}
class MCTorch2 : MCTorch replaces ShortGreenTorch {}
class MCTorch3 : MCTorch replaces ShortBlueTorch {}
class MCTorch4 : MCTorch replaces RedTorch {}
class MCTorch5 : MCTorch replaces GreenTorch {}
class MCTorch6 : MCTorch replaces BlueTorch {}

class MCLampPost : Column replaces Column
{
	Default { Radius 16; Height 96; }
	States { Spawn: MCLP A -1 Bright; Stop; }
	override void PostBeginPlay()
	{
		super.PostBeginPlay();
		A_AttachLight('lamp', DynamicLight.PointLight, "fff0a0", 160, 160, 0, (0, 0, 84));
	}
}
class MCLampPost2 : MCLampPost replaces TechLamp {}
class MCLampPost3 : MCLampPost replaces TechLamp2 {}

class MCObsidianPillar : TechPillar replaces TechPillar
{
	Default { Radius 16; Height 96; }
	States { Spawn: MCPL A -1; Stop; }
	override void PostBeginPlay()
	{
		super.PostBeginPlay();
		A_AttachLight('rune', DynamicLight.PulseLight, "a040ff", 48, 80, 0, (0, 0, 60), 1.5);
	}
}

class MCHangingStones : Stalagtite replaces Stalagtite
{
	Default { Radius 16; Height 64; }
	States { Spawn: MCST A -1; Stop; }
}
