.segment "HEADER"

h_PRG_ROM_SIZE		= 4			; PRG-ROM size in 16k banks
h_CHR_ROM_SIZE		= 0			; CHR-ROM size in 8k banks
h_MAPPER			= 28		; Mapper number
h_MIRRORING			= 1			; Mirroring (Vertical = 1)
h_FOUR_SCREEN		= 0			; Four screen vram
h_BATTERY			= 0			; Non-volatile memory present?
h_SUBMAPPER			= 0			; Submapper
h_PRG_RAM_SIZE		= 0			; PRG-RAM size (64 * 2^n)
h_PRG_NVRAM_SIZE	= 0			; Non-volatile PRG-RAM size (64 * 2^n)
h_CHR_RAM_SIZE		= 9			; CHR-RAM size (64 * 2^n)
h_CHR_NVRAM_SIZE	= 0			; Non_volatile CHR-RAM size (64 * 2^n)
h_CONSOLE_TYPE		= 0			; 0 = NES/Famicom, 1 = Vs. System, 2 = Playchoice 10, 3 = Extended Console Type
h_EXTENDED_CONSOLE	= 0			;
h_CONSOLE_REGION	= 0			; 0 = NTSC, 1 = PAL, 2 = Multi-region, 3 = Dendy
h_MISC_ROMS			= 0			;
h_DEFAULT_EXPANSION	= 0			; 

.byte	"NES",$1A
.byte	h_PRG_ROM_SIZE & $FF
.byte	h_CHR_ROM_SIZE & $FF
.byte	((h_MAPPER & $0F) << 4) | (h_FOUR_SCREEN << 3) | (h_BATTERY << 1) | (h_MIRRORING)
.byte	(h_MAPPER & $F0) | (h_CONSOLE_TYPE) | %1000
.byte	(h_SUBMAPPER << 4) | ((h_MAPPER & $F00) >> 8)
.byte	((h_PRG_ROM_SIZE & $F00) >> 4) | ((h_CHR_ROM_SIZE & $F00) >> 8)
.byte	(h_PRG_NVRAM_SIZE << 4) | (h_PRG_RAM_SIZE)
.byte	(h_CHR_NVRAM_SIZE << 4) | (h_CHR_RAM_SIZE)
.byte	h_CONSOLE_REGION
.byte	h_EXTENDED_CONSOLE
.byte	h_MISC_ROMS
.byte	h_DEFAULT_EXPANSION