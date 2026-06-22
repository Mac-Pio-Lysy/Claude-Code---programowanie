import { create } from 'zustand';
import {
  type Node,
  type Edge,
  type Connection,
  type NodeChange,
  type EdgeChange,
  applyNodeChanges,
  applyEdgeChanges,
  addEdge,
  MarkerType,
} from '@xyflow/react';
import type { DiagramMode, DiagramSnapshot } from '../types';

const STORAGE_KEY = 'c4-bpmn-diagram';
const MAX_HISTORY = 100;

interface DiagramState {
  mode: DiagramMode;
  nodes: Node[];
  edges: Edge[];
  past: DiagramSnapshot[];
  future: DiagramSnapshot[];

  setMode: (mode: DiagramMode) => void;
  onNodesChange: (changes: NodeChange[]) => void;
  onEdgesChange: (changes: EdgeChange[]) => void;
  onConnect: (connection: Connection) => void;
  addNode: (node: Node) => void;
  updateNodeData: (id: string, data: Record<string, unknown>) => void;
  updateEdgeLabel: (id: string, label: string) => void;

  takeSnapshot: () => void;
  undo: () => void;
  redo: () => void;

  loadDiagram: (snapshot: DiagramSnapshot) => void;
  clearDiagram: () => void;
  saveToLocalStorage: () => void;
}

let idCounter = 1;
export const nextId = (prefix = 'node') => `${prefix}_${Date.now()}_${idCounter++}`;

const snapshotOf = (s: DiagramState): DiagramSnapshot => ({
  mode: s.mode,
  nodes: JSON.parse(JSON.stringify(s.nodes)),
  edges: JSON.parse(JSON.stringify(s.edges)),
});

const loadInitial = (): Pick<DiagramState, 'mode' | 'nodes' | 'edges'> => {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (raw) {
      const parsed = JSON.parse(raw) as DiagramSnapshot;
      if (parsed.nodes && parsed.edges) {
        return {
          mode: parsed.mode ?? 'C4',
          nodes: parsed.nodes,
          edges: parsed.edges,
        };
      }
    }
  } catch {
    /* ignore corrupted storage */
  }
  return { mode: 'C4', nodes: [], edges: [] };
};

export const defaultEdgeOptions = {
  markerEnd: { type: MarkerType.ArrowClosed },
};

export const useDiagramStore = create<DiagramState>((set, get) => ({
  ...loadInitial(),
  past: [],
  future: [],

  setMode: (mode) => set({ mode }),

  onNodesChange: (changes) => {
    if (changes.some((c) => c.type === 'remove')) get().takeSnapshot();
    set((state) => ({ nodes: applyNodeChanges(changes, state.nodes) }));
  },

  onEdgesChange: (changes) => {
    if (changes.some((c) => c.type === 'remove')) get().takeSnapshot();
    set((state) => ({ edges: applyEdgeChanges(changes, state.edges) }));
  },

  onConnect: (connection) => {
    get().takeSnapshot();
    set((state) => ({
      edges: addEdge(
        { ...connection, ...defaultEdgeOptions, label: '' },
        state.edges
      ),
    }));
  },

  addNode: (node) => {
    get().takeSnapshot();
    set((state) => ({ nodes: [...state.nodes, node] }));
  },

  // Uwaga: edycja tekstu nie robi snapshotu na każdy znak — snapshot jest
  // brany na początku edycji (onFocus / wejście w tryb edycji w węźle).
  updateNodeData: (id, data) =>
    set((state) => ({
      nodes: state.nodes.map((n) =>
        n.id === id ? { ...n, data: { ...n.data, ...data } } : n
      ),
    })),

  updateEdgeLabel: (id, label) =>
    set((state) => ({
      edges: state.edges.map((e) => (e.id === id ? { ...e, label } : e)),
    })),

  takeSnapshot: () =>
    set((state) => ({
      past: [...state.past, snapshotOf(state)].slice(-MAX_HISTORY),
      future: [],
    })),

  undo: () =>
    set((state) => {
      if (state.past.length === 0) return state;
      const previous = state.past[state.past.length - 1];
      return {
        past: state.past.slice(0, -1),
        future: [snapshotOf(state), ...state.future],
        mode: previous.mode,
        nodes: previous.nodes,
        edges: previous.edges,
      };
    }),

  redo: () =>
    set((state) => {
      if (state.future.length === 0) return state;
      const next = state.future[0];
      return {
        past: [...state.past, snapshotOf(state)],
        future: state.future.slice(1),
        mode: next.mode,
        nodes: next.nodes,
        edges: next.edges,
      };
    }),

  loadDiagram: (snapshot) => {
    get().takeSnapshot();
    set({
      mode: snapshot.mode ?? 'C4',
      nodes: snapshot.nodes ?? [],
      edges: snapshot.edges ?? [],
    });
  },

  clearDiagram: () => {
    get().takeSnapshot();
    set({ nodes: [], edges: [] });
  },

  saveToLocalStorage: () => {
    const { mode, nodes, edges } = get();
    localStorage.setItem(
      STORAGE_KEY,
      JSON.stringify({ mode, nodes, edges } satisfies DiagramSnapshot)
    );
  },
}));

// Autozapis do localStorage przy każdej zmianie diagramu.
useDiagramStore.subscribe((state, prev) => {
  if (
    state.nodes !== prev.nodes ||
    state.edges !== prev.edges ||
    state.mode !== prev.mode
  ) {
    state.saveToLocalStorage();
  }
});
