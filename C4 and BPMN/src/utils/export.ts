import { toPng, toSvg } from 'html-to-image';
import { getNodesBounds, getViewportForBounds } from '@xyflow/react';
import type { Node, Edge } from '@xyflow/react';
import type { DiagramSnapshot } from '../types';

const PADDING = 40;

function downloadDataUrl(dataUrl: string, filename: string) {
  const a = document.createElement('a');
  a.href = dataUrl;
  a.download = filename;
  a.click();
}

function viewportElement(): HTMLElement | null {
  return document.querySelector('.react-flow__viewport');
}

/**
 * Wymiary i transform tła pod eksport — dopasowanie do bounding boxu węzłów.
 */
function exportConfig(nodes: Node[]) {
  const bounds = getNodesBounds(nodes);
  const width = Math.max(bounds.width + PADDING * 2, 200);
  const height = Math.max(bounds.height + PADDING * 2, 200);
  const viewport = getViewportForBounds(bounds, width, height, 0.5, 2, PADDING);
  return { width, height, viewport };
}

async function renderImage(
  nodes: Node[],
  renderer: typeof toPng | typeof toSvg,
  background?: string
): Promise<string | null> {
  const el = viewportElement();
  if (!el || nodes.length === 0) return null;
  const { width, height, viewport } = exportConfig(nodes);
  return renderer(el, {
    backgroundColor: background,
    width,
    height,
    style: {
      width: `${width}px`,
      height: `${height}px`,
      transform: `translate(${viewport.x}px, ${viewport.y}px) scale(${viewport.zoom})`,
    },
    filter: (node) => {
      const cn = (node as HTMLElement)?.classList;
      if (!cn) return true;
      // Pomijamy kontrolki, minimapę i tło z kropkami.
      return !(
        cn.contains('react-flow__controls') ||
        cn.contains('react-flow__minimap') ||
        cn.contains('react-flow__background') ||
        cn.contains('react-flow__panel')
      );
    },
  });
}

export async function exportToPng(nodes: Node[]) {
  const url = await renderImage(nodes, toPng, '#ffffff');
  if (url) downloadDataUrl(url, 'diagram.png');
}

export async function exportToSvg(nodes: Node[]) {
  const url = await renderImage(nodes, toSvg);
  if (url) downloadDataUrl(url, 'diagram.svg');
}

export function exportToJson(snapshot: DiagramSnapshot) {
  const blob = new Blob([JSON.stringify(snapshot, null, 2)], {
    type: 'application/json',
  });
  const url = URL.createObjectURL(blob);
  downloadDataUrl(url, 'diagram.json');
  setTimeout(() => URL.revokeObjectURL(url), 1000);
}

export function importFromJson(file: File): Promise<DiagramSnapshot> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => {
      try {
        const parsed = JSON.parse(String(reader.result)) as DiagramSnapshot;
        if (!Array.isArray(parsed.nodes) || !Array.isArray(parsed.edges)) {
          throw new Error('Nieprawidłowy format pliku.');
        }
        resolve({
          mode: parsed.mode === 'BPMN' ? 'BPMN' : 'C4',
          nodes: parsed.nodes as Node[],
          edges: parsed.edges as Edge[],
        });
      } catch (e) {
        reject(e);
      }
    };
    reader.onerror = () => reject(reader.error);
    reader.readAsText(file);
  });
}
