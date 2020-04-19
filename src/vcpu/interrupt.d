module vcpu.interrupt;

import vcpu.cpu;

enum Vector {
	// Intel: 0-15
	DE, DB, NMI, BP, OF, BR, UD, NM, DF, TS, NP, SS, GP, PF, Res,
	// Intel: 16-18
	MF, AC, MC,
	// IBM: 8-15
	IRQ0 = 8,
	IRQ1 = 9,
	IRQ3 = COM2,
	IRQ4 = COM1,
	IRQ5 = Disk,
	IRQ6 = Floppy,
	IRQ7 = Printer,
	COM2    = 0xB,
	COM1    = 0xC,
	Disk    = 0xD,
	Floppy  = 0xE,
	Printer = 0xF
}

void interrupt(cpu_t *cpu, int vector) {
	//TODO: Check if IBM/DOS/MS-DOS service first
}