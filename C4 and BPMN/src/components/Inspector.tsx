import { useDiagramStore } from '../store/useDiagramStore';
import { isC4Type } from '../types';

function Field({
  label,
  value,
  onChange,
  multiline,
  placeholder,
}: {
  label: string;
  value: string;
  onChange: (v: string) => void;
  multiline?: boolean;
  placeholder?: string;
}) {
  // Snapshot raz, na początku edycji pola (nie na każdy znak).
  const onFocus = () => useDiagramStore.getState().takeSnapshot();
  return (
    <label className="flex flex-col gap-1">
      <span className="text-[11px] font-semibold uppercase tracking-wide text-gray-500">
        {label}
      </span>
      {multiline ? (
        <textarea
          value={value}
          placeholder={placeholder}
          rows={3}
          onFocus={onFocus}
          onChange={(e) => onChange(e.target.value)}
          className="resize-none rounded border border-gray-300 px-2 py-1 text-sm outline-none focus:border-blue-400"
        />
      ) : (
        <input
          value={value}
          placeholder={placeholder}
          onFocus={onFocus}
          onChange={(e) => onChange(e.target.value)}
          className="rounded border border-gray-300 px-2 py-1 text-sm outline-none focus:border-blue-400"
        />
      )}
    </label>
  );
}

export function Inspector() {
  const nodes = useDiagramStore((s) => s.nodes);
  const edges = useDiagramStore((s) => s.edges);
  const updateNodeData = useDiagramStore((s) => s.updateNodeData);
  const updateEdgeLabel = useDiagramStore((s) => s.updateEdgeLabel);

  const node = nodes.find((n) => n.selected);
  const edge = edges.find((e) => e.selected);

  return (
    <aside className="flex w-64 flex-col gap-4 overflow-y-auto border-l border-gray-200 bg-white p-4">
      <h2 className="text-xs font-semibold uppercase tracking-wide text-gray-500">
        Inspektor
      </h2>

      {!node && !edge && (
        <p className="text-sm text-gray-400">
          Zaznacz węzeł lub strzałkę, aby edytować właściwości.
        </p>
      )}

      {node && (
        <div className="flex flex-col gap-3">
          <span className="text-xs text-gray-400">Typ: {node.type}</span>
          {isC4Type(node.type) ? (
            <>
              <Field
                label="Nazwa"
                value={String(node.data.name ?? '')}
                onChange={(name) => updateNodeData(node.id, { name })}
              />
              <Field
                label="Opis"
                value={String(node.data.description ?? '')}
                onChange={(description) =>
                  updateNodeData(node.id, { description })
                }
                multiline
              />
              {(node.type === 'c4Container' ||
                node.type === 'c4Component') && (
                <Field
                  label="Technologia"
                  value={String(node.data.technology ?? '')}
                  onChange={(technology) =>
                    updateNodeData(node.id, { technology })
                  }
                  placeholder="np. React, Node.js"
                />
              )}
            </>
          ) : (
            <Field
              label="Etykieta"
              value={String(node.data.label ?? '')}
              onChange={(label) => updateNodeData(node.id, { label })}
              multiline
            />
          )}
        </div>
      )}

      {edge && !node && (
        <div className="flex flex-col gap-3">
          <span className="text-xs text-gray-400">Strzałka</span>
          <Field
            label="Etykieta"
            value={String(edge.label ?? '')}
            onChange={(label) => updateEdgeLabel(edge.id, label)}
            placeholder="np. używa, wysyła dane"
          />
        </div>
      )}
    </aside>
  );
}
