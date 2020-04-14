/**
 * mm: Processor memory manager
 * ---
 * The following function names are encoded using this example.
 * mmgu16_i
 * |||||| +- Immediate (fetch only, optional)
 * |||+++--- Type (unsigned 16-bit)
 * ||+------- Get (g) or Set (s)
 * ++-------- Memory Manager
 * ---
 */
module vcpu.mm;

import consts;
import vcpu.core;
import vcpu.interrupt;

extern (C):

//
// Segment utilities
//

//int chkseg16(cpu_t *cpu, ushort seg, int addr)

//
// Fetch / Get
//

/**
 * Get BYTE from absolute address.
 * Params:
 * 	cpu = cpu_t structure
 * 	addr = Memory position
 * 	val = Data pointer
 * Returns: Non-zero on error and interrupt called
 */
int mmgu8(cpu_t *cpu, uint addr, int *val) {
	if (addr >= cpu.memsize) {
		interrupt(cpu, Vector.OF);
		return 1;
	}
	*val = cpu.mem[addr];
	return 0;
}

/**
 * Get WORD from absolute address.
 * Params:
 * 	cpu = cpu_t structure
 * 	addr = Memory position
 * 	val = Data pointer
 * Returns: Non-zero on error and interrupt called
 */
int mmgu16(cpu_t *cpu, uint addr, int *val) {
	if (addr >= cpu.memsize) {
		interrupt(cpu, Vector.OF);
		return 1;
	}
	*val = *cast(ushort*)(cpu.mem + addr);
	return 0;
}

//
// Immediate fetch / get
//

/**
 * Get immediate BYTE from IP.
 * Params:
 * 	cpu = cpu_t structure
 * 	val = Data pointer
 * Returns: Non-zero on error and interrupt called
 */
int mmgu8_i(cpu_t *cpu, int* val) {
	if (cpu.EIP >= cpu.memsize) {
		interrupt(cpu, Vector.OF);
		return 1;
	}
	*val = cpu.mem[cpu.EIP];
	++cpu.EIP.u32;
	return 0;
}

/**
 * Get immediate WORD from IP.
 * Params:
 * 	cpu = cpu_t structure
 * 	val = Data pointer
 * Returns: Non-zero on error and interrupt called
 */
int mmgu16_i(cpu_t *cpu, int* val) {
	if (cpu.EIP + 1 >= cpu.memsize) {
		interrupt(cpu, Vector.OF);
		return 1;
	}
	*val = *cast(ushort*)(cpu.mem + cpu.EIP);
	cpu.EIP += 2;
	return 0;
}

//
// Insert / Set
//

/**
 * Set BYTE at absolute address.
 * Params:
 * 	cpu = cpu_t structure
 * 	addr = Memory position
 * 	val = Data pointer
 * Returns: Non-zero on error and interrupt called
 */
int mmsu8(cpu_t *cpu, uint addr, int *val) {
	if (addr >= cpu.memsize) {
		interrupt(cpu, Vector.OF);
		return 1;
	}
	cpu.mem[addr] = cast(ubyte)*val;
	return 0;
}
/**
 * Set WORD at absolute address.
 * Params:
 * 	cpu = cpu_t structure
 * 	addr = Memory position
 * 	val = Data pointer
 * Returns: Non-zero on error and interrupt called
 */
int mmsu16(cpu_t *cpu, uint addr, int *val) {
	if (addr >= cpu.memsize) {
		interrupt(cpu, Vector.OF);
		return 1;
	}
	ushort* p = cast(ushort*)(cpu.mem + addr);
	*p = cast(ushort)*val;
	return 0;
}

//
// ANCHOR ModR/M
//

enum {
	MODRM_MOD_00 =   0,	/// MOD 00, Memory Mode, no displacement
	MODRM_MOD_01 =  64,	/// MOD 01, Memory Mode, 8-bit displacement
	MODRM_MOD_10 = 128,	/// MOD 10, Memory Mode, 16-bit displacement
	MODRM_MOD_11 = 192,	/// MOD 11, Register Mode
	MODRM_MOD = MODRM_MOD_11,	/// Used for masking the MOD bits (11 000 000)

	MODRM_REG_000 =  0,	/// AL/AX
	MODRM_REG_001 =  8,	/// CL/CX
	MODRM_REG_010 = 16,	/// DL/DX
	MODRM_REG_011 = 24,	/// BL/BX
	MODRM_REG_100 = 32,	/// AH/SP
	MODRM_REG_101 = 40,	/// CH/BP
	MODRM_REG_110 = 48,	/// DH/SI
	MODRM_REG_111 = 56,	/// BH/DI
	MODRM_REG = MODRM_REG_111,	/// Used for masking the REG bits (00 111 000)

	MODRM_RM_000 = 0,	/// R/M 000 bits
	MODRM_RM_001 = 1,	/// R/M 001 bits
	MODRM_RM_010 = 2,	/// R/M 010 bits
	MODRM_RM_011 = 3,	/// R/M 011 bits
	MODRM_RM_100 = 4,	/// R/M 100 bits
	MODRM_RM_101 = 5,	/// R/M 101 bits
	MODRM_RM_110 = 6,	/// R/M 110 bits
	MODRM_RM_111 = 7,	/// R/M 111 bits
	MODRM_RM = MODRM_RM_111,	/// Used for masking the R/M bits (00 000 111)

	MODRM_SET_SRC = 0,	/// Set source pointer
	MODRM_SET_DST = 1,	/// Set destination pointer
	MODRM_WIDTH_8B	= 0x100,	/// Flags: (MOD=11) Set reg width to 8-bit
	MODRM_WIDTH_16B	= 0x200,	/// Flags: (MOD=11) Set reg width to 16-bit
	MODRM_WIDTH_32B	= 0x300,	/// Flags: (MOD=11) Set reg width to 32-bit
	MODRM_WIDTH_64B	= 0x400,	/// Flags: (MOD=11) Set reg width to 64-bit
	MODRM_WIDTH	= 0xF00,	/// Width mask
}

/// Set the destination or source pointer from a ModR/M byte in real mode
/// (16-bit). This is effective with the MOD and RM fields.
/// Params:
/// 	cpu = cpu_t structure
/// 	modrm = Modrm value
/// 	flags = Set MODRM_SET_DST for destination (unset: SRC) and width when MOD=11
/// Returns: Non-zero on error and interrupt called
int modrm16rm(cpu_t *cpu, int modrm, int flags) {
	int mod = modrm & MODRM_MOD;
	int addr = void;
	int imm = void;
	switch (mod) {
	case 0:
		if (modrm_rm16(cpu, modrm, &addr))
			return 1;
		break;
	case MODRM_MOD_01: // +IMM8
		if (modrm_rm16(cpu, modrm, &addr))
			return 1;
		if (mmgu8_i(cpu, &imm))
			return 1;
		addr += cast(byte)imm;   // disp8 is sign-extended
		break;
	case MODRM_MOD_10: // +IMM16
		if (modrm_rm16(cpu, modrm, &addr))
			return 1;
		if (mmgu16_i(cpu, &imm))
			return 1;
		addr += cast(ushort)imm; // disp16 is not sign-extended
		break;
	default: // Register mode
		modrm <<= 3; // REG <- RM
		switch (flags & MODRM_WIDTH) {
		case MODRM_WIDTH_8B:  modrm8reg(cpu, modrm, flags); break;
		case MODRM_WIDTH_16B: modrm16reg(cpu, modrm, flags); break;
		default: return 1;
		}
		return 0;
	}
	if (addr >= cpu.memsize) {
		interrupt(cpu, Vector.OF);
		return 1;
	}
	if (flags & MODRM_SET_DST)
		cpu.dst = cpu.memptr + addr; // void.sizeof == 1
	else
		cpu.src = cpu.memptr + addr; // void.sizeof == 1
	return 0;
}

/// Set the destination or source pointer from a ModR/M byte in real mode
/// (16-bit). This is effective with the REG field with an 8-bit width.
/// Params:
/// 	cpu = cpu_t structure
/// 	modrm = Modrm value
/// 	flags = Set MODRM_SET_DST for destination
void modrm8reg(cpu_t *cpu, int modrm, int flags) {
	int reg = (modrm & MODRM_REG) >> 3;
	ubyte *p = reg & 0b100 ? &cpu.regs[reg].u8h : &cpu.regs[reg].u8l;
	if (flags & MODRM_SET_DST)
		cpu.dst_u8 = p;
	else
		cpu.src_u8 = p;
}
/// Set the destination or source pointer from a ModR/M byte in real mode
/// (16-bit). This is effective with the REG field with an 16-bit width.
/// Params:
/// 	cpu = cpu_t structure
/// 	modrm = Modrm value
/// 	flags = Set MODRM_SET_DST for destination
void modrm16reg(cpu_t *cpu, int modrm, int flags) {
	int reg = (modrm & MODRM_REG) >> 3;
	if (flags & MODRM_SET_DST)
		cpu.dst = &cpu.regs[reg].u16;
	else
		cpu.src = &cpu.regs[reg].u16;
}

//
// Internals
//

// R/M base address for real-mode
/// (Internal) Fetch base address with RM field in real mode (16-bit).
/// Params:
/// 	cpu = cpu_t structure
/// 	modrm = Modrm value
/// 	mem = Data pointer
/// Returns: Non-zero on error and interrupt called
int modrm_rm16(cpu_t *cpu, int modrm, int *mem) {
	int rm = modrm & MODRM_RM;
	int addr = void;
	switch (rm) { // R/M
	case MODRM_RM_000: addr = cpu.gregs.SI + cpu.gregs.BX; break;
	case MODRM_RM_001: addr = cpu.gregs.DI + cpu.gregs.BX; break;
	case MODRM_RM_010: addr = cpu.gregs.SI + cpu.gregs.BP; break;
	case MODRM_RM_011: addr = cpu.gregs.DI + cpu.gregs.BP; break;
	case MODRM_RM_100: addr = cpu.gregs.SI; break;
	case MODRM_RM_101: addr = cpu.gregs.DI; break;
	case MODRM_RM_110:
		if (mmgu16_i(cpu, &addr)) {
			interrupt(cpu, Vector.OF);
			return 1;
		}
		break;
	default:/*RM=111*/ addr = cpu.gregs.BX; break;
	}
	//TODO: Check more bounds
	if (addr >= cpu.memsize) {
		interrupt(cpu, Vector.OF);
		return 1;
	}
	*mem = addr;
	return 0;
}

//
// ANCHOR SIB
//