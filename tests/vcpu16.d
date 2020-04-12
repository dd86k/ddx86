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
	int modrm = 0b11_001_000; // Mode=Reg, Src: CL, Dst: AL
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

	write("02H  add reg8, rm8\t: ");
	--cpu.EIP; // Mode=Reg, Src: AL, Dst: CL
	cpu.gregs.CL = 27;
	cpu.gregs.AL = 12;
	exec16(&cpu, 0x02);
	assert(cpu.gregs.CL == 39);
	assert((cpu.FLAG & FLAG_CF) == 0);
	--cpu.EIP;
	cpu.gregs.AL = 0xFF;
	cpu.gregs.CL = 0xE0;
	exec16(&cpu, 0x02);
	assert(cpu.FLAG & FLAG_CF);
	writeln("ok");

	write("03H  add reg16, rm16\t: ");
	--cpu.EIP;
	cpu.gregs.CX = 6969;
	cpu.gregs.AX =  101;
	exec16(&cpu, 0x03);
	assert(cpu.gregs.CX == 7070);
	assert((cpu.FLAG & FLAG_CF) == 0);
	--cpu.EIP;
	cpu.gregs.CX = 0xF420;
	cpu.gregs.AX = 0xFFFF;
	exec16(&cpu, 0x03);
	assert(cpu.FLAG & FLAG_CF);
	writeln("ok");

	write("04H  add al, imm8\t: ");
	int imm = 42;
	mmsu8(&cpu, cpu.EIP, &imm);
	cpu.gregs.AL = 12;
	exec16(&cpu, 0x04);
	assert(cpu.gregs.AL == 54);
	assert((cpu.FLAG & FLAG_CF) == 0);
	--cpu.EIP;
	cpu.gregs.AL = 0xFF;
	exec16(&cpu, 0x04);
	assert(cpu.FLAG & FLAG_CF);
	writeln("ok");

	write("05H  add ax, imm16\t: ");
	imm = 1422;
	mmsu16(&cpu, cpu.EIP, &imm);
	cpu.gregs.AX = 1254;
	exec16(&cpu, 0x05);
	assert(cpu.gregs.AX == 2676);
	assert((cpu.FLAG & FLAG_CF) == 0);
	cpu.EIP -= 2;
	cpu.gregs.AX = 0xFF00;
	exec16(&cpu, 0x05);
	assert(cpu.FLAG & FLAG_CF);
	writeln("ok");

	write("06H  push es\t: ");
	cpu.sregs.SS = 0x110;
	cpu.gregs.SP = 0x30;
	cpu.sregs.ES = 0x220;
	exec16(&cpu, 0x06);
	mmgu16(&cpu, cpuaddress(cpu.sregs.SS, cpu.gregs.SP), &imm);
	assert(imm == 0x220);
	writeln("ok");

	write("07H  pop es\t: ");
	cpu.sregs.ES = 0x4440;
	exec16(&cpu, 0x07);
	assert(cpu.sregs.ES == 0x220);
	writeln("ok");
}