module tests.vcpu16;

import std.stdio;
import vcpu;

unittest {
	writeln("** vcpu16");

	cpu_t cpu = void;
	cpu_settings_t settings = void;
	settings.memkb = 640;

	cpuinit(&cpu, &settings);

	cpu.EIP.u32 = 0x100;

	write("00H  add rm8, reg8\t: ");
	int modrm = 0b11_001_000; // Reg, Src: CL, Dst: AL
	mmsu8(&cpu, cpu.EIP, &modrm);
	cpu.gregs.AL = 12;
	cpu.gregs.CL = 13;
	exec16(&cpu, 0x00);
	assert(cpu.gregs.AL == 25);
	assert((cpu.FLAG & FLAG_CF) == 0);
	--cpu.EIP;
	cpu.gregs.AL = 0xFF;
	cpu.gregs.CL = 0xE0;
	exec16(&cpu, 0x00);
	assert(cpu.FLAG & FLAG_CF);
	writeln("ok");

	write("01H  add rm16, reg16\t: ");
	--cpu.EIP;
	cpu.gregs.AX = 1120;
	cpu.gregs.CX = 132;
	exec16(&cpu, 0x01);
	assert(cpu.gregs.AX == 1252);
	assert((cpu.FLAG & FLAG_CF) == 0);
	--cpu.EIP;
	cpu.gregs.AX = 0xFF00;
	cpu.gregs.CX = 0xE022;
	exec16(&cpu, 0x01);
	assert(cpu.FLAG & FLAG_CF);
	writeln("ok");
}