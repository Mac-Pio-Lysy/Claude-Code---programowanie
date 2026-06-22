import type { NodeProps } from '@xyflow/react';
import { C4Base } from './C4Base';

export function C4Container(props: NodeProps) {
  return (
    <C4Base
      {...props}
      typeLabel="Container"
      colorClass="bg-[#438dd5]"
      borderClass="border-[#2e6da4]"
      hasTechnology
    />
  );
}
