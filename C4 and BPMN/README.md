# C4 & BPMN Editor

Edytor diagramów w notacji **C4** i **BPMN** w przeglądarce.

## Stack

- Vite + React + TypeScript
- [@xyflow/react](https://reactflow.dev) (React Flow) — silnik płótna
- Zustand — stan diagramu (węzły, krawędzie, tryb, historia undo/redo)
- Tailwind CSS v4 — UI
- html-to-image — eksport PNG/SVG

## Uruchomienie

```bash
npm install
npm run dev      # http://localhost:5173
npm run build    # build produkcyjny + typecheck
```

## Funkcje

- **Przełącznik trybu C4 / BPMN** — zmienia dostępną paletę
- **Drag & drop** elementów z palety na płótno
- **Łączenie** węzłów strzałkami (handle na 4 bokach, tryb loose), etykiety na strzałkach
- **Edycja tekstu** — dwuklik w węźle (inline) lub panel Inspektora po prawej
- **Usuwanie** — Delete / Backspace
- **Undo / Redo** — Ctrl+Z / Ctrl+Y (lub Ctrl+Shift+Z)
- **Zapis** — autozapis do localStorage + eksport/import JSON
- **Eksport** widoku do PNG i SVG
- Zoom / pan, minimapa, kontrolki (natywne React Flow)

### Elementy C4

Person, Software System, Container, Component — każdy z polami **Nazwa**, **Opis**,
a Container/Component dodatkowo **Technologia**.

### Elementy BPMN

Start Event (zielone kółko), End Event (czerwone, pogrubione), Task (zaokrąglony
prostokąt), Gateway XOR (romb z ✕).

## Struktura

```
src/
  nodes/        komponenty węzłów (C4*.tsx, Bpmn*.tsx) + rejestr + metadane palety
  store/        zustand store (diagram, historia, persistencja)
  components/   Toolbar, Palette, Canvas, Inspector
  utils/        export.ts (PNG/SVG/JSON, import)
  types.ts      typy domeny
```
