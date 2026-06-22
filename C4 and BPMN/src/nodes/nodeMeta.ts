import type { AppNodeType, DiagramMode } from '../types';

export interface PaletteItem {
  type: AppNodeType;
  label: string;
  hint: string;
  defaultData: Record<string, unknown>;
}

export const PALETTE: Record<DiagramMode, PaletteItem[]> = {
  C4: [
    {
      type: 'c4Person',
      label: 'Person',
      hint: 'Użytkownik / aktor',
      defaultData: { name: 'Użytkownik', description: '' },
    },
    {
      type: 'c4System',
      label: 'Software System',
      hint: 'System programowy',
      defaultData: { name: 'System', description: '' },
    },
    {
      type: 'c4Container',
      label: 'Container',
      hint: 'Aplikacja / baza danych',
      defaultData: { name: 'Kontener', description: '', technology: '' },
    },
    {
      type: 'c4Component',
      label: 'Component',
      hint: 'Komponent w kontenerze',
      defaultData: { name: 'Komponent', description: '', technology: '' },
    },
  ],
  BPMN: [
    {
      type: 'bpmnStart',
      label: 'Start Event',
      hint: 'Zdarzenie początkowe',
      defaultData: { label: 'Start' },
    },
    {
      type: 'bpmnEnd',
      label: 'End Event',
      hint: 'Zdarzenie końcowe',
      defaultData: { label: 'Koniec' },
    },
    {
      type: 'bpmnTask',
      label: 'Task',
      hint: 'Zadanie / czynność',
      defaultData: { label: 'Zadanie' },
    },
    {
      type: 'bpmnGateway',
      label: 'Gateway (XOR)',
      hint: 'Bramka decyzyjna',
      defaultData: { label: '' },
    },
  ],
};

export const defaultDataFor = (type: AppNodeType): Record<string, unknown> => {
  for (const mode of ['C4', 'BPMN'] as DiagramMode[]) {
    const item = PALETTE[mode].find((i) => i.type === type);
    if (item) return { ...item.defaultData };
  }
  return {};
};
