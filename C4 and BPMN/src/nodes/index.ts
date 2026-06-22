import type { NodeTypes } from '@xyflow/react';
import { C4Person } from './C4Person';
import { C4System } from './C4System';
import { C4Container } from './C4Container';
import { C4Component } from './C4Component';
import { BpmnTask } from './BpmnTask';
import { BpmnStart, BpmnEnd } from './BpmnEvent';
import { BpmnGateway } from './BpmnGateway';

export const nodeTypes: NodeTypes = {
  c4Person: C4Person,
  c4System: C4System,
  c4Container: C4Container,
  c4Component: C4Component,
  bpmnStart: BpmnStart,
  bpmnEnd: BpmnEnd,
  bpmnTask: BpmnTask,
  bpmnGateway: BpmnGateway,
};
