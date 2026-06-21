---
name: perl-sv-magic-memory
description: "Use when changing Perl SV/AV/HV/CV internals, refcounts, mortals, magic/vtables, save stack, arenas, allocation macros, or memory ownership."
---

# Perl SV, Magic, and Memory

Treat object lifetime, flags, magic callbacks, and ownership as compatibility-sensitive. Read nearby patterns before changing refcount or save-stack behavior.

## Workflow

1. Identify the concrete value type, owner, and lifetime boundary.
2. Check flags, magic, copy-on-write, weak reference, and tied/overloaded behavior before simplifying.
3. Keep allocation and free paths paired with the established `Newx`/`Safefree`, arena, or stack discipline.
4. Add leak, magic, tie, thread, or XS/API coverage when the change crosses those surfaces.
5. Route symbol exposure or API documentation changes through `perl-embed-fnc`.

Read [references/sv-magic-memory.md](references/sv-magic-memory.md) for files, risk checks, test targets, and useful searches.
