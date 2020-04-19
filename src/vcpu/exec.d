module vcpu.exec;

import vcpu.cpu;
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
	modrm8reg(cpu, modrm, 0);
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
	int v = void;
	if (cpupop16(cpu, &v))
		return;
	cpu.sregs.ES = cast(ushort)v;
}

void exec08h(cpu_t *cpu) { // or rm8, reg8
	int modrm = void;
	if (mmgu8_i(cpu, &modrm)) return;
	if (modrm16rm(cpu, modrm, MODRM_SET_DST | MODRM_WIDTH_8B)) return;
	modrm8reg(cpu, modrm, 0);
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
	modrm8reg(cpu, modrm, 0);
	int a = *cpu.dst_u8 + *cpu.src_u8;
	if (cpu.FLAG & FLAG_CF) ++a;
	cpuflag(cpu, a, CPUFLAG_WIDTH_8B | CPUFLAG_GRP1);
	*cpu.dst_u8 = cast(ubyte)a;
}

void exec11h(cpu_t *cpu) { // adc rm16, reg16
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
	int v = void;
	if (cpupop16(cpu, &v))
		return;
	cpu.sregs.SS = cast(ushort)v;
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
	int v = void;
	if (cpupop16(cpu, &v))
		return;
	cpu.sregs.DS = cast(ushort)v;
}

void exec20h(cpu_t *cpu) { // and rm8, reg8
	int modrm = void;
	if (mmgu8_i(cpu, &modrm)) return;
	if (modrm16rm(cpu, modrm, MODRM_SET_DST | MODRM_WIDTH_8B)) return;
	modrm8reg(cpu, modrm, 0);
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

void exec28h(cpu_t *cpu) { // sub rm8, reg8
	int modrm = void;
	if (mmgu8_i(cpu, &modrm)) return;
	if (modrm16rm(cpu, modrm, MODRM_SET_DST | MODRM_WIDTH_8B)) return;
	modrm8reg(cpu, modrm, 0);
	int a = *cpu.dst_u8 - *cpu.src_u8;
	cpuflag(cpu, a, CPUFLAG_WIDTH_8B | CPUFLAG_GRP1);
	*cpu.dst_u8 = cast(ubyte)a;
}

void exec29h(cpu_t *cpu) { // sub rm16, reg16
	int modrm = void;
	if (mmgu8_i(cpu, &modrm)) return;
	if (modrm16rm(cpu, modrm, MODRM_SET_DST | MODRM_WIDTH_16B)) return;
	modrm16reg(cpu, modrm, 0);
	int a = *cpu.dst_u16 - *cpu.src_u16;
	cpuflag(cpu, a, CPUFLAG_WIDTH_16B | CPUFLAG_GRP1);
	*cpu.dst_u16 = cast(ushort)a;
}

void exec2Ah(cpu_t *cpu) { // sub reg8, rm8
	int modrm = void;
	if (mmgu8_i(cpu, &modrm)) return;
	if (modrm16rm(cpu, modrm, MODRM_WIDTH_8B)) return;
	modrm8reg(cpu, modrm, MODRM_SET_DST);
	int a = *cpu.dst_u8 - *cpu.src_u8;
	cpuflag(cpu, a, CPUFLAG_WIDTH_8B | CPUFLAG_GRP1);
	*cpu.dst_u8 = cast(ubyte)a;
}

void exec2Bh(cpu_t *cpu) { // sub reg16, rm16
	int modrm = void;
	if (mmgu8_i(cpu, &modrm)) return;
	if (modrm16rm(cpu, modrm, MODRM_WIDTH_16B)) return;
	modrm16reg(cpu, modrm, MODRM_SET_DST);
	int a = *cpu.dst_u16 - *cpu.src_u16;
	cpuflag(cpu, a, CPUFLAG_WIDTH_16B | CPUFLAG_GRP1);
	*cpu.dst_u16 = cast(ushort)a;
}

void exec2Ch(cpu_t *cpu) { // sub al, imm8
	int imm = void;
	if (mmgu8_i(cpu, &imm)) return;
	int a = cpu.gregs.AL - imm;
	cpuflag(cpu, a, CPUFLAG_WIDTH_8B | CPUFLAG_GRP1);
	cpu.gregs.AL = cast(ubyte)a;
}

void exec2Dh(cpu_t *cpu) { // sub ax, imm16
	int imm = void;
	if (mmgu16_i(cpu, &imm)) return;
	int a = cpu.gregs.AX - imm;
	cpuflag(cpu, a, CPUFLAG_WIDTH_16B | CPUFLAG_GRP1);
	cpu.gregs.AX = cast(ushort)a;
}

void exec2Eh(cpu_t *cpu) { // cs:
	cpu.segov = SegReg.CS;
}

void exec2Fh(cpu_t *cpu) { // das
	int r = cpu.gregs.AL;

	if (((r & 0xF) > 9) || cpu.FLAG & FLAG_AF) {
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

void exec30h(cpu_t *cpu) { // xor rm8, reg8
	int modrm = void;
	if (mmgu8_i(cpu, &modrm)) return;
	if (modrm16rm(cpu, modrm, MODRM_SET_DST | MODRM_WIDTH_8B)) return;
	modrm8reg(cpu, modrm, 0);
	int a = *cpu.dst_u8 ^ *cpu.src_u8;
	cpuflag(cpu, a, CPUFLAG_WIDTH_8B | CPUFLAG_GRP2);
	cpu.FLAG &= ~(FLAG_OF | FLAG_CF);
	*cpu.dst_u8 = cast(ubyte)a;
}

void exec31h(cpu_t *cpu) { // xor rm16, reg16
	int modrm = void;
	if (mmgu8_i(cpu, &modrm)) return;
	if (modrm16rm(cpu, modrm, MODRM_SET_DST | MODRM_WIDTH_16B)) return;
	modrm16reg(cpu, modrm, 0);
	int a = *cpu.dst_u16 ^ *cpu.src_u16;
	cpuflag(cpu, a, CPUFLAG_WIDTH_16B | CPUFLAG_GRP2);
	cpu.FLAG &= ~(FLAG_OF | FLAG_CF);
	*cpu.dst_u16 = cast(ushort)a;
}

void exec32h(cpu_t *cpu) { // xor reg8, rm8
	int modrm = void;
	if (mmgu8_i(cpu, &modrm)) return;
	if (modrm16rm(cpu, modrm, MODRM_WIDTH_8B)) return;
	modrm8reg(cpu, modrm, MODRM_SET_DST);
	int a = *cpu.dst_u8 ^ *cpu.src_u8;
	cpuflag(cpu, a, CPUFLAG_WIDTH_8B | CPUFLAG_GRP2);
	cpu.FLAG &= ~(FLAG_OF | FLAG_CF);
	*cpu.dst_u8 = cast(ubyte)a;
}

void exec33h(cpu_t *cpu) { // xor reg16, rm16
	int modrm = void;
	if (mmgu8_i(cpu, &modrm)) return;
	if (modrm16rm(cpu, modrm, MODRM_WIDTH_16B)) return;
	modrm16reg(cpu, modrm, MODRM_SET_DST);
	int a = *cpu.dst_u16 ^ *cpu.src_u16;
	cpuflag(cpu, a, CPUFLAG_WIDTH_16B | CPUFLAG_GRP2);
	cpu.FLAG &= ~(FLAG_OF | FLAG_CF);
	*cpu.dst_u16 = cast(ushort)a;
}

void exec34h(cpu_t *cpu) { // xor al, imm8
	int imm = void;
	if (mmgu8_i(cpu, &imm)) return;
	int a = cpu.gregs.AL ^ imm;
	cpuflag(cpu, a, CPUFLAG_WIDTH_8B | CPUFLAG_GRP2);
	cpu.FLAG &= ~(FLAG_OF | FLAG_CF);
	cpu.gregs.AL = cast(ubyte)a;
}

void exec35h(cpu_t *cpu) { // xor ax, imm16
	int imm = void;
	if (mmgu16_i(cpu, &imm)) return;
	int a = cpu.gregs.AX ^ imm;
	cpuflag(cpu, a, CPUFLAG_WIDTH_16B | CPUFLAG_GRP2);
	cpu.FLAG &= ~(FLAG_OF | FLAG_CF);
	cpu.gregs.AX = cast(ushort)a;
}

void exec36h(cpu_t *cpu) { // ss:
	cpu.segov = SegReg.ES;
}

void exec37h(cpu_t *cpu) { // aaa
	if ((cpu.gregs.AL & 0xF) > 9 || cpu.FLAG & FLAG_AF) {
		cpu.gregs.AX += 0x106;
		cpu.FLAG |= FLAG_AF | FLAG_CF;
	} else
		cpu.FLAG &= ~(FLAG_AF | FLAG_CF);
	cpu.gregs.AL &= 0xF;
}

void exec38h(cpu_t *cpu) { // cmp rm8, reg8
	int modrm = void;
	if (mmgu8_i(cpu, &modrm)) return;
	if (modrm16rm(cpu, modrm, MODRM_SET_DST | MODRM_WIDTH_8B)) return;
	modrm8reg(cpu, modrm, 0);
	int a = *cpu.dst_u8 - *cpu.src_i8;
	cpuflag(cpu, a, CPUFLAG_WIDTH_8B | CPUFLAG_GRP1);
}

void exec39h(cpu_t *cpu) { // cmp rm16, reg16
	int modrm = void;
	if (mmgu8_i(cpu, &modrm)) return;
	if (modrm16rm(cpu, modrm, MODRM_SET_DST | MODRM_WIDTH_16B)) return;
	modrm16reg(cpu, modrm, 0);
	int a = *cpu.dst_u16 - *cpu.src_i16;
	cpuflag(cpu, a, CPUFLAG_WIDTH_16B | CPUFLAG_GRP1);
}

void exec3Ah(cpu_t *cpu) { // cmp reg8, rm8
	int modrm = void;
	if (mmgu8_i(cpu, &modrm)) return;
	if (modrm16rm(cpu, modrm, MODRM_WIDTH_8B)) return;
	modrm8reg(cpu, modrm, MODRM_SET_DST);
	int a = *cpu.dst_u8 + *cpu.src_i8;
	cpuflag(cpu, a, CPUFLAG_WIDTH_8B | CPUFLAG_GRP1);
}

void exec3Bh(cpu_t *cpu) { // cmp reg16, rm16
	int modrm = void;
	if (mmgu8_i(cpu, &modrm)) return;
	if (modrm16rm(cpu, modrm, MODRM_WIDTH_16B)) return;
	modrm16reg(cpu, modrm, MODRM_SET_DST);
	int a = *cpu.dst_u16 - *cpu.src_i16;
	cpuflag(cpu, a, CPUFLAG_WIDTH_16B | CPUFLAG_GRP1);
}

void exec3Ch(cpu_t *cpu) { // cmp al, imm8
	int imm = void;
	if (mmgu8_i(cpu, &imm)) return;
	int a = cpu.gregs.AL - imm;
	cpuflag(cpu, a, CPUFLAG_WIDTH_8B | CPUFLAG_GRP1);
}

void exec3Dh(cpu_t *cpu) { // cmp ax, imm16
	int imm = void;
	if (mmgu16_i(cpu, &imm)) return;
	int a = cpu.gregs.AX - imm;
	cpuflag(cpu, a, CPUFLAG_WIDTH_16B | CPUFLAG_GRP1);
}

void exec3Eh(cpu_t *cpu) { // ds:
	cpu.segov = SegReg.DS;
}

void exec3Fh(cpu_t *cpu) { // aas
	if (((cpu.gregs.AL & 0xF) > 9) || cpu.FLAG & FLAG_AF) {
		cpu.gregs.AX -= 6;
		--cpu.gregs.AH;
		cpu.FLAG |= FLAG_AF | FLAG_CF;
	} else {
		cpu.FLAG &= ~(FLAG_AF | FLAG_CF);
	}
	cpu.gregs.AL &= 0xF;
}

void exec40h(cpu_t *cpu) { // inc ax
	++cpu.gregs.AX;
}

void exec41h(cpu_t *cpu) { // inc cx
	++cpu.gregs.CX;
}

void exec42h(cpu_t *cpu) { // inc dx
	++cpu.gregs.DX;
}

void exec43h(cpu_t *cpu) { // inc bx
	++cpu.gregs.BX;
}

void exec44h(cpu_t *cpu) { // inc sp
	++cpu.gregs.SP;
}

void exec45h(cpu_t *cpu) { // inc bp
	++cpu.gregs.BP;
}

void exec46h(cpu_t *cpu) { // inc si
	++cpu.gregs.SI;
}

void exec47h(cpu_t *cpu) { // inc di
	++cpu.gregs.DI;
}

void exec48h(cpu_t *cpu) { // dec ax
	--cpu.gregs.AX;
}

void exec49h(cpu_t *cpu) { // dec cx
	--cpu.gregs.CX;
}

void exec4Ah(cpu_t *cpu) { // dec dx
	--cpu.gregs.DX;
}

void exec4Bh(cpu_t *cpu) { // dec bx
	--cpu.gregs.BX;
}

void exec4Ch(cpu_t *cpu) { // dec sp
	--cpu.gregs.SP;
}

void exec4Dh(cpu_t *cpu) { // dec bp
	--cpu.gregs.BP;
}

void exec4Eh(cpu_t *cpu) { // dec si
	--cpu.gregs.SI;
}

void exec4Fh(cpu_t *cpu) { // dec di
	--cpu.gregs.DI;
}

void exec50h(cpu_t *cpu) { // push ax
	cpupush16(cpu, cpu.gregs.AX);
}

void exec51h(cpu_t *cpu) { // push cx
	cpupush16(cpu, cpu.gregs.CX);
}

void exec52h(cpu_t *cpu) { // push dx
	cpupush16(cpu, cpu.gregs.DX);
}

void exec53h(cpu_t *cpu) { // push bx
	cpupush16(cpu, cpu.gregs.BX);
}

void exec54h(cpu_t *cpu) { // push sp
	cpupush16(cpu, cpu.gregs.SP);
}

void exec55h(cpu_t *cpu) { // push bp
	cpupush16(cpu, cpu.gregs.BP);
}

void exec56h(cpu_t *cpu) { // push si
	cpupush16(cpu, cpu.gregs.SI);
}

void exec57h(cpu_t *cpu) { // push di
	cpupush16(cpu, cpu.gregs.DI);
}

void exec58h(cpu_t *cpu) { // pop ax
	int v = void;
	if (cpupop16(cpu, &v))
		return;
	cpu.gregs.AX = cast(ushort)v;
}

void exec59h(cpu_t *cpu) { // pop cx
	int v = void;
	if (cpupop16(cpu, &v))
		return;
	cpu.gregs.CX = cast(ushort)v;
}

void exec5Ah(cpu_t *cpu) { // pop dx
	int v = void;
	if (cpupop16(cpu, &v))
		return;
	cpu.gregs.DX = cast(ushort)v;
}

void exec5Bh(cpu_t *cpu) { // pop bx
	int v = void;
	if (cpupop16(cpu, &v))
		return;
	cpu.gregs.DX = cast(ushort)v;
}

void exec5Ch(cpu_t *cpu) { // pop sp
	int v = void;
	if (cpupop16(cpu, &v))
		return;
	cpu.gregs.SP = cast(ushort)v;
}

void exec5Dh(cpu_t *cpu) { // pop bp
	int v = void;
	if (cpupop16(cpu, &v))
		return;
	cpu.gregs.BP = cast(ushort)v;
}

void exec5Eh(cpu_t *cpu) { // pop si
	int v = void;
	if (cpupop16(cpu, &v))
		return;
	cpu.gregs.SI = cast(ushort)v;
}

void exec5Fh(cpu_t *cpu) { // pop di
	int v = void;
	if (cpupop16(cpu, &v))
		return;
	cpu.gregs.DI = cast(ushort)v;
}

void exec60h(cpu_t *cpu) { // pusha
	int sp = cpu.gregs.SP;
	if (cpupush16(cpu, cpu.gregs.AX)) return;
	if (cpupush16(cpu, cpu.gregs.CX)) return;
	if (cpupush16(cpu, cpu.gregs.DX)) return;
	if (cpupush16(cpu, cpu.gregs.BX)) return;
	if (cpupush16(cpu, sp)) return;
	if (cpupush16(cpu, cpu.gregs.BP)) return;
	if (cpupush16(cpu, cpu.gregs.SI)) return;
	if (cpupush16(cpu, cpu.gregs.DI)) return;
}

void exec61h(cpu_t *cpu) { // popa
	int v = void;
	if (cpupop16(cpu, &v)) return;
	cpu.gregs.DI = cast(ushort)v;
	if (cpupop16(cpu, &v)) return;
	cpu.gregs.SI = cast(ushort)v;
	if (cpupop16(cpu, &v)) return;
	cpu.gregs.BP = cast(ushort)v;
	cpu.gregs.SP += 2;
	if (cpupop16(cpu, &v)) return;
	cpu.gregs.BX = cast(ushort)v;
	if (cpupop16(cpu, &v)) return;
	cpu.gregs.DX = cast(ushort)v;
	if (cpupop16(cpu, &v)) return;
	cpu.gregs.CX = cast(ushort)v;
	if (cpupop16(cpu, &v)) return;
	cpu.gregs.AX = cast(ushort)v;
}

void exec62h(cpu_t *cpu) { // bound reg16, mem16&mem16
	int modrm = void;
	if (mmgu8_i(cpu, &modrm)) return;
	if ((modrm & MODRM_MOD) == MODRM_MOD_11) {
		interrupt(cpu, Vector.UD);
		return;
	}
	if (modrm16rm(cpu, modrm, 0)) return;
	modrm16reg(cpu, modrm, MODRM_SET_DST);
	modrm = *cpu.dst_u16; // re-use variables
	//TODO: Check stack and data segment limits
	if (modrm < *cpu.src_u16 || modrm > *(cpu.src_u16 + 1))
		interrupt(cpu, Vector.BR);
}

void exec63h(cpu_t *cpu) { // arpl r/m16,r16
	//TODO: arpl
	interrupt(cpu, Vector.UD);
}

void exec64h(cpu_t *cpu) { // fs:
	cpu.segov = SegReg.FS;
}

void exec65h(cpu_t *cpu) { // gs:
	cpu.segov = SegReg.GS;
}

void exec66h(cpu_t *cpu) { // operand size (66H)
	cpu.pf66h = 0x66;
}

void exec67h(cpu_t *cpu) { // address size (67H)
	cpu.pf67h = 0x67;
}

void exec68h(cpu_t *cpu) { // push imm16
	int imm = void;
	if (mmgu16_i(cpu, &imm)) return;
	cpupush16(cpu, imm);
}

void exec69h(cpu_t *cpu) { // imul reg16, rm16, imm16
	int imm = void; /// modrm
	if (mmgu8_i(cpu, &imm)) return;
	if (modrm16rm(cpu, imm, MODRM_WIDTH_16B)) return;
	modrm16reg(cpu, imm, MODRM_SET_DST);
	if (mmgu16_i(cpu, &imm)) return;
	imm = *cpu.src_u16 * imm;
	if (imm > 0xFFFF || imm < -0xFFFF)
		cpu.FLAG |= FLAG_CF | FLAG_OF;
	else
		cpu.FLAG &= ~(FLAG_CF | FLAG_OF);
	*cpu.dst_u16 = cast(ushort)imm;
}

void exec6Ah(cpu_t *cpu) { // push imm8
	int imm = void;
	if (mmgu8_i(cpu, &imm)) return;
	cpupush16(cpu, imm);
}

void exec6Bh(cpu_t *cpu) { // imul reg16, rm16, imm8
	int imm = void; /// modrm
	if (mmgu8_i(cpu, &imm)) return;
	if (modrm16rm(cpu, imm, MODRM_WIDTH_16B)) return;
	modrm16reg(cpu, imm, MODRM_SET_DST);
	if (mmgu8_i(cpu, &imm)) return;
	imm = *cpu.src_u16 * imm;
	if (imm > 0xFFFF || imm < -0xFFFF)
		cpu.FLAG |= FLAG_CF | FLAG_OF;
	else
		cpu.FLAG &= ~(FLAG_CF | FLAG_OF);
	*cpu.dst_u16 = cast(ushort)imm;
}
