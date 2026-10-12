---
name: quality-audit
description: Whole-project quality sweep for Lavadero — design-system consistency (colors/spacing/typography/reusable widgets), SOLID/clean-code/architecture drift, and performance, across the whole repo rather than just the current diff. Use when asked to audit code quality, check design-system consistency, verify conventions/SOLID/clean-code project-wide, or review performance.
---

# Lavadero — project-wide quality audit

This is a full-repo sweep, not a diff review. It exists because `architecture-guardian`,
`flutter-reviewer`, and `rls-guardian` are written to review *what changed* — they are the right
tool once you know where to look, but nothing runs them over the whole tree at once. This skill
does the sweep and tells you where to point them next.

Read `CLAUDE.md` first — it's the index of non-negotiable conventions this audit checks against.
Don't re-derive conventions from scratch; every check below cites the file that already states the
rule.

## 1. Design system sweep (Flutter: `admin_web/`, `mobile_app/`, `packages/lavadero_core/`)

Source of truth: `packages/lavadero_core/lib/src/theme/design_tokens.dart` +
`lavadero_theme.dart`, and the shared widgets in `packages/lavadero_core/lib/src/widgets/`
(`EmptyState`, `StatusBadge`, `ErrorBanner`, `LoadingButton`).

Run each of these from the repo root; a real hit is a finding, not a nitpick:

```bash
# Hardcoded colors bypassing the palette
grep -rn "Color(0x" mobile_app/lib admin_web/lib packages/lavadero_core/lib | grep -v design_tokens.dart
grep -rn "Colors\.\(red\|green\|blue\|orange\|grey\|black\|white\)" mobile_app/lib admin_web/lib packages/lavadero_core/lib

# Magic-number spacing/radii instead of LavaderoSpacing/LavaderoRadii
grep -rEn "EdgeInsets\.(all|symmetric|only)\([^)]*[0-9]+\.?[0-9]*\)" mobile_app/lib admin_web/lib | grep -v LavaderoSpacing
grep -rn "BorderRadius.circular(" mobile_app/lib admin_web/lib packages/lavadero_core/lib | grep -v "lavadero_theme.dart\|design_tokens.dart\|LavaderoRadii"

# Hardcoded typography instead of Theme.of(context).textTheme
grep -rn "TextStyle(fontSize:" mobile_app/lib admin_web/lib packages/lavadero_core/lib

# Explicit input border overriding the global InputDecorationTheme (a shipped regression once —
# see architecture-guardian's SOLID/LSP section for the Wompi analogue of "implementation drifts
# from the shared contract")
grep -rn "border: OutlineInputBorder()" mobile_app/lib admin_web/lib

# Ad-hoc empty-state text that should be EmptyState (verify each hit is really a "list has zero
# items" case, not an unrelated string before flagging)
grep -rln "Todavía no hay\|No hay \|No se encontraron" mobile_app/lib admin_web/lib | xargs grep -L "EmptyState"
```

For anything found: cite the screen that already does it right (e.g. `branches_screen.dart` for
dialogs, `agenda_screen.dart` for empty states) as the fix template, don't just say "use the
theme".

## 2. SOLID / clean-code / architecture drift (backend: `backend/modules/*`)

```bash
# God-class candidates — this codebase's files are consistently small (~100-170 lines); a big
# outlier is a signal, not proof
find backend/modules -name "*.java" -path "*/main/*" | xargs wc -l | sort -rn | head -20

# Read use cases missing @Transactional(readOnly = true)
for f in $(grep -rl "class Listar\|class Buscar\|class Obtener" backend/modules/*/src/main/java --include="*.java"); do
  grep -q "@Transactional(readOnly = true)" "$f" || echo "MISSING readOnly: $f"
done

# application importing infrastructure directly (DIP violation)
grep -rln "infrastructure\." backend/modules/*/src/main/java/*/application --include="*.java"

# domain importing Spring/JPA (layering violation — ArchUnit should already catch this, but check)
grep -rln "org.springframework\|jakarta.persistence" backend/modules/*/src/main/java/*/domain --include="*.java"
```

Then run the ArchUnit suite for a definitive answer rather than trusting grep alone:
`cd backend && JAVA_HOME=$(brew --prefix openjdk@21)/libexec/openjdk.jdk/Contents/Home ./gradlew :architecture-tests:test`.

Map any real finding to the specific SOLID letter using `architecture-guardian`'s "SOLID, named
explicitly" section — don't report a bare "violates SOLID".

## 3. Performance

Backend:

```bash
# FK/lookup columns without a matching index (cross-check manually — grep can't join these two lists)
grep -rn "_id uuid\|_id uuid not null" backend/modules/*/src/main/resources/db/migration/*.sql
grep -rn "create index" backend/modules/*/src/main/resources/db/migration/*.sql

# Loops that could be N+1s (a repository call inside a for/forEach/map over a collection)
grep -rn "for (\|forEach\|\.map(" backend/modules/*/src/main/java --include="*UseCase.java" | grep -i "findById\|Repository\."

# Unpaginated list endpoints (acceptable at this project's declared scale per docs/adr/0001 —
# note as a scale ceiling, not an urgent fix, unless a specific query is known to return
# unbounded rows like an audit log)
grep -rln "List<.*Response>\|List<.*Dto>" backend/modules/*/src/main/java/*/interfaces/rest/*Controller.java
```

Flutter:

```bash
# StatelessWidget/leaf widgets that could be const but aren't (spot-check, this is noisy — only
# report clear, cheap wins)
grep -rn "return Card(\|return Container(\|return Padding(" mobile_app/lib admin_web/lib | grep -v "const "

# Network calls inside build() instead of a controller method
grep -rn "\.read(.*Provider).*\.\(listar\|obtener\|buscar\|cargar\)" mobile_app/lib admin_web/lib | grep -B2 "Widget build"
```

## Reporting

One consolidated report, findings ranked: security/correctness > architecture-boundary violations
> performance > design-system/style. For each finding: file:line, what's wrong, why it matters
*in this codebase* (cite the convention file it deviates from — `CLAUDE.md`, an ADR, or an
existing correct example), and the concrete fix.

If a section turns up nothing, say so in one line and move on — this project (as of the last
audit pass) is unusually disciplined about its own conventions; don't manufacture nitpicks to
look thorough. If a finding is squarely inside one specialist's territory (a new migration's RLS
shape, a single changed Dart file's Riverpod pattern), delegate to `rls-guardian` /
`flutter-reviewer` / `architecture-guardian` instead of re-deriving their checklist here.
