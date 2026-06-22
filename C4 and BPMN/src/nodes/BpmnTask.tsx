import { Handle, Position, type NodeProps } from '@xyflow/react';
import { InlineText } from './InlineText';
import { useDiagramStore } from '../store/useDiagramStore';
import type { BpmnNodeData } from '../types';

const handleStyle = { width: 8, height: 8 };

export function BpmnTask({ id, data, selected }: NodeProps) {
  const d = data as BpmnNodeData;
  const updateNodeData = useDiagramStore((s) => s.updateNodeData);

  return (
    <div
      className={`flex min-h-[56px] min-w-[140px] max-w-[220px] items-center justify-center rounded-lg border-2 bg-white px-3 py-2 shadow-md ${
        selected ? 'border-blue-500 ring-2 ring-blue-200' : 'border-gray-400'
      }`}
    >
      {(['Top', 'Right', 'Bottom', 'Left'] as const).map((pos) => (
        <Handle
          key={pos}
          id={pos.toLowerCase()}
          type="source"
          position={Position[pos]}
          style={handleStyle}
          className="!bg-gray-600"
        />
      ))}
      <InlineText
        value={d.label ?? ''}
        onCommit={(label) => updateNodeData(id, { label })}
        placeholder="Zadanie"
        multiline
        className="text-center text-sm font-medium text-gray-800"
      />
    </div>
  );
}
