import { useDiagramStore } from '../store/useDiagramStore';
import { PALETTE } from '../nodes/nodeMeta';

const swatch: Record<string, string> = {
  c4Person: 'bg-[#08427b]',
  c4System: 'bg-[#1168bd]',
  c4Container: 'bg-[#438dd5]',
  c4Component: 'bg-[#85bbf0]',
  bpmnStart: 'bg-white border-2 border-green-600 rounded-full',
  bpmnEnd: 'bg-white border-[3px] border-red-600 rounded-full',
  bpmnTask: 'bg-white border-2 border-gray-400 rounded',
  bpmnGateway: 'bg-amber-50 border-2 border-amber-500 rotate-45',
};

export function Palette() {
  const mode = useDiagramStore((s) => s.mode);
  const items = PALETTE[mode];

  const onDragStart = (event: React.DragEvent, nodeType: string) => {
    event.dataTransfer.setData('application/reactflow', nodeType);
    event.dataTransfer.effectAllowed = 'move';
  };

  return (
    <aside className="flex w-60 flex-col gap-2 overflow-y-auto border-r border-gray-200 bg-gray-50 p-3">
      <h2 className="mb-1 text-xs font-semibold uppercase tracking-wide text-gray-500">
        Paleta · {mode}
      </h2>
      {items.map((item) => (
        <div
          key={item.type}
          draggable
          onDragStart={(e) => onDragStart(e, item.type)}
          className="flex cursor-grab items-center gap-3 rounded-md border border-gray-300 bg-white px-3 py-2 shadow-sm transition-colors hover:border-blue-400 active:cursor-grabbing"
        >
          <span
            className={`h-5 w-5 shrink-0 ${swatch[item.type] ?? 'bg-gray-300'}`}
          />
          <span className="flex flex-col leading-tight">
            <span className="text-sm font-medium text-gray-800">
              {item.label}
            </span>
            <span className="text-[11px] text-gray-500">{item.hint}</span>
          </span>
        </div>
      ))}
      <p className="mt-3 text-[11px] leading-relaxed text-gray-400">
        Przeciągnij element na płótno. Dwuklik = edycja tekstu. Połącz węzły
        ciągnąc od kropki. Del = usuń.
      </p>
    </aside>
  );
}
