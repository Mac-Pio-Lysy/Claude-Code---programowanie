import { Handle, Position, type NodeProps } from '@xyflow/react';
import { InlineText } from './InlineText';
import { useDiagramStore } from '../store/useDiagramStore';
import type { C4NodeData } from '../types';

interface C4BaseProps extends NodeProps {
  typeLabel: string;
  colorClass: string; // tło + tekst (Tailwind)
  borderClass: string;
  rounded?: boolean;
  hasTechnology?: boolean;
  icon?: React.ReactNode;
}

const handleStyle = { width: 8, height: 8 };

export function C4Base({
  id,
  data,
  selected,
  typeLabel,
  colorClass,
  borderClass,
  rounded = false,
  hasTechnology = false,
  icon,
}: C4BaseProps) {
  const d = data as C4NodeData;
  const updateNodeData = useDiagramStore((s) => s.updateNodeData);

  return (
    <div
      className={`relative min-w-[180px] max-w-[260px] border-2 px-3 py-2 text-white shadow-md ${colorClass} ${borderClass} ${
        rounded ? 'rounded-2xl' : 'rounded-md'
      } ${selected ? 'ring-2 ring-offset-2 ring-blue-300' : ''}`}
    >
      {(['Top', 'Right', 'Bottom', 'Left'] as const).map((pos) => (
        <Handle
          key={pos}
          id={pos.toLowerCase()}
          type="source"
          position={Position[pos]}
          style={handleStyle}
          className="!bg-white !border-2 !border-gray-500"
        />
      ))}

      {icon && <div className="mb-1 flex justify-center">{icon}</div>}

      <InlineText
        value={d.name ?? ''}
        onCommit={(name) => updateNodeData(id, { name })}
        placeholder="Nazwa"
        className="text-center text-sm font-bold leading-tight"
      />

      <div className="mt-0.5 text-center text-[10px] font-medium uppercase tracking-wide opacity-80">
        [{typeLabel}]
      </div>

      {hasTechnology && (
        <InlineText
          value={d.technology ?? ''}
          onCommit={(technology) => updateNodeData(id, { technology })}
          placeholder="Technologia"
          className="mt-1 text-center text-[11px] italic opacity-90"
        />
      )}

      <InlineText
        value={d.description ?? ''}
        onCommit={(description) => updateNodeData(id, { description })}
        placeholder="Opis…"
        multiline
        className="mt-1 text-center text-xs leading-snug opacity-95"
      />
    </div>
  );
}
