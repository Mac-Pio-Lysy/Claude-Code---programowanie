import { Handle, Position, type NodeProps } from '@xyflow/react';
import { InlineText } from './InlineText';
import { useDiagramStore } from '../store/useDiagramStore';
import type { BpmnNodeData } from '../types';

const handleStyle = { width: 8, height: 8 };

export function BpmnGateway({ id, data, selected }: NodeProps) {
  const d = data as BpmnNodeData;
  const updateNodeData = useDiagramStore((s) => s.updateNodeData);

  return (
    <div className="relative flex flex-col items-center">
      <div className="relative h-16 w-16">
        {/* Romb: obrócony kwadrat */}
        <div
          className={`absolute inset-0 rotate-45 rounded-md border-2 bg-amber-50 shadow-md ${
            selected ? 'border-blue-500 ring-2 ring-blue-200' : 'border-amber-500'
          }`}
        />
        {/* Symbol X */}
        <div className="absolute inset-0 flex items-center justify-center text-2xl font-bold text-amber-700">
          ✕
        </div>
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
      </div>
      <div className="mt-1 max-w-[140px]">
        <InlineText
          value={d.label ?? ''}
          onCommit={(label) => updateNodeData(id, { label })}
          placeholder="Warunek?"
          className="text-center text-xs font-medium text-gray-700"
        />
      </div>
    </div>
  );
}
