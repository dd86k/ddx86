module tests.mm;

import std.stdio;
import vcpu;

unittest {
	writeln("** mm");

	cpu_t cpu = void;

	write("Registers\t: ");
	cpu.regs[Reg.C].u32 = 0x44332211;
	assert(cpu.gregs.ECX == 0x44332211);
	assert(cpu.gregs.CX == 0x2211);
	assert(cpu.gregs.CH == 0x22);
	assert(cpu.gregs.CL == 0x11);
	cpu.segs[SegReg.SS] = 0x2211;
	assert(cpu.sregs.SS == 0x2211);
	writeln("ok");

	cpu_settings_t settings = void;
	settings.memkb = 640;
	assert(cpuinit(&cpu, &settings) == 0);
}
