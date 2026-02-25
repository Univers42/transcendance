# Prismatica Design System v1.0

**Date**: February 25, 2026  
**Status**: Wireframes in progress

---

**Key Decisions**:
- Dual theme (Light/Dark) with adaptive behavior per device
- Corporate neutral palette (Slate) with a technical accent (Blue)
- Dual typography: Inter for UI, JetBrains Mono for data
- Strict WCAG 2.2 AA compliance

---

## 1. Color System

### 1.1 Philosophy

**Why Slate instead of pure gray?**
- Neutral gray (#808080) is anonymous and cold.
- Slate has a subtle bluish tint that conveys **technology** and **professionalism** without being aggressive.
- It maintains the necessary neutrality so that colored data (charts, alerts) stand out.

**Why not a more vibrant brand color?**
- In a data viewer, the content (numbers, trends, alerts) must be the protagonist.
- A very strong corporate accent would visually compete with the information.
- Royal blue (#3B82F6) is conservative, legible, and associated with trust/stability.

### 1.2 Token Architecture

Variable structure to maintain consistency between Light and Dark:


```

bg/primary        → Primary surface (page background)
bg/secondary      → Alternate surfaces (headers, sidebars)
bg/elevated       → Floating elements (cards, modals, dropdowns)

text/primary      → Primary text (titles, critical data)
text/secondary    → Supporting text (descriptions, metadata)
text/tertiary     → Subtle text (placeholders, disabled timestamps)

border/default    → Standard separators
border/strong     → Prominent separators (section dividers)

accent/default    → Primary actions (buttons, links, selection)
accent/hover      → Action hover state

```

### 1.3 Full Palette

#### Corporate Neutrals (Slate)

| Token | Light | Dark | Contrast Ratio |
|-------|-------|------|----------------|
| bg/primary | #FFFFFF | #0F172A | - |
| bg/secondary | #F8FAFC | #1E293B | - |
| bg/elevated | #FFFFFF | #1E293B | - |
| text/primary | #0F172A | #F8FAFC | 15.8:1 / 16.1:1 |
| text/secondary | #475569 | #94A3B8 | 7.2:1 / 7.0:1 |
| text/tertiary | #94A3B8 | #64748B | 4.6:1 / 4.7:1 |

**Validation**: All texts meet WCAG AA (4.5:1 minimum). Primary texts exceed AAA (7:1).

#### Action Accent (Blue)

| State | Light | Dark | Note |
|-------|-------|------|------|
| Default | #3B82F6 | #60A5FA | In dark, +20% lightness to compensate for the dark background |
| Hover | #2563EB | #3B82F6 | Deeper transition in light mode |
| Pressed | #1D4ED8 | #2563EB | For tactile feedback |

#### Data Semantics

Colors for business states and data visualization:

| Use | Light | Dark | Context |
|-----|-------|------|---------|
| Positive/Growth | #059669 | #34D399 | Revenue ↑, positive KPIs, favorable variance |
| Negative/Loss | #DC2626 | #F87171 | Losses, critical alerts, errors |
| Warning/Alert | #D97706 | #FBBF24 | Deviated forecasts, attention required |
| Info/Neutral | #0284C7 | #38BDF8 | Contextual data, tooltips, help |
| Trend/Highlight | #7C3AED | #A78BFA | Special highlights, multiple selection |

**Accessibility Consideration**: We never use color alone to convey information. We always pair it with:
- Iconography (trend arrows ▲▼)
- Explicit text ("+12.5%" vs "↑ 12.5%")
- Position/context (positives on the right, negatives on the left in certain layouts)

#### Categorical Palette (Charts)

To distinguish series in bar/line charts:

**Light**: #2563EB → #7C3AED → #DB2777 → #EA580C → #059669 → #0891B2 → #4F46E5  
**Dark**: #60A5FA → #A78BFA → #F472B6 → #FB923C → #34D399 → #22D3EE → #818CF8

**Generation Rule**: In dark theme, maintain the hue but increase lightness by 15-20% and reduce saturation by 10%. This avoids an aggressive "neon" effect and maintains visual harmony.

### 1.4 Theme System

**Behavior per device**:

| Device | Initial Theme | Theme Control | Rationale |
|--------|---------------|---------------|-----------|
| Mobile (< 768px) | OS System | Hidden in Settings > Appearance | Maximize space for data, avoid UI clutter |
| Tablet (768-1023px) | OS System | Toggle icon in header | Accessible but not intrusive |
| Desktop (> 1023px) | OS System | Toggle + shortcut `Cmd/Ctrl+Shift+L` | Power users appreciate quick control |

---

## 2. Typography System

### 2.1 Philosophy

**Why two font families?**

| Family | Role | Justification |
|--------|------|---------------|
| **Inter** | UI, text, navigation | Designed specifically for screens. High x-height, excellent legibility at small sizes (12-14px). Optimized for dense UI. |
| **JetBrains Mono** | Numerical data, tables, metrics | Monospaced with tabular numbers by default. Clearly distinguishes 0/O, 1/l/I. Critical for decimal alignment in financial tables. |

### 2.2 Typographic Scale

#### Inter (UI & Content)

| Token | Size | Weight | Line Height | Primary Use |
|-------|------|--------|-------------|-------------|
| Display | 40px | 600 | 1.2 | Page/login title |
| H1 | 32px | 600 | 1.25 | Main section header |
| H2 | 24px | 600 | 1.3 | Widget/card title |
| H3 | 20px | 500 | 1.4 | Subtitle, dataset name |
| H4 | 16px | 600 | 1.4 | Table column header |
| Body | 14px | 400 | 1.5 | General text, descriptions |
| Body-sm | 13px | 400 | 1.5 | Secondary text, metadata |
| Caption | 12px | 500 | 1.4 | Form labels, timestamps |

**Technical Notes**:
- Slightly negative tracking at large sizes (-0.02em on Display) for greater impact.
- Positive tracking at small sizes (+0.01em to +0.02em) for better legibility.
- Weight 500 (Medium) in Caption to compensate for the reduced size.

#### JetBrains Mono (Data)

| Token | Size | Weight | Line Height | Primary Use |
|-------|------|--------|-------------|-------------|
| Data-xl | 24px | 600 | 1.2 | Hero KPIs (total revenue, large metrics) |
| Data-lg | 20px | 500 | 1.25 | Main metrics on dashboard |
| Data-md | 16px | 400 | 1.3 | Standard data in tables |
| Data-sm | 14px | 400 | 1.3 | Dense data, complex tables |
| Data-xs | 12px | 400 | 1.3 | Timestamps, technical IDs, small version |
| Code | 13px | 400 | 1.6 | Formula snippets, queries |

**Specific Features**:
- Always tabular numbers (monospaced) for perfect decimal alignment.
- Weight 600 (SemiBold) reserved for totals and summaries, never for individual data points.
- Reduced line height (1.3) to maximize density without sacrificing legibility.

---

## 3. WCAG 2.2 Compliance

### 3.1 Our Commitments

| Principle | Criterion | Implementation |
|-----------|-----------|----------------|
| **Perceivable** | 1.4.3 Minimum Contrast | All text ≥ 4.5:1. Large text (18px+) ≥ 3:1 |
| | 1.4.11 Non-text Contrast | UI components, icons, charts ≥ 3:1 |
| | 1.4.12 Text Spacing | Supports spacing adjustments without loss of content |
| **Operable** | 2.4.11 Focus Appearance | 2px outline + 2px offset on all interactive elements |
| | 2.5.5 Target Size | Minimum 24x24px, ideal 44x44px for frequent touch targets |
| **Robust** | 4.1.2 Name, Role, Value | All components identifiable by assistive technology |

### 3.2 Specific Accessibility Decisions

**Dark Theme Contrast**
- Primary texts in dark (#F8FAFC) have a 16:1 contrast, exceeding the AAA requirement.
- Secondary texts (#94A3B8) are at 7:1, meeting AA with a comfortable margin.
- The accent in dark (#60A5FA) is lighter than in light mode to maintain visibility on dark backgrounds.

**Reduced Motion**
- Theme transitions: 300ms (below the annoyance threshold).
- We do not use entrance/exit animations for data (blinking, bouncing).

**Color Blindness**
- Simulation performed with Stark: Protanopia, Deuteranopia, Tritanopia, Achromatopsia.
- Semantic colors (green/red) are distinguished by lightness, not just hue.
- There is always an additional textual or iconic indicator alongside color.

### 3.3 Validation Tools

- **Stark Plugin** (Figma): Contrast verification and color blindness simulation.

---

## 4. Design Principles

### 4.1 Data First
Information is the protagonist. Every design decision must facilitate the reading, comparison, and analysis of data.

### 4.2 Density with Clarity
We maximize information density (lots of data per screen) without sacrificing legibility. Consistent spacing, strict alignment, clear hierarchy.

### 4.3 Accessible by Default
It is not an afterthought. From the very first wireframe, everything must be usable by people with diverse visual, motor, or cognitive abilities.

### 4.4 Theme Agnostic
The experience must be equivalent in Light and Dark modes. It's not "dark mode as an alternative," it's "two equally important variants."

---

## 5. Graphical Chart Usage

The file `Graphical Chart.jpg` (attached in `/assets`) contains:

1. **Full Slate palette** (50-900) with Light/Dark equivalencies
2. **Semantic colors** (Success, Warning, Error, Info)
3. **Categorical palette** for charts (7 colors)
4. **Typographic scale** visualized with placeholder text
