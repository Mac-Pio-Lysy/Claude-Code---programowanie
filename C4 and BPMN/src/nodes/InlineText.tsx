import { useEffect, useRef, useState } from 'react';
import { useDiagramStore } from '../store/useDiagramStore';

interface Props {
  value: string;
  onCommit: (value: string) => void;
  placeholder?: string;
  className?: string;
  multiline?: boolean;
}

/**
 * Tekst edytowalny po dwukliku. Enter zatwierdza, Esc anuluje.
 * Klasa "nodrag" zapobiega przeciąganiu węzła podczas edycji.
 */
export function InlineText({
  value,
  onCommit,
  placeholder,
  className = '',
  multiline = false,
}: Props) {
  const [editing, setEditing] = useState(false);
  const [draft, setDraft] = useState(value);
  const ref = useRef<HTMLTextAreaElement | HTMLInputElement>(null);
  const takeSnapshot = useDiagramStore((s) => s.takeSnapshot);

  useEffect(() => {
    if (editing && ref.current) {
      ref.current.focus();
      ref.current.select();
    }
  }, [editing]);

  const commit = () => {
    setEditing(false);
    if (draft !== value) onCommit(draft.trim());
  };

  const cancel = () => {
    setDraft(value);
    setEditing(false);
  };

  if (editing) {
    const shared = {
      ref: ref as never,
      value: draft,
      className: `nodrag w-full resize-none rounded border border-blue-400 bg-white/95 px-1 py-0.5 text-inherit outline-none ${className}`,
      onChange: (e: React.ChangeEvent<HTMLTextAreaElement | HTMLInputElement>) =>
        setDraft(e.target.value),
      onBlur: commit,
      onMouseDown: (e: React.MouseEvent) => e.stopPropagation(),
      onKeyDown: (e: React.KeyboardEvent) => {
        if (e.key === 'Escape') cancel();
        else if (e.key === 'Enter' && (!multiline || !e.shiftKey)) {
          e.preventDefault();
          commit();
        }
      },
    };
    return multiline ? (
      <textarea {...shared} rows={2} />
    ) : (
      <input {...shared} />
    );
  }

  return (
    <div
      className={`cursor-text whitespace-pre-wrap break-words ${className} ${
        !value ? 'italic opacity-50' : ''
      }`}
      onDoubleClick={(e) => {
        e.stopPropagation();
        takeSnapshot();
        setDraft(value);
        setEditing(true);
      }}
      title="Dwuklik aby edytować"
    >
      {value || placeholder || ''}
    </div>
  );
}
