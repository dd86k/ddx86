module vcpu.core;

import core.stdc.stdlib : malloc;
import vdos.def : system_t;
import consts;

extern (C):

/// General register enumeration
enum Reg {
	A, C, D, B, SP, BP, SI, DI
}
/// Segment register enumeration
enum SegReg {
	CS, SS, DS, ES, FS, GS, None
}
/// Processor model, affects instruction latency and availability
enum CPUModel {
	i8086, i486, Pentium
}
/// Processor operating mode
enum CPUMode {
	Real, System, Protected, VM8086
}
enum {
	FLAG_CF = 1,	/// Bit 0
	FLAG_PF = 4,	/// Bit 2
	FLAG_AF = 0x10,	/// Bit 4
	FLAG_ZF = 0x40,	/// Bit 6
	FLAG_SF = 0x80,	/// Bit 7
	FLAG_TF = 0x100,	/// Bit 8
	FLAG_IF = 0x200,	/// Bit 9
	FLAG_DF = 0x400,	/// Bit 10
	FLAG_OF = 0x800,	/// Bit 11
	// i286
	FLAG_IOPL = 0x3000,	/// Bit 13:12
	FLAG_NT   = 0x4000,	/// Bit 14
	// i386
	FLAG_RF = 0x1_0000,	/// Bit 16
	FLAG_VM = 0x2_0000,	/// Bit 17

	// CR0
	CR0_PE = 1,	/// Bit 0
	CR0_MP = 2,	/// Bit 1
	CR0_EM = 4,	/// Bit 2
	CR0_TS = 8,	/// Bit 3
	CR0_ET = 0x10,	/// Bit 4
	CR0_NE = 0x20,	/// Bit 5
	CR0_WP = 0x1_0000,	/// Bit 16
	CR0_AM = 0x4_0000,	/// Bit 18
	CR0_PG = 0x8000_0000,	/// Bit 31
	// CR3
	CR3_PWT = 8,	/// Bit 3
	CR3_PCD = 0x10	/// Bit 4
}

/// General register structure to overlap with register array
struct general_regsiter_t {
	union {
		uint EAX; // @suppress(dscanner.style.undocumented_declaration)
		ushort AX; // @suppress(dscanner.style.undocumented_declaration)
		struct { ubyte AL, AH; } // @suppress(dscanner.style.undocumented_declaration)
	}
	union {
		uint ECX; // @suppress(dscanner.style.undocumented_declaration)
		ushort CX; // @suppress(dscanner.style.undocumented_declaration)
		struct { ubyte CL, CH; } // @suppress(dscanner.style.undocumented_declaration)
	}
	union {
		uint EDX; // @suppress(dscanner.style.undocumented_declaration)
		ushort DX; // @suppress(dscanner.style.undocumented_declaration)
		struct { ubyte DL, DH; } // @suppress(dscanner.style.undocumented_declaration)
	}
	union {
		uint EBX; // @suppress(dscanner.style.undocumented_declaration)
		ushort BX; // @suppress(dscanner.style.undocumented_declaration)
		struct { ubyte BL, BH; } // @suppress(dscanner.style.undocumented_declaration)
	}
	union {
		uint ESP; // @suppress(dscanner.style.undocumented_declaration)
		ushort SP; // @suppress(dscanner.style.undocumented_declaration)
	}
	union {
		uint EBP; // @suppress(dscanner.style.undocumented_declaration)
		ushort BP; // @suppress(dscanner.style.undocumented_declaration)
	}
	union {
		uint ESI; // @suppress(dscanner.style.undocumented_declaration)
		ushort SI; // @suppress(dscanner.style.undocumented_declaration)
	}
	union {
		uint EDI; // @suppress(dscanner.style.undocumented_declaration)
		ushort DI; // @suppress(dscanner.style.undocumented_declaration)
	}
}
/// Defines a register, with lower 16-bit, and 8-bit halves accesses
struct register_t {
	union {
		alias u32 this;
		uint u32; // @suppress(dscanner.style.undocumented_declaration)
		ushort u16; // @suppress(dscanner.style.undocumented_declaration)
		struct { ubyte u8l, u8h; } // @suppress(dscanner.style.undocumented_declaration)
	}
}

/// Main CPU structure with CPU state
struct cpu_t {
	union {
		void *memptr;	/// Memory bank pointer
		ubyte *mem;	/// Memory bank pointer
		system_t *sys;	/// System pointer (memory)
	}
	uint memsize;	/// Memory size, allocated in bytes
	// Registers
	union {
		register_t[8] regs;	/// Common registers within ModR/M reach
		general_regsiter_t gregs;	/// Provides prettier register names
	}
	register_t EIP;	/// Instruction Pointer
	register_t FLAG;	/// Flag register
	uint[8] CR;	/// Control registers
	ushort[6] segs;	/// Segment registers
	uint[8] TR;	/// T registers
	uint[8] DR;	/// Debug registers
	// Internals
	int pf66h;	/// Operand prefix
	int pf67h;	/// Address prefix
	int seg;	/// Segment override
	int ring;	/// CPL
	int opmode;	/// Operating mode (real, protected, etc.)
	int cycles;	/// Reserved

	// Compilers would whine if a local variable pointer is "used" before
	// setting, so instead of being in the exec core, it's here
	union {
		void   *src;	/// Used internally
		ubyte  *src_u8;	/// Used internally
		ushort *src_u16;	/// Used internally
		uint   *src_u32;	/// Used internally
	}
	union {
		void   *dst;	/// Used internally
		ubyte  *dst_u8;	/// Used internally
		ushort *dst_u16;	/// Used internally
		uint   *dst_u32;	/// Used internally
	}
	
	void function(cpu_t*)[256] opmap1;	/// 1-byte opcode map
	void function(cpu_t*)[256] opmap2;	/// 2-byte opcode map
}
/// CPU settings for init function
struct cpu_settings_t {
	int memkb;	/// Requested memory amount in KiB
	int cpumodel;	/// CPUModel, only i8086 is currently supported
}

/// Initiate the cpu struture with a settings structure. This initiates
/// memory, instruction function tables, some special registers, and then
/// performs a RESET.
/// Params:
/// 	cpu = cpu_t structure
/// 	settings = cpu_settings_t structure
/// Returns: Non-zero on error
int cpuinit(cpu_t *cpu, cpu_settings_t *settings) {
	import vcpu.exec;

	settings.memkb <<= 10;

	if (settings.memkb > MAX_MEM)
		return 1;
	if (settings.memkb < 640 * 1024)
		return 2;

	cpu.memptr = malloc(settings.memkb);
	if (cpu.memptr == null)
		return 3;

	cpu.memsize = settings.memkb;
	cpureset(cpu);

	// Function assignment
	cpu.opmap1[0x00] = &exec00h;
	cpu.opmap1[0x01] = &exec01h;
	/+OPMAP1[0x02] = &exec02;
	OPMAP1[0x03] = &exec03;
	OPMAP1[0x04] = &exec04;
	OPMAP1[0x05] = &exec05;
	OPMAP1[0x06] = &exec06;
	OPMAP1[0x07] = &exec07;
	OPMAP1[0x08] = &exec08;
	OPMAP1[0x09] = &exec09;
	OPMAP1[0x0A] = &exec0A;
	OPMAP1[0x0B] = &exec0B;
	OPMAP1[0x0C] = &exec0C;
	OPMAP1[0x0D] = &exec0D;
	OPMAP1[0x0E] = &exec0E;
	OPMAP1[0x10] = &exec10;
	OPMAP1[0x11] = &exec11;
	OPMAP1[0x12] = &exec12;
	OPMAP1[0x13] = &exec13;
	OPMAP1[0x14] = &exec14;
	OPMAP1[0x15] = &exec15;
	OPMAP1[0x16] = &exec16;
	OPMAP1[0x17] = &exec17;
	OPMAP1[0x18] = &exec18;
	OPMAP1[0x19] = &exec19;
	OPMAP1[0x1A] = &exec1A;
	OPMAP1[0x1B] = &exec1B;
	OPMAP1[0x1C] = &exec1C;
	OPMAP1[0x1D] = &exec1D;
	OPMAP1[0x1E] = &exec1E;
	OPMAP1[0x1F] = &exec1F;
	OPMAP1[0x20] = &exec20;
	OPMAP1[0x21] = &exec21;
	OPMAP1[0x22] = &exec22;
	OPMAP1[0x23] = &exec23;
	OPMAP1[0x24] = &exec24;
	OPMAP1[0x25] = &exec25;
	OPMAP1[0x26] = &exec26;
	OPMAP1[0x27] = &exec27;
	OPMAP1[0x28] = &exec28;
	OPMAP1[0x29] = &exec29;
	OPMAP1[0x2A] = &exec2A;
	OPMAP1[0x2B] = &exec2B;
	OPMAP1[0x2C] = &exec2C;
	OPMAP1[0x2D] = &exec2D;
	OPMAP1[0x2E] = &exec2E;
	OPMAP1[0x2F] = &exec2F;
	OPMAP1[0x30] = &exec30;
	OPMAP1[0x31] = &exec31;
	OPMAP1[0x32] = &exec32;
	OPMAP1[0x33] = &exec33;
	OPMAP1[0x34] = &exec34;
	OPMAP1[0x35] = &exec35;
	OPMAP1[0x36] = &exec36;
	OPMAP1[0x37] = &exec37;
	OPMAP1[0x38] = &exec38;
	OPMAP1[0x39] = &exec39;
	OPMAP1[0x3A] = &exec3A;
	OPMAP1[0x3B] = &exec3B;
	OPMAP1[0x3C] = &exec3C;
	OPMAP1[0x3D] = &exec3D;
	OPMAP1[0x3E] = &exec3E;
	OPMAP1[0x3F] = &exec3F;
	OPMAP1[0x40] = &exec40;
	OPMAP1[0x41] = &exec41;
	OPMAP1[0x42] = &exec42;
	OPMAP1[0x43] = &exec43;
	OPMAP1[0x44] = &exec44;
	OPMAP1[0x45] = &exec45;
	OPMAP1[0x46] = &exec46;
	OPMAP1[0x47] = &exec47;
	OPMAP1[0x48] = &exec48;
	OPMAP1[0x49] = &exec49;
	OPMAP1[0x4A] = &exec4A;
	OPMAP1[0x4B] = &exec4B;
	OPMAP1[0x4C] = &exec4C;
	OPMAP1[0x4D] = &exec4D;
	OPMAP1[0x4E] = &exec4E;
	OPMAP1[0x4F] = &exec4F;
	OPMAP1[0x50] = &exec50;
	OPMAP1[0x51] = &exec51;
	OPMAP1[0x52] = &exec52;
	OPMAP1[0x53] = &exec53;
	OPMAP1[0x54] = &exec54;
	OPMAP1[0x55] = &exec55;
	OPMAP1[0x56] = &exec56;
	OPMAP1[0x57] = &exec57;
	OPMAP1[0x58] = &exec58;
	OPMAP1[0x59] = &exec59;
	OPMAP1[0x5A] = &exec5A;
	OPMAP1[0x5B] = &exec5B;
	OPMAP1[0x5C] = &exec5C;
	OPMAP1[0x5D] = &exec5D;
	OPMAP1[0x5E] = &exec5E;
	OPMAP1[0x5F] = &exec5F;
	OPMAP1[0x70] = &exec70;
	OPMAP1[0x71] = &exec71;
	OPMAP1[0x72] = &exec72;
	OPMAP1[0x73] = &exec73;
	OPMAP1[0x74] = &exec74;
	OPMAP1[0x75] = &exec75;
	OPMAP1[0x76] = &exec76;
	OPMAP1[0x77] = &exec77;
	OPMAP1[0x78] = &exec78;
	OPMAP1[0x79] = &exec79;
	OPMAP1[0x7A] = &exec7A;
	OPMAP1[0x7B] = &exec7B;
	OPMAP1[0x7C] = &exec7C;
	OPMAP1[0x7D] = &exec7D;
	OPMAP1[0x7E] = &exec7E;
	OPMAP1[0x7F] = &exec7F;
	OPMAP1[0x80] = &exec80;
	OPMAP1[0x81] = &exec81;
	OPMAP1[0x82] = &exec82;
	OPMAP1[0x83] = &exec83;
	OPMAP1[0x84] = &exec84;
	OPMAP1[0x85] = &exec85;
	OPMAP1[0x86] = &exec86;
	OPMAP1[0x87] = &exec87;
	OPMAP1[0x88] = &exec88;
	OPMAP1[0x89] = &exec89;
	OPMAP1[0x8A] = &exec8A;
	OPMAP1[0x8B] = &exec8B;
	OPMAP1[0x8C] = &exec8C;
	OPMAP1[0x8D] = &exec8D;
	OPMAP1[0x8E] = &exec8E;
	OPMAP1[0x8F] = &exec8F;
	OPMAP1[0x90] = &exec90;
	OPMAP1[0x91] = &exec91;
	OPMAP1[0x92] = &exec92;
	OPMAP1[0x93] = &exec93;
	OPMAP1[0x94] = &exec94;
	OPMAP1[0x95] = &exec95;
	OPMAP1[0x96] = &exec96;
	OPMAP1[0x97] = &exec97;
	OPMAP1[0x98] = &exec98;
	OPMAP1[0x99] = &exec99;
	OPMAP1[0x9A] = &exec9A;
	OPMAP1[0x9B] = &exec9B;
	OPMAP1[0x9C] = &exec9C;
	OPMAP1[0x9D] = &exec9D;
	OPMAP1[0x9E] = &exec9E;
	OPMAP1[0x9F] = &exec9F;
	OPMAP1[0xA0] = &execA0;
	OPMAP1[0xA1] = &execA1;
	OPMAP1[0xA2] = &execA2;
	OPMAP1[0xA3] = &execA3;
	OPMAP1[0xA4] = &execA4;
	OPMAP1[0xA5] = &execA5;
	OPMAP1[0xA6] = &execA6;
	OPMAP1[0xA7] = &execA7;
	OPMAP1[0xA8] = &execA8;
	OPMAP1[0xA9] = &execA9;
	OPMAP1[0xAA] = &execAA;
	OPMAP1[0xAB] = &execAB;
	OPMAP1[0xAC] = &execAC;
	OPMAP1[0xAD] = &execAD;
	OPMAP1[0xAE] = &execAE;
	OPMAP1[0xAF] = &execAF;
	OPMAP1[0xB0] = &execB0;
	OPMAP1[0xB1] = &execB1;
	OPMAP1[0xB2] = &execB2;
	OPMAP1[0xB3] = &execB3;
	OPMAP1[0xB4] = &execB4;
	OPMAP1[0xB5] = &execB5;
	OPMAP1[0xB6] = &execB6;
	OPMAP1[0xB7] = &execB7;
	OPMAP1[0xB8] = &execB8;
	OPMAP1[0xB9] = &execB9;
	OPMAP1[0xBA] = &execBA;
	OPMAP1[0xBB] = &execBB;
	OPMAP1[0xBC] = &execBC;
	OPMAP1[0xBD] = &execBD;
	OPMAP1[0xBE] = &execBE;
	OPMAP1[0xBF] = &execBF;
	OPMAP1[0xC2] = &execC2;
	OPMAP1[0xC3] = &execC3;
	OPMAP1[0xC4] = &execC4;
	OPMAP1[0xC5] = &execC5;
	OPMAP1[0xC6] = &execC6;
	OPMAP1[0xC7] = &execC7;
	OPMAP1[0xCA] = &execCA;
	OPMAP1[0xCB] = &execCB;
	OPMAP1[0xCC] = &execCC;
	OPMAP1[0xCD] = &execCD;
	OPMAP1[0xCE] = &execCE;
	OPMAP1[0xCF] = &execCF;
	OPMAP1[0xD0] = &execD0;
	OPMAP1[0xD1] = &execD1;
	OPMAP1[0xD2] = &execD2;
	OPMAP1[0xD3] = &execD3;
	OPMAP1[0xD4] = &execD4;
	OPMAP1[0xD5] = &execD5;
	OPMAP1[0xD7] = &execD7;
	OPMAP1[0xE0] = &execE0;
	OPMAP1[0xE1] = &execE1;
	OPMAP1[0xE2] = &execE2;
	OPMAP1[0xE3] = &execE3;
	OPMAP1[0xE4] = &execE4;
	OPMAP1[0xE5] = &execE5;
	OPMAP1[0xE6] = &execE6;
	OPMAP1[0xE7] = &execE7;
	OPMAP1[0xE8] = &execE8;
	OPMAP1[0xE9] = &execE9;
	OPMAP1[0xEA] = &execEA;
	OPMAP1[0xEB] = &execEB;
	OPMAP1[0xEC] = &execEC;
	OPMAP1[0xED] = &execED;
	OPMAP1[0xEE] = &execEE;
	OPMAP1[0xEF] = &execEF;
	OPMAP1[0xF0] = &execF0;
	OPMAP1[0xF2] = &execF2;
	OPMAP1[0xF3] = &execF3;
	OPMAP1[0xF4] = &execF4;
	OPMAP1[0xF5] = &execF5;
	OPMAP1[0xF6] = &execF6;
	OPMAP1[0xF7] = &execF7;
	OPMAP1[0xF8] = &execF8;
	OPMAP1[0xF9] = &execF9;
	OPMAP1[0xFA] = &execFA;
	OPMAP1[0xFB] = &execFB;
	OPMAP1[0xFC] = &execFC;
	OPMAP1[0xFD] = &execFD;
	OPMAP1[0xFE] = &execFE;
	OPMAP1[0xFF] = &execFF;
	OPMAP1[0xD6] = &execill;
	switch (cpu.model) {
	case CPU_8086:
		OPMAP1[0xC8] =
		OPMAP1[0xC9] =
		OPMAP1[0x0F] = // Two-byte map
		OPMAP1[0xC0] =
		OPMAP1[0xC1] =
		OPMAP1[0xD8] =
		OPMAP1[0xD9] =
		OPMAP1[0xDA] =
		OPMAP1[0xDB] =
		OPMAP1[0xDC] =
		OPMAP1[0xDD] =
		OPMAP1[0xDE] =
		OPMAP1[0xDF] =
		OPMAP1[0xF1] = &execill;
		// While it is possible to map a range, range sets rely on
		// memset32/64 which DMD linkers will not find
		for (size_t i = 0x60; i < 0x70; ++i)
			OPMAP1[i] = &execill;
		break;
	case CPU_80486:
		OPMAP1[0x60] =
		OPMAP1[0x61] =
		OPMAP1[0x62] =
		OPMAP1[0x63] =
		OPMAP1[0x64] =
		OPMAP1[0x65] =
		OPMAP1[0x68] =
		OPMAP1[0x69] =
		OPMAP1[0x6A] =
		OPMAP1[0x6B] =
		OPMAP1[0x6C] =
		OPMAP1[0x6D] =
		OPMAP1[0x6E] =
		OPMAP1[0x6F] = &execill;
		OPMAP1[0x66] = &exec66;
		OPMAP1[0x67] = &exec67;
		break;
	default:
	}

	for (size_t i; i < 256; ++i) { // Sanity checker
		assert(OPMAP1[i], "REAL_MAP missed spot");
	}+/

	return 0;
}

/// Starts the CPU and start executing instructions at EIP. The CPU absolutely
/// must be initiated before calling this function.
/// Params: cpu = cpu_t structure
void cpurun(cpu_t *cpu) {
	
}

/// Performs a RESET on the CPU. Sets operation mode to Real, segment override
/// to None, FLAG to 2, EIP to 0, DS/SS/ES to 0, and CS to 0xFFFF.
/// Params: cpu = cpu_t structure
void cpureset(cpu_t *cpu) {
	cpu.opmode = CPUMode.Real;
	cpu.seg = SegReg.None;

	cpu.FLAG.u32 = 2;
	cpu.EIP.u32 = 0;
	cpu.segs[SegReg.DS] = cpu.segs[SegReg.SS] = cpu.segs[SegReg.ES] = 0;
	cpu.segs[SegReg.CS] = 0xFFFF;
}

/// Get the value of a segment register. If the segment override is set to
/// None, the specified default segment value is returned.
/// Params: cpu = cpu_t structure
ushort cpuseg(cpu_t *cpu, SegReg def) {
	if (cpu.seg == SegReg.None)
		return cpu.segs[def];
	else
		return cpu.segs[cpu.seg];
}

//
// CPU flagging operations
//

enum {
	CPUFLAG_WIDTH_8B	= 0,	/// Value is BYTE (8-bit)
	CPUFLAG_WIDTH_16B	= 0x100_0000,	/// Value is WORD (16-bit)
	CPUFLAG_WIDTH_32B	= 0x200_0000,	/// Value is DWORD (32-bit)
	CPUFLAG_WIDTH	= 0xF00_0000,	/// CPUFLAG width mask

	/// Affect OF, SF, ZF, AF, CF, and PF flags
	CPUFLAG_GRP1	= FLAG_OF | FLAG_SF | FLAG_ZF | FLAG_AF | FLAG_CF | FLAG_PF,
}

/// Evaluate specified flags. The operation width and EFLAGS values are set in
/// the flags parameter.
/// Params:
/// 	cpu = cpu_t structure
/// 	val = Value to evaluate
/// 	flags = Defines which flag to affect with the operating width OR'd
void cpuflag(cpu_t *cpu, int val, int flags) {
	if (flags & FLAG_ZF) {
		if (val == 0)
			cpu.FLAG |= FLAG_ZF;
		else
			cpu.FLAG &= ~FLAG_ZF;
	}
	switch (flags & CPUFLAG_WIDTH) {
	case CPUFLAG_WIDTH_8B:
		if (flags & FLAG_CF) {
			if (val & 0x100) {
				cpu.FLAG.u32 |= FLAG_CF;
			} else {
				cpu.FLAG.u32 &= ~FLAG_CF;
			}
		}
		return;
	case CPUFLAG_WIDTH_16B:
		if (flags & FLAG_CF) {
			if (val & 0x10000) {
				cpu.FLAG.u32 |= FLAG_CF;
			} else {
				cpu.FLAG.u32 &= ~FLAG_CF;
			}
		}
		return;
	default: // 32B
		
		return;
	}
}
