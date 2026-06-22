import { Handle, Position, type NodeProps } from '@xyflow/react';
import { InlineText } from './InlineText';
import { useDiagramStore } from '../store/useDiagramStore';
import type { BpmnNodeData } from '../types';

const handleStyle = { width: 8, height: 8 };

interface BpmnEventProps extends NodeProps {
  variant: 'start' | 'end';
}

function BpmnEvent({ id, data, selected, variant }: BpmnEventProps) {
  const d = data as BpmnNodeData;
  const updateNodeData = useDiagramStore((s) => s.updateNodeData);

  const ring =
    variant === 'start'
      ? 'border-green-600 border-2'
      : 'border-red-600 border-[5px]';

  return (
    <div className="relative flex flex-col items-center">
      <div
        className={`flex h-16 w-16 items-center justify-center rounded-full bg-white shadow-md ${ring} ${
          selected ? 'ring-2 ring-offset-2 ring-blue-400' : ''
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
      </div>
      <div className="mt-1 max-w-[120px]">
        <InlineText
          value={d.label ?? ''}
          onCommit={(label) => updateNodeData(id, { label })}
          placeholder={variant === 'start' ? 'Start' : 'Koniec'}
          className="text-center text-xs font-medium text-gray-700"
        />
      </div>
    </div>
  );
}

export const BpmnStart = (props: NodeProps) => (
  <BpmnEvent {...props} variant="start" />
);
export const BpmnEnd = (props: NodeProps) => (
  <BpmnEvent {...props} variant="end" />
);
