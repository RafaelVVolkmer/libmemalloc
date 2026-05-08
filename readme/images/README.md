<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

---

# Image Guide

## Overview

This document defines the visual system for the **libmemalloc** penguin mascot and related illustrations.
It includes:

- the selected Lospec palette
- the color mapping for each visual element
- the typography recommendation

---

## Selected Palette

**Palette:** [Endesga 32](https://lospec.com/palette-list/endesga-32)
**Author:** ENDESGA

This palette was selected because it provides a cohesive set of:

- cool blues for clothing and branding
- purple tones for secondary accents
- clean neutrals for outlines and body shading
- warm oranges/yellows for beak and feet
- bright cyan for magical/code accents

---

## Typography

### Primary Font

Nunito Sans Bold

### Why this font

Nunito Sans Bold works well with the mascot style because it is:

- rounded
- friendly
- modern
- highly legible
- compatible with a soft cartoon / tech-brand aesthetic

### Recommended Use

- Main wordmark / logo text
- Short labels
- Headings in brand-support graphics
- Captions near mascot illustrations

### Suggested Fallbacks

If Nunito Sans is unavailable, use:

1. **Nunito Sans SemiBold / ExtraBold**
2. **Montserrat Rounded**
3. **Arial Rounded MT Bold**
4. any **rounded geometric sans-serif** with a soft and friendly look

---

## Color Application by Element

All colors below are chosen from or aligned to the selected **Endesga 32** palette.

### Mascot / Illustration Colors

| Element                           | Hex Color | Notes                                                      |
| --------------------------------- | --------- | ---------------------------------------------------------- |
| Main penguin outfit               | `#124E89` | Primary blue for robe, wizard hat, and main clothing areas |
| Main outfit shadow                | `#3A4466` | Darker cool shadow for robe and hat depth                  |
| Secondary outfit accent           | `#68386C` | Secondary purple accent when variation is needed           |
| Secondary accent shadow           | `#3E2731` | Deep shadow for purple secondary elements                  |
| Outline                           | `#181425` | Main outline color; use for strong shape definition        |
| Dark penguin skin / body          | `#262B44` | Penguin body dark area                                     |
| Light penguin skin / belly / face | `#FFFFFF` | Main white body area                                       |
| Light skin shadow                 | `#C0CBDC` | Soft shadow for white body areas                           |
| Beak and feet                     | `#FEAE34` | Main warm accent                                           |
| Beak and feet shadow              | `#D77643` | Warm shadow tone                                           |
| Eyes                              | `#181425` | Same family as outline for cohesion                        |
| Book cover                        | `#3A4466` | Main cover color                                           |
| Book pages                        | `#EAD4AA` | Slightly warm paper tone                                   |
| Book lettering / symbol           | `#2CE8F5` | Bright magical cyan accent                                 |
| Binary digits / magical code      | `#2CE8F5` | Use as luminous visual accent                              |

### Text / Wordmark Colors

| Text Element            | Hex Color | Notes                      |
| ----------------------- | --------- | -------------------------- |
| Top line text           | `#5A6988` | Neutral cool gray-blue     |
| Bottom line text        | `#124E89` | Main brand blue            |
| Optional highlight text | `#2CE8F5` | Use sparingly for emphasis |

---

## Recommended Visual Rules

### General Style

Use a **clean flat-cartoon vector look** with:

- thick outlines
- soft rounded shapes
- minimal but clear shading
- simple lighting
- plain fills
- no heavy textures
- no painterly rendering
- no photorealism

### Shading Rules

- Use **1 main fill + 1 shadow tone** for most elements
- Keep shading clean and graphic
- Avoid gradients when possible
- Avoid noisy airbrush effects
- Prefer solid color blocks with crisp separation

### Character Rules

- Penguin should be cute, compact, and friendly
- Body proportions should stay rounded and readable
- Eyes should be large and expressive
- Pose should remain simple and iconic
- Expressions should be easy to read at small sizes

### Brand Style Rules

- Friendly open-source mascot feel
- Tech-meets-magic visual concept
- Book, code bits, scrolls, stars, or small magical symbols are acceptable support elements
- Keep compositions clean enough for README, docs, and logo-adjacent graphics

---

## Quick Style Block

```text
Palette: Endesga 32
Palette link: https://lospec.com/palette-list/endesga-32
Primary font: Nunito Sans Bold

Main outfit: #124E89
Main outfit shadow: #3A4466
Secondary accent: #68386C
Secondary accent shadow: #3E2731
Outline: #181425
Dark body: #262B44
Light body: #FFFFFF
Light body shadow: #C0CBDC
Beak and feet: #FEAE34
Beak and feet shadow: #D77643
Book cover: #3A4466
Book pages: #EAD4AA
Book symbol / code accent: #2CE8F5
Top text: #5A6988
Bottom text: #124E89
```

<!-- EOF -->
