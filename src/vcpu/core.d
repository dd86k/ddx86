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
struct general_regsiter_t { align(1):
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

/// Segment registers
struct segment_registers_t { align(1):
	ushort CS, SS, DS, ES, FS, GS; // @suppress(dscanner.style.undocumented_declaration)
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
	union {
		ushort[6] segs;	/// Segment registers
		segment_registers_t sregs;	/// Provides prettier register names
	}
	uint[8] TR;	/// T registers
	uint[8] DR;	/// Debug registers
	// Internals
	int pf66h;	/// Operand prefix
	int pf67h;	/// Address prefix
	int segov;	/// Segment override
	int ring;	/// CPL
	int opmode;	/// Operating mode (real, protected, etc.)
	int cycles;	/// Reserved
	int model;	/// CPU Model

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

	cpu.model = CPUModel.i8086;
	cpu.opmode = CPUMode.Real;

	// Function assignment
	cpu.opmap1[0x00] = &exec00h;
	cpu.opmap1[0x01] = &exec01h;
	cpu.opmap1[0x02] = &exec02h;
	cpu.opmap1[0x03] = &exec03h;
	cpu.opmap1[0x04] = &exec04h;
	cpu.opmap1[0x05] = &exec05h;
	cpu.opmap1[0x06] = &exec06h;
	cpu.opmap1[0x07] = &exec07h;
	/+cpu.opmap1[0x08] = &exec08h;
	cpu.opmap1[0x09] = &exec09h;
	cpu.opmap1[0x0A] = &exec0Ah;
	cpu.opmap1[0x0B] = &exec0Bh;
	cpu.opmap1[0x0C] = &exec0Ch;
	cpu.opmap1[0x0D] = &exec0Dh;
	cpu.opmap1[0x0E] = &exec0Eh;
	cpu.opmap1[0x10] = &exec10h;
	cpu.opmap1[0x11] = &exec11h;
	cpu.opmap1[0x12] = &exec12h;
	cpu.opmap1[0x13] = &exec13h;
	cpu.opmap1[0x14] = &exec14h;
	cpu.opmap1[0x15] = &exec15h;
	cpu.opmap1[0x16] = &exec16h;
	cpu.opmap1[0x17] = &exec17h;
	cpu.opmap1[0x18] = &exec18h;
	cpu.opmap1[0x19] = &exec19h;
	cpu.opmap1[0x1A] = &exec1Ah;
	cpu.opmap1[0x1B] = &exec1Bh;
	cpu.opmap1[0x1C] = &exec1Ch;
	cpu.opmap1[0x1D] = &exec1Dh;
	cpu.opmap1[0x1E] = &exec1Eh;
	cpu.opmap1[0x1F] = &exec1Fh;
	cpu.opmap1[0x20] = &exec20h;
	cpu.opmap1[0x21] = &exec21h;
	cpu.opmap1[0x22] = &exec22h;
	cpu.opmap1[0x23] = &exec23h;
	cpu.opmap1[0x24] = &exec24h;
	cpu.opmap1[0x25] = &exec25h;
	cpu.opmap1[0x26] = &exec26h;
	cpu.opmap1[0x27] = &exec27h;
	cpu.opmap1[0x28] = &exec28h;
	cpu.opmap1[0x29] = &exec29h;
	cpu.opmap1[0x2A] = &exec2Ah;
	cpu.opmap1[0x2B] = &exec2Bh;
	cpu.opmap1[0x2C] = &exec2Ch;
	cpu.opmap1[0x2D] = &exec2Dh;
	cpu.opmap1[0x2E] = &exec2Eh;
	cpu.opmap1[0x2F] = &exec2Fh;
	cpu.opmap1[0x30] = &exec30h;
	cpu.opmap1[0x31] = &exec31h;
	cpu.opmap1[0x32] = &exec32h;
	cpu.opmap1[0x33] = &exec33h;
	cpu.opmap1[0x34] = &exec34h;
	cpu.opmap1[0x35] = &exec35h;
	cpu.opmap1[0x36] = &exec36h;
	cpu.opmap1[0x37] = &exec37h;
	cpu.opmap1[0x38] = &exec38h;
	cpu.opmap1[0x39] = &exec39h;
	cpu.opmap1[0x3A] = &exec3Ah;
	cpu.opmap1[0x3B] = &exec3Bh;
	cpu.opmap1[0x3C] = &exec3Ch;
	cpu.opmap1[0x3D] = &exec3Dh;
	cpu.opmap1[0x3E] = &exec3Eh;
	cpu.opmap1[0x3F] = &exec3Fh;
	cpu.opmap1[0x40] = &exec40h;
	cpu.opmap1[0x41] = &exec41h;
	cpu.opmap1[0x42] = &exec42h;
	cpu.opmap1[0x43] = &exec43h;
	cpu.opmap1[0x44] = &exec44h;
	cpu.opmap1[0x45] = &exec45h;
	cpu.opmap1[0x46] = &exec46h;
	cpu.opmap1[0x47] = &exec47h;
	cpu.opmap1[0x48] = &exec48h;
	cpu.opmap1[0x49] = &exec49h;
	cpu.opmap1[0x4A] = &exec4Ah;
	cpu.opmap1[0x4B] = &exec4Bh;
	cpu.opmap1[0x4C] = &exec4Ch;
	cpu.opmap1[0x4D] = &exec4Dh;
	cpu.opmap1[0x4E] = &exec4Eh;
	cpu.opmap1[0x4F] = &exec4Fh;
	cpu.opmap1[0x50] = &exec50h;
	cpu.opmap1[0x51] = &exec51h;
	cpu.opmap1[0x52] = &exec52h;
	cpu.opmap1[0x53] = &exec53h;
	cpu.opmap1[0x54] = &exec54h;
	cpu.opmap1[0x55] = &exec55h;
	cpu.opmap1[0x56] = &exec56h;
	cpu.opmap1[0x57] = &exec57h;
	cpu.opmap1[0x58] = &exec58h;
	cpu.opmap1[0x59] = &exec59h;
	cpu.opmap1[0x5A] = &exec5Ah;
	cpu.opmap1[0x5B] = &exec5Bh;
	cpu.opmap1[0x5C] = &exec5Ch;
	cpu.opmap1[0x5D] = &exec5Dh;
	cpu.opmap1[0x5E] = &exec5Eh;
	cpu.opmap1[0x5F] = &exec5Fh;
	cpu.opmap1[0x70] = &exec70h;
	cpu.opmap1[0x71] = &exec71h;
	cpu.opmap1[0x72] = &exec72h;
	cpu.opmap1[0x73] = &exec73h;
	cpu.opmap1[0x74] = &exec74h;
	cpu.opmap1[0x75] = &exec75h;
	cpu.opmap1[0x76] = &exec76h;
	cpu.opmap1[0x77] = &exec77h;
	cpu.opmap1[0x78] = &exec78h;
	cpu.opmap1[0x79] = &exec79h;
	cpu.opmap1[0x7A] = &exec7Ah;
	cpu.opmap1[0x7B] = &exec7Bh;
	cpu.opmap1[0x7C] = &exec7Ch;
	cpu.opmap1[0x7D] = &exec7Dh;
	cpu.opmap1[0x7E] = &exec7Eh;
	cpu.opmap1[0x7F] = &exec7Fh;
	cpu.opmap1[0x80] = &exec80h;
	cpu.opmap1[0x81] = &exec81h;
	cpu.opmap1[0x82] = &exec82h;
	cpu.opmap1[0x83] = &exec83h;
	cpu.opmap1[0x84] = &exec84h;
	cpu.opmap1[0x85] = &exec85h;
	cpu.opmap1[0x86] = &exec86h;
	cpu.opmap1[0x87] = &exec87h;
	cpu.opmap1[0x88] = &exec88h;
	cpu.opmap1[0x89] = &exec89h;
	cpu.opmap1[0x8A] = &exec8Ah;
	cpu.opmap1[0x8B] = &exec8Bh;
	cpu.opmap1[0x8C] = &exec8Ch;
	cpu.opmap1[0x8D] = &exec8Dh;
	cpu.opmap1[0x8E] = &exec8Eh;
	cpu.opmap1[0x8F] = &exec8Fh;
	cpu.opmap1[0x90] = &exec90h;
	cpu.opmap1[0x91] = &exec91h;
	cpu.opmap1[0x92] = &exec92h;
	cpu.opmap1[0x93] = &exec93h;
	cpu.opmap1[0x94] = &exec94h;
	cpu.opmap1[0x95] = &exec95h;
	cpu.opmap1[0x96] = &exec96h;
	cpu.opmap1[0x97] = &exec97h;
	cpu.opmap1[0x98] = &exec98h;
	cpu.opmap1[0x99] = &exec99h;
	cpu.opmap1[0x9A] = &exec9Ah;
	cpu.opmap1[0x9B] = &exec9Bh;
	cpu.opmap1[0x9C] = &exec9Ch;
	cpu.opmap1[0x9D] = &exec9Dh;
	cpu.opmap1[0x9E] = &exec9Eh;
	cpu.opmap1[0x9F] = &exec9Fh;
	cpu.opmap1[0xA0] = &execA0h;
	cpu.opmap1[0xA1] = &execA1h;
	cpu.opmap1[0xA2] = &execA2h;
	cpu.opmap1[0xA3] = &execA3h;
	cpu.opmap1[0xA4] = &execA4h;
	cpu.opmap1[0xA5] = &execA5h;
	cpu.opmap1[0xA6] = &execA6h;
	cpu.opmap1[0xA7] = &execA7h;
	cpu.opmap1[0xA8] = &execA8h;
	cpu.opmap1[0xA9] = &execA9h;
	cpu.opmap1[0xAA] = &execAAh;
	cpu.opmap1[0xAB] = &execABh;
	cpu.opmap1[0xAC] = &execACh;
	cpu.opmap1[0xAD] = &execADh;
	cpu.opmap1[0xAE] = &execAEh;
	cpu.opmap1[0xAF] = &execAFh;
	cpu.opmap1[0xB0] = &execB0h;
	cpu.opmap1[0xB1] = &execB1h;
	cpu.opmap1[0xB2] = &execB2h;
	cpu.opmap1[0xB3] = &execB3h;
	cpu.opmap1[0xB4] = &execB4h;
	cpu.opmap1[0xB5] = &execB5h;
	cpu.opmap1[0xB6] = &execB6h;
	cpu.opmap1[0xB7] = &execB7h;
	cpu.opmap1[0xB8] = &execB8h;
	cpu.opmap1[0xB9] = &execB9h;
	cpu.opmap1[0xBA] = &execBAh;
	cpu.opmap1[0xBB] = &execBBh;
	cpu.opmap1[0xBC] = &execBCh;
	cpu.opmap1[0xBD] = &execBDh;
	cpu.opmap1[0xBE] = &execBEh;
	cpu.opmap1[0xBF] = &execBFh;
	cpu.opmap1[0xC2] = &execC2h;
	cpu.opmap1[0xC3] = &execC3h;
	cpu.opmap1[0xC4] = &execC4h;
	cpu.opmap1[0xC5] = &execC5h;
	cpu.opmap1[0xC6] = &execC6h;
	cpu.opmap1[0xC7] = &execC7h;
	cpu.opmap1[0xCA] = &execCAh;
	cpu.opmap1[0xCB] = &execCBh;
	cpu.opmap1[0xCC] = &execCCh;
	cpu.opmap1[0xCD] = &execCDh;
	cpu.opmap1[0xCE] = &execCEh;
	cpu.opmap1[0xCF] = &execCFh;
	cpu.opmap1[0xD0] = &execD0h;
	cpu.opmap1[0xD1] = &execD1h;
	cpu.opmap1[0xD2] = &execD2h;
	cpu.opmap1[0xD3] = &execD3h;
	cpu.opmap1[0xD4] = &execD4h;
	cpu.opmap1[0xD5] = &execD5h;
	cpu.opmap1[0xD7] = &execD7h;
	cpu.opmap1[0xE0] = &execE0h;
	cpu.opmap1[0xE1] = &execE1h;
	cpu.opmap1[0xE2] = &execE2h;
	cpu.opmap1[0xE3] = &execE3h;
	cpu.opmap1[0xE4] = &execE4h;
	cpu.opmap1[0xE5] = &execE5h;
	cpu.opmap1[0xE6] = &execE6h;
	cpu.opmap1[0xE7] = &execE7h;
	cpu.opmap1[0xE8] = &execE8h;
	cpu.opmap1[0xE9] = &execE9h;
	cpu.opmap1[0xEA] = &execEAh;
	cpu.opmap1[0xEB] = &execEBh;
	cpu.opmap1[0xEC] = &execECh;
	cpu.opmap1[0xED] = &execEDh;
	cpu.opmap1[0xEE] = &execEEh;
	cpu.opmap1[0xEF] = &execEFh;
	cpu.opmap1[0xF0] = &execF0h;
	cpu.opmap1[0xF2] = &execF2h;
	cpu.opmap1[0xF3] = &execF3h;
	cpu.opmap1[0xF4] = &execF4h;
	cpu.opmap1[0xF5] = &execF5h;
	cpu.opmap1[0xF6] = &execF6h;
	cpu.opmap1[0xF7] = &execF7h;
	cpu.opmap1[0xF8] = &execF8h;
	cpu.opmap1[0xF9] = &execF9h;
	cpu.opmap1[0xFA] = &execFAh;
	cpu.opmap1[0xFB] = &execFBh;
	cpu.opmap1[0xFC] = &execFCh;
	cpu.opmap1[0xFD] = &execFDh;
	cpu.opmap1[0xFE] = &execFEh;
	cpu.opmap1[0xFF] = &execFFh;
	cpu.opmap1[0xD6] = &execill;
	switch (cpu.model) {
	case CPU_8086:
		cpu.opmap1[0xC8] =
		cpu.opmap1[0xC9] =
		cpu.opmap1[0x0F] = // Two-byte map
		cpu.opmap1[0xC0] =
		cpu.opmap1[0xC1] =
		cpu.opmap1[0xD8] =
		cpu.opmap1[0xD9] =
		cpu.opmap1[0xDA] =
		cpu.opmap1[0xDB] =
		cpu.opmap1[0xDC] =
		cpu.opmap1[0xDD] =
		cpu.opmap1[0xDE] =
		cpu.opmap1[0xDF] =
		cpu.opmap1[0xF1] = &execill;
		// While it is possible to map a range, range sets rely on
		// memset32/64 which DMD linkers will not find
		for (size_t i = 0x60; i < 0x70; ++i)
			cpu.opmap1[i] = &execill;
		break;
	case CPU_80486:
		cpu.opmap1[0x60] =
		cpu.opmap1[0x61] =
		cpu.opmap1[0x62] =
		cpu.opmap1[0x63] =
		cpu.opmap1[0x64] =
		cpu.opmap1[0x65] =
		cpu.opmap1[0x68] =
		cpu.opmap1[0x69] =
		cpu.opmap1[0x6A] =
		cpu.opmap1[0x6B] =
		cpu.opmap1[0x6C] =
		cpu.opmap1[0x6D] =
		cpu.opmap1[0x6E] =
		cpu.opmap1[0x6F] = &execill;
		cpu.opmap1[0x66] = &exec66;
		cpu.opmap1[0x67] = &exec67;
		break;
	default:
	}

	for (size_t i; i < 256; ++i) { // Sanity checker
		assert(cpu.opmap1[i], "");
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
	cpu.segov = SegReg.None;

	cpu.FLAG.u32 = 2;
	cpu.EIP.u32 = 0;
	cpu.segs[SegReg.DS] = cpu.segs[SegReg.SS] = cpu.segs[SegReg.ES] = 0;
	cpu.segs[SegReg.CS] = 0xFFFF;
}

/// Push a value into memory
void cpupush16(cpu_t *cpu, int v) {
	import vcpu.mm;
	uint addr = void;
	with (CPUMode)
	switch (cpu.opmode) {
	case Real:
		if (cpu.model == CPUModel.i8086) {
			cpu.gregs.SP -= 2;
			addr = cpuaddress(cpu.sregs.SS, cpu.gregs.SP);
		} else {
			addr = cpuaddress(cpu.sregs.SS, cpu.gregs.SP);
			cpu.gregs.SP -= 2;
		}
		mmsu16(cpu, addr, &v);
		break;
	case Protected:
	
		break;
	default:
	}
}
void cpupush32(cpu_t *cpu, int v) {
	
}
ushort cpupop16(cpu_t *cpu) {
	import vcpu.mm;
	int v = void;
	uint addr = void;
	with (CPUMode)
	switch (cpu.opmode) {
	case Real:
		addr = cpuaddress(cpu.sregs.SS, cpu.gregs.SP);
		cpu.gregs.SP += 2;
		if (mmgu16(cpu, addr, &v))
			return 0;
		break;
	case Protected:
	
		break;
	default:
	}
	return cast(ushort)v;
}
/*uint cpupop32(cpu_t *cpu) {
}*/

uint cpuaddress(int s, int a) {
	return (s << 4) | a;
}

/// Get the value of a segment register. If the segment override is set to
/// None, the specified default segment value is returned.
/// Params: cpu = cpu_t structure
ushort cpuseg(cpu_t *cpu, SegReg def) {
	if (cpu.segov == SegReg.None)
		return cpu.segs[def];
	else
		return cpu.segs[cpu.segov];
}

//
// CPU flagging operations
//

enum { // FLAG[31:24] is unused, so use it to put our flags in there
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
	//TODO: PF, AF, etc.
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
			if (val & 0x1_0000) {
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
