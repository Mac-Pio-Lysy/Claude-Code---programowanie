import { useEffect } from 'react';
import { ReactFlowProvider } from '@xyflow/react';
import { Toolbar } from './components/Toolbar';
import { Palette } from './components/Palette';
import { Canvas } from './components/Canvas';
import { Inspector } from './components/Inspector';
import { useDiagramStore } from './store/useDiagramStore';

function useKeyboardShortcuts() {
  const undo = useDiagramStore((s) => s.undo);
  const redo = useDiagramStore((s) => s.redo);

  useEffect(() => {
    const onKeyDown = (e: KeyboardEvent) => {
      const target = e.target as HTMLElement;
      // Nie przechwytuj skrótów podczas edycji w polu tekstowym.
      const typing =
        target.tagName === 'INPUT' ||
        target.tagName === 'TEXTAREA' ||
        target.isContentEditable;
      if (typing) return;

      if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'z') {
        e.preventDefault();
        if (e.shiftKey) redo();
        else undo();
      } else if (
        (e.ctrlKey || e.metaKey) &&
        e.key.toLowerCase() === 'y'
      ) {
        e.preventDefault();
        redo();
      }
    };
    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, [undo, redo]);
}

export default function App() {
  useKeyboardShortcuts();

  return (
    <ReactFlowProvider>
      <div className="flex h-full flex-col">
        <Toolbar />
        <div className="flex flex-1 overflow-hidden">
          <Palette />
          <main className="flex-1">
            <Canvas />
          </main>
          <Inspector />
        </div>
      </div>
    </ReactFlowProvider>
  );
}
