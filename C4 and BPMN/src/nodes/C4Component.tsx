import type { NodeProps } from '@xyflow/react';
import { C4Base } from './C4Base';

export function C4Component(props: NodeProps) {
  return (
    <C4Base
      {...props}
      typeLabel="Component"
      colorClass="bg-[#85bbf0] !text-[#0b2545]"
      borderClass="border-[#5a9bd4]"
      hasTechnology
    />
  );
}
