import { useRef } from 'react';
import { useReactFlow } from '@xyflow/react';
import { useDiagramStore } from '../store/useDiagramStore';
import type { DiagramMode } from '../types';
import {
  exportToPng,
  exportToSvg,
  exportToJson,
  importFromJson,
} from '../utils/export';

const modes: DiagramMode[] = ['C4', 'BPMN'];

function Btn({
  children,
  onClick,
  disabled,
  title,
}: {
  children: React.ReactNode;
  onClick: () => void;
  disabled?: boolean;
  title?: string;
}) {
  return (
    <button
      onClick={onClick}
      disabled={disabled}
      title={title}
      className="rounded border border-gray-300 bg-white px-2.5 py-1 text-sm text-gray-700 transition-colors hover:bg-gray-100 disabled:cursor-not-allowed disabled:opacity-40"
    >
      {children}
    </button>
  );
}

export function Toolbar() {
  const fileInputRef = useRef<HTMLInputElement>(null);
  const { getNodes } = useReactFlow();

  const mode = useDiagramStore((s) => s.mode);
  const setMode = useDiagramStore((s) => s.setMode);
  const undo = useDiagramStore((s) => s.undo);
  const redo = useDiagramStore((s) => s.redo);
  const canUndo = useDiagramStore((s) => s.past.length > 0);
  const canRedo = useDiagramStore((s) => s.future.length > 0);
  const loadDiagram = useDiagramStore((s) => s.loadDiagram);
  const clearDiagram = useDiagramStore((s) => s.clearDiagram);

  const handleExportJson = () => {
    const { mode, nodes, edges } = useDiagramStore.getState();
    exportToJson({ mode, nodes, edges });
  };

  const handleImport = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    try {
      const snapshot = await importFromJson(file);
      loadDiagram(snapshot);
    } catch (err) {
      alert('Nie udało się wczytać pliku: ' + (err as Error).message);
    }
    e.target.value = '';
  };

  return (
    <header className="flex flex-wrap items-center gap-3 border-b border-gray-200 bg-white px-4 py-2">
      <span className="text-sm font-semibold text-gray-800">
        C4 &amp; BPMN Editor
      </span>

      <div className="flex overflow-hidden rounded-md border border-gray-300">
        {modes.map((m) => (
          <button
            key={m}
            onClick={() => setMode(m)}
            className={`px-3 py-1 text-sm transition-colors ${
              mode === m
                ? 'bg-blue-600 text-white'
                : 'bg-white text-gray-700 hover:bg-gray-100'
            }`}
          >
            {m}
          </button>
        ))}
      </div>

      <div className="h-5 w-px bg-gray-200" />

      <div className="flex gap-1">
        <Btn onClick={undo} disabled={!canUndo} title="Cofnij (Ctrl+Z)">
          ↶ Cofnij
        </Btn>
        <Btn onClick={redo} disabled={!canRedo} title="Ponów (Ctrl+Y)">
          ↷ Ponów
        </Btn>
      </div>

      <div className="h-5 w-px bg-gray-200" />

      <div className="flex gap-1">
        <Btn onClick={() => exportToPng(getNodes())} title="Eksport PNG">
          PNG
        </Btn>
        <Btn onClick={() => exportToSvg(getNodes())} title="Eksport SVG">
          SVG
        </Btn>
        <Btn onClick={handleExportJson} title="Eksport JSON">
          Eksport JSON
        </Btn>
        <Btn onClick={() => fileInputRef.current?.click()} title="Import JSON">
          Import JSON
        </Btn>
        <input
          ref={fileInputRef}
          type="file"
          accept="application/json"
          className="hidden"
          onChange={handleImport}
        />
      </div>

      <div className="ml-auto">
        <Btn
          onClick={() => {
            if (confirm('Wyczyścić cały diagram?')) clearDiagram();
          }}
          title="Wyczyść płótno"
        >
          🗑 Wyczyść
        </Btn>
      </div>
    </header>
  );
}
