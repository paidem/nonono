// Embeds the clips from ../../sounds via the assembler's .incbin, so the
// release binary is self-contained. The directory is on the include path
// (Package.swift headerSearchPath), which the integrated assembler searches.
#include "csounds.h"

__asm__(
    ".section __TEXT,__const\n"
    ".p2align 4\n"
    "_nonono_wait_start:\n"
    ".incbin \"no-no-wait-wait.mp3\"\n"
    "_nonono_wait_end:\n"
    ".p2align 4\n"
    "_nonono_phew_start:\n"
    ".incbin \"luigi-phew-mamma-mia.mp3\"\n"
    "_nonono_phew_end:\n"
    ".p2align 4\n"
    "_nonono_violin_start:\n"
    ".incbin \"sad-violin-the-meme-one.mp3\"\n"
    "_nonono_violin_end:\n"
);

extern const unsigned char nonono_wait_start[], nonono_wait_end[];
extern const unsigned char nonono_phew_start[], nonono_phew_end[];
extern const unsigned char nonono_violin_start[], nonono_violin_end[];

const unsigned char *nonono_wait_mp3(void) { return nonono_wait_start; }
size_t nonono_wait_mp3_len(void) { return (size_t)(nonono_wait_end - nonono_wait_start); }
const unsigned char *nonono_phew_mp3(void) { return nonono_phew_start; }
size_t nonono_phew_mp3_len(void) { return (size_t)(nonono_phew_end - nonono_phew_start); }
const unsigned char *nonono_violin_mp3(void) { return nonono_violin_start; }
size_t nonono_violin_mp3_len(void) { return (size_t)(nonono_violin_end - nonono_violin_start); }
