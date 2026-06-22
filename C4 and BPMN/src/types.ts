import type { Node, Edge } from '@xyflow/react';

export type DiagramMode = 'C4' | 'BPMN';

// ----- C4 -----
export type C4NodeType =
  | 'c4Person'
  | 'c4System'
  | 'c4Container'
  | 'c4Component';

export interface C4NodeData {
  name: string;
  description?: string;
  technology?: string;
  [key: string]: unknown;
}

// ----- BPMN -----
export type BpmnNodeType =
  | 'bpmnStart'
  | 'bpmnEnd'
  | 'bpmnTask'
  | 'bpmnGateway';

export interface BpmnNodeData {
  label: string;
  [key: string]: unknown;
}

export type AppNodeType = C4NodeType | BpmnNodeType;

export const C4_TYPES: C4NodeType[] = [
  'c4Person',
  'c4System',
  'c4Container',
  'c4Component',
];

export const BPMN_TYPES: BpmnNodeType[] = [
  'bpmnStart',
  'bpmnEnd',
  'bpmnTask',
  'bpmnGateway',
];

export const isC4Type = (t?: string): t is C4NodeType =>
  C4_TYPES.includes(t as C4NodeType);

export interface DiagramSnapshot {
  mode: DiagramMode;
  nodes: Node[];
  edges: Edge[];
}
