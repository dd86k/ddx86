module vcpu.exec;

import vcpu.core;
import vcpu.mm;
import vcpu.interrupt;

extern (C):

void exec16(cpu_t *cpu, ubyte op) {
	cpu.opmap1[op](cpu);
}

void exec00h(cpu_t *cpu) { // add rm8, reg8
	int modrm = void;
	if (mmgu8_i(cpu, &modrm)) return;
	if (modrm16rm(cpu, modrm, MODRM_SET_DST | MODRM_WIDTH_8B)) return;
	modrm8reg(cpu, modrm, MODRM_WIDTH_8B);
	int a = *cpu.dst_u8 + *cpu.src_u8;
	cpuflag(cpu, a, CPUFLAG_WIDTH_8B | CPUFLAG_GRP1);
	*cpu.dst_u8 = cast(ubyte)a;
}

void exec01h(cpu_t *cpu) { // add rm16, reg16
	int modrm = void;
	if (mmgu8_i(cpu, &modrm)) return;
	if (modrm16rm(cpu, modrm, MODRM_SET_DST | MODRM_WIDTH_16B)) return;
	modrm16reg(cpu, modrm, 0);
	int a = *cpu.dst_u16 + *cpu.src_u16;
	cpuflag(cpu, a, CPUFLAG_WIDTH_16B | CPUFLAG_GRP1);
	*cpu.dst_u16 = cast(ushort)a;
}

void exec02h(cpu_t *cpu) { // add reg8, rm8
	int modrm = void;
	if (mmgu8_i(cpu, &modrm)) return;
	if (modrm16rm(cpu, modrm, MODRM_WIDTH_8B)) return;
	modrm8reg(cpu, modrm, MODRM_SET_DST);
	int a = *cpu.dst_u8 + *cpu.src_u8;
	cpuflag(cpu, a, CPUFLAG_WIDTH_8B | CPUFLAG_GRP1);
	*cpu.dst_u8 = cast(ubyte)a;
}

void exec03h(cpu_t *cpu) { // add reg16, rm16
	int modrm = void;
	if (mmgu8_i(cpu, &modrm)) return;
	if (modrm16rm(cpu, modrm, MODRM_WIDTH_16B)) return;
	modrm16reg(cpu, modrm, MODRM_SET_DST);
	int a = *cpu.dst_u16 + *cpu.src_u16;
	cpuflag(cpu, a, CPUFLAG_WIDTH_16B | CPUFLAG_GRP1);
	*cpu.dst_u16 = cast(ushort)a;
}

void exec04h(cpu_t *cpu) { // add al, imm8
	int imm = void;
	if (mmgu8_i(cpu, &imm)) return;
	int a = cpu.gregs.AL + imm;
	cpuflag(cpu, a, CPUFLAG_WIDTH_8B | CPUFLAG_GRP1);
	cpu.gregs.AL = cast(ubyte)a;
}

void exec05h(cpu_t *cpu) { // add ax, imm16
	int imm = void;
	if (mmgu16_i(cpu, &imm)) return;
	int a = cpu.gregs.AX + imm;
	cpuflag(cpu, a, CPUFLAG_WIDTH_16B | CPUFLAG_GRP1);
	cpu.gregs.AX = cast(ushort)a;
}

void exec06h(cpu_t *cpu) { // push es
	cpupush16(cpu, cpu.sregs.ES);
}

void exec07h(cpu_t *cpu) { // pop es
	cpu.sregs.ES = cpupop16(cpu);
}

void execill(cpu_t *cpu) {
	interrupt(cpu, Vector.UD);
}