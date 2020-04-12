module vcpu.exec;

import vcpu.core;
import vcpu.mm;
import vcpu.interrupt;

extern (C):

/**
 * Execute an instruction.
 * Params:
 * 	cpu = cpu_t structure
 * 	op = Operation code
 */
void exec16(cpu_t *cpu, ubyte op) {
	cpu.opmap1[op](cpu);
}

/// #UD placeholder
/// Params: cpu = cpu_t structure
void execill(cpu_t *cpu) {
	interrupt(cpu, Vector.UD);
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

void exec08h(cpu_t *cpu) { // or rm8, reg8
	int modrm = void;
	if (mmgu8_i(cpu, &modrm)) return;
	if (modrm16rm(cpu, modrm, MODRM_SET_DST | MODRM_WIDTH_8B)) return;
	modrm8reg(cpu, modrm, MODRM_WIDTH_8B);
	int a = *cpu.dst_u8 | *cpu.src_u8;
	cpuflag(cpu, a, CPUFLAG_WIDTH_8B | CPUFLAG_GRP2);
	cpu.FLAG &= ~(FLAG_OF | FLAG_CF);
	*cpu.dst_u8 = cast(ubyte)a;
}

void exec09h(cpu_t *cpu) { // or rm16, reg16
	int modrm = void;
	if (mmgu8_i(cpu, &modrm)) return;
	if (modrm16rm(cpu, modrm, MODRM_SET_DST | MODRM_WIDTH_16B)) return;
	modrm16reg(cpu, modrm, 0);
	int a = *cpu.dst_u16 | *cpu.src_u16;
	cpuflag(cpu, a, CPUFLAG_WIDTH_16B | CPUFLAG_GRP2);
	cpu.FLAG &= ~(FLAG_OF | FLAG_CF);
	*cpu.dst_u16 = cast(ushort)a;
}

void exec0Ah(cpu_t *cpu) { // or reg8, rm8
	int modrm = void;
	if (mmgu8_i(cpu, &modrm)) return;
	if (modrm16rm(cpu, modrm, MODRM_WIDTH_8B)) return;
	modrm8reg(cpu, modrm, MODRM_SET_DST);
	int a = *cpu.dst_u8 | *cpu.src_u8;
	cpuflag(cpu, a, CPUFLAG_WIDTH_8B | CPUFLAG_GRP2);
	cpu.FLAG &= ~(FLAG_OF | FLAG_CF);
	*cpu.dst_u8 = cast(ubyte)a;
}

void exec0Bh(cpu_t *cpu) { // or reg16, rm16
	int modrm = void;
	if (mmgu8_i(cpu, &modrm)) return;
	if (modrm16rm(cpu, modrm, MODRM_WIDTH_16B)) return;
	modrm16reg(cpu, modrm, MODRM_SET_DST);
	int a = *cpu.dst_u16 | *cpu.src_u16;
	cpuflag(cpu, a, CPUFLAG_WIDTH_16B | CPUFLAG_GRP2);
	cpu.FLAG &= ~(FLAG_OF | FLAG_CF);
	*cpu.dst_u16 = cast(ushort)a;
}

void exec0Ch(cpu_t *cpu) { // or al, imm8
	int imm = void;
	if (mmgu8_i(cpu, &imm)) return;
	int a = cpu.gregs.AL | imm;
	cpuflag(cpu, a, CPUFLAG_WIDTH_8B | CPUFLAG_GRP2);
	cpu.FLAG &= ~(FLAG_OF | FLAG_CF);
	cpu.gregs.AL = cast(ubyte)a;
}

void exec0Dh(cpu_t *cpu) { // or ax, imm16
	int imm = void;
	if (mmgu16_i(cpu, &imm)) return;
	int a = cpu.gregs.AX | imm;
	cpuflag(cpu, a, CPUFLAG_WIDTH_16B | CPUFLAG_GRP2);
	cpu.FLAG &= ~(FLAG_OF | FLAG_CF);
	cpu.gregs.AX = cast(ushort)a;
}

void exec0Eh(cpu_t *cpu) { // push cs
	cpupush16(cpu, cpu.sregs.CS);
}

void exec0Fh(cpu_t *cpu) { // 0f escape
	int imm = void;
	if (mmgu16_i(cpu, &imm)) return;
	cpu.opmap2[cast(ubyte)imm](cpu);
}

void exec10h(cpu_t *cpu) { // adc rm8, reg8
	int modrm = void;
	if (mmgu8_i(cpu, &modrm)) return;
	if (modrm16rm(cpu, modrm, MODRM_SET_DST | MODRM_WIDTH_8B)) return;
	modrm8reg(cpu, modrm, MODRM_WIDTH_8B);
	int a = *cpu.dst_u8 + *cpu.src_u8;
	if (cpu.FLAG & FLAG_CF) ++a;
	cpuflag(cpu, a, CPUFLAG_WIDTH_8B | CPUFLAG_GRP1);
	*cpu.dst_u8 = cast(ubyte)a;
}

void exec11h(cpu_t *cpu) { // adc rm8, reg8
	int modrm = void;
	if (mmgu8_i(cpu, &modrm)) return;
	if (modrm16rm(cpu, modrm, MODRM_SET_DST | MODRM_WIDTH_16B)) return;
	modrm16reg(cpu, modrm, 0);
	int a = *cpu.dst_u16 + *cpu.src_u16;
	if (cpu.FLAG & FLAG_CF) ++a;
	cpuflag(cpu, a, CPUFLAG_WIDTH_16B | CPUFLAG_GRP1);
	*cpu.dst_u16 = cast(ushort)a;
}

void exec12h(cpu_t *cpu) { // adc reg8, rm8
	int modrm = void;
	if (mmgu8_i(cpu, &modrm)) return;
	if (modrm16rm(cpu, modrm, MODRM_WIDTH_8B)) return;
	modrm8reg(cpu, modrm, MODRM_SET_DST);
	int a = *cpu.dst_u8 + *cpu.src_u8;
	if (cpu.FLAG & FLAG_CF) ++a;
	cpuflag(cpu, a, CPUFLAG_WIDTH_8B | CPUFLAG_GRP1);
	*cpu.dst_u8 = cast(ubyte)a;
}

void exec13h(cpu_t *cpu) { // adc reg16, rm16
	int modrm = void;
	if (mmgu8_i(cpu, &modrm)) return;
	if (modrm16rm(cpu, modrm, MODRM_WIDTH_16B)) return;
	modrm16reg(cpu, modrm, MODRM_SET_DST);
	int a = *cpu.dst_u16 + *cpu.src_u16;
	if (cpu.FLAG & FLAG_CF) ++a;
	cpuflag(cpu, a, CPUFLAG_WIDTH_16B | CPUFLAG_GRP1);
	*cpu.dst_u16 = cast(ushort)a;
}

void exec14h(cpu_t *cpu) { // adc al, imm8
	int imm = void;
	if (mmgu8_i(cpu, &imm)) return;
	int a = cpu.gregs.AL + imm;
	if (cpu.FLAG & FLAG_CF) ++a;
	cpuflag(cpu, a, CPUFLAG_WIDTH_8B | CPUFLAG_GRP1);
	cpu.gregs.AL = cast(ubyte)a;
}

void exec15h(cpu_t *cpu) { // adc ax, imm16
	int imm = void;
	if (mmgu16_i(cpu, &imm)) return;
	int a = cpu.gregs.AX + imm;
	if (cpu.FLAG & FLAG_CF) ++a;
	cpuflag(cpu, a, CPUFLAG_WIDTH_16B | CPUFLAG_GRP1);
	cpu.gregs.AX = cast(ushort)a;
}

void exec16h(cpu_t *cpu) { // push ss
	cpupush16(cpu, cpu.sregs.SS);
}

void exec17h(cpu_t *cpu) { // pop ss
	cpu.sregs.SS = cpupop16(cpu);
}

void exec18h(cpu_t *cpu) { // sbb rm8, reg8
	int modrm = void;
	if (mmgu8_i(cpu, &modrm)) return;
	if (modrm16rm(cpu, modrm, MODRM_SET_DST | MODRM_WIDTH_8B)) return;
	modrm8reg(cpu, modrm, MODRM_WIDTH_8B);
	modrm = *cpu.src_u8; // re-use var
	if (cpu.FLAG & FLAG_CF) ++modrm;
	int a = *cpu.dst_u8 - modrm;
	cpuflag(cpu, a, CPUFLAG_WIDTH_8B | CPUFLAG_GRP1);
	*cpu.dst_u8 = cast(ubyte)a;
}

void exec19h(cpu_t *cpu) { // sbb rm16, reg16
	int modrm = void;
	if (mmgu8_i(cpu, &modrm)) return;
	if (modrm16rm(cpu, modrm, MODRM_SET_DST | MODRM_WIDTH_16B)) return;
	modrm16reg(cpu, modrm, 0);
	modrm = *cpu.src_u8; // re-use var
	if (cpu.FLAG & FLAG_CF) ++modrm;
	int a = *cpu.dst_u8 - modrm;
	cpuflag(cpu, a, CPUFLAG_WIDTH_16B | CPUFLAG_GRP1);
	*cpu.dst_u16 = cast(ushort)a;
}

void exec1Ah(cpu_t *cpu) { // sbb reg8, rm8
	int modrm = void;
	if (mmgu8_i(cpu, &modrm)) return;
	if (modrm16rm(cpu, modrm, MODRM_WIDTH_8B)) return;
	modrm8reg(cpu, modrm, MODRM_SET_DST);
	modrm = *cpu.src_u8; // re-use var
	if (cpu.FLAG & FLAG_CF) ++modrm;
	int a = *cpu.dst_u8 - modrm;
	cpuflag(cpu, a, CPUFLAG_WIDTH_8B | CPUFLAG_GRP1);
	*cpu.dst_u8 = cast(ubyte)a;
}

void exec1Bh(cpu_t *cpu) { // sbb reg16, rm16
	int modrm = void;
	if (mmgu8_i(cpu, &modrm)) return;
	if (modrm16rm(cpu, modrm, MODRM_WIDTH_16B)) return;
	modrm16reg(cpu, modrm, MODRM_SET_DST);
	modrm = *cpu.src_u8; // re-use var
	if (cpu.FLAG & FLAG_CF) ++modrm;
	int a = *cpu.dst_u8 - modrm;
	cpuflag(cpu, a, CPUFLAG_WIDTH_16B | CPUFLAG_GRP1);
	*cpu.dst_u16 = cast(ushort)a;
}

void exec1Ch(cpu_t *cpu) { // sbb al, imm8
	int imm = void;
	if (mmgu8_i(cpu, &imm)) return;
	if (cpu.FLAG & FLAG_CF) ++imm;
	int a = cpu.gregs.AL - imm;
	cpuflag(cpu, a, CPUFLAG_WIDTH_8B | CPUFLAG_GRP1);
	cpu.gregs.AL = cast(ubyte)a;
}

void exec1Dh(cpu_t *cpu) { // sbb ax, imm16
	int imm = void;
	if (mmgu16_i(cpu, &imm)) return;
	if (cpu.FLAG & FLAG_CF) ++imm;
	int a = cpu.gregs.AL - imm;
	cpuflag(cpu, a, CPUFLAG_WIDTH_16B | CPUFLAG_GRP1);
	cpu.gregs.AX = cast(ushort)a;
}

void exec1Eh(cpu_t *cpu) { // push ds
	cpupush16(cpu, cpu.sregs.DS);
}

void exec1Fh(cpu_t *cpu) { // pop ds
	cpu.sregs.DS = cpupop16(cpu);
}

void exec20h(cpu_t *cpu) { // and rm8, reg8
	int modrm = void;
	if (mmgu8_i(cpu, &modrm)) return;
	if (modrm16rm(cpu, modrm, MODRM_SET_DST | MODRM_WIDTH_8B)) return;
	modrm8reg(cpu, modrm, MODRM_WIDTH_8B);
	int a = *cpu.dst_u8 & *cpu.src_u8;
	cpuflag(cpu, a, CPUFLAG_WIDTH_8B | CPUFLAG_GRP2);
	cpu.FLAG &= ~(FLAG_OF | FLAG_CF);
	*cpu.dst_u8 = cast(ubyte)a;
}

void exec21h(cpu_t *cpu) { // and rm16, reg16
	int modrm = void;
	if (mmgu8_i(cpu, &modrm)) return;
	if (modrm16rm(cpu, modrm, MODRM_SET_DST | MODRM_WIDTH_16B)) return;
	modrm16reg(cpu, modrm, 0);
	int a = *cpu.dst_u16 & *cpu.src_u16;
	cpuflag(cpu, a, CPUFLAG_WIDTH_16B | CPUFLAG_GRP2);
	cpu.FLAG &= ~(FLAG_OF | FLAG_CF);
	*cpu.dst_u16 = cast(ushort)a;
}

void exec22h(cpu_t *cpu) { // and reg8, rm8
	int modrm = void;
	if (mmgu8_i(cpu, &modrm)) return;
	if (modrm16rm(cpu, modrm, MODRM_WIDTH_8B)) return;
	modrm8reg(cpu, modrm, MODRM_SET_DST);
	int a = *cpu.dst_u8 & *cpu.src_u8;
	cpuflag(cpu, a, CPUFLAG_WIDTH_8B | CPUFLAG_GRP2);
	cpu.FLAG &= ~(FLAG_OF | FLAG_CF);
	*cpu.dst_u8 = cast(ubyte)a;
}

void exec23h(cpu_t *cpu) { // and reg16, rm16
	int modrm = void;
	if (mmgu8_i(cpu, &modrm)) return;
	if (modrm16rm(cpu, modrm, MODRM_WIDTH_16B)) return;
	modrm16reg(cpu, modrm, MODRM_SET_DST);
	int a = *cpu.dst_u16 & *cpu.src_u16;
	cpuflag(cpu, a, CPUFLAG_WIDTH_16B | CPUFLAG_GRP2);
	cpu.FLAG &= ~(FLAG_OF | FLAG_CF);
	*cpu.dst_u16 = cast(ushort)a;
}

void exec24h(cpu_t *cpu) { // and al, imm8
	int imm = void;
	if (mmgu8_i(cpu, &imm)) return;
	int a = cpu.gregs.AL & imm;
	cpuflag(cpu, a, CPUFLAG_WIDTH_8B | CPUFLAG_GRP2);
	cpu.FLAG &= ~(FLAG_OF | FLAG_CF);
	cpu.gregs.AL = cast(ubyte)a;
}

void exec25h(cpu_t *cpu) { // and ax, imm16
	int imm = void;
	if (mmgu16_i(cpu, &imm)) return;
	int a = cpu.gregs.AX & imm;
	cpuflag(cpu, a, CPUFLAG_WIDTH_16B | CPUFLAG_GRP2);
	cpu.FLAG &= ~(FLAG_OF | FLAG_CF);
	cpu.gregs.AX = cast(ushort)a;
}

void exec26h(cpu_t *cpu) { // es:
	cpu.segov = SegReg.ES;
}

void exec27h(cpu_t *cpu) { // daa
	int r = cpu.gregs.AL;

	if ((r & 0xF) > 9 || cpu.FLAG & FLAG_AF) {
		if (r > 0x99 || cpu.FLAG & FLAG_CF) {
			r += 0x60;
			cpu.FLAG |= FLAG_CF;
		} else {
			cpu.FLAG &= ~FLAG_CF;
		}
		r += 6;
		cpu.FLAG |= FLAG_AF;
	} else {
		if (r > 0x99 || cpu.FLAG & FLAG_CF) {
			r += 0x60;
			cpu.FLAG |= FLAG_CF;
		} else {
			cpu.FLAG &= ~FLAG_CF;
		}
		cpu.FLAG &= ~FLAG_AF;
	}

	cpuflag(cpu, r, CPUFLAG_WIDTH_8B | FLAG_ZF | FLAG_SF | FLAG_PF);
	cpu.gregs.AL = cast(ubyte)r;
}
