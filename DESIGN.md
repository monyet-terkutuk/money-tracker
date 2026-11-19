# DESIGN.md — Catat Uang

## Aesthetic Direction
**Swiss-Editorial Private Ledger**: Inspired by private-banking statements, Monocle financial print, and Leica/Montblanc hardware minimalism. High-contrast ink on warm limestone paper (light) or matte carbon (dark), anchored by sharp architectural radii and hairline rules instead of bubbly neobank cards.

## Color System (Strict 2 Core + 1 Accent)
- **Light Mode**:
  - Ground: `#F4F1EA` (Warm Limestone)
  - Surface: `#FCFBF8` (Ledger Paper)
  - Primary Ink: `#141413` (Charcoal Ink)
  - Secondary Ink: `#6B6860` (Muted Stone)
  - Border / Rule: `#DFDBD0` (Hairline Rule)
  - Accent: `#A67C37` (Burnished Brass — reserved for focal rules and primary highlights)
- **Dark Mode**:
  - Ground: `#0E0E0D` (Matte Carbon)
  - Surface: `#161614` (Elevated Slate)
  - Primary Ink: `#F2EFE9` (Warm Ivory)
  - Secondary Ink: `#9A968C` (Stone Grey)
  - Border / Rule: `#292824` (Dark Hairline)
  - Accent: `#C8A055` (Burnished Brass)
- **Semantic**:
  - Income: `#166534` (Light) / `#4ADE80` (Dark)
  - Expense: `#991B1B` (Light) / `#F87171` (Dark)

## Geometry & Elevation Rules (Anti-Slop)
- **Radii**: `16px` for primary statement/modal containers, `10px` for inputs and buttons, `4px` for micro-tags. No uniform `24px+` bubbly pills everywhere.
- **Shadows**: Flat by default. Hairline `1px` borders define hierarchy; only the primary statement slab and modal sheets carry subtle elevation.
- **No Slop**: Zero blurred radial glow orbs, zero 4-column copy-paste icon grids, zero decorative status dots, zero hollow marketing taglines.
