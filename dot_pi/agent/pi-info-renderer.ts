import { truncateToWidth } from "@earendil-works/pi-tui";

// pi-info's documented renderer hook; keep segment formatting/colors in JSON.
// This file lives outside extensions/ so Pi does not auto-load it as an extension.
export function renderBar(bar: {
  position: string;
  width: number;
  parts: { key: string; text: string }[];
  separator: string;
}): string | null {
  if (bar.position !== "footer" || !bar.parts.some((part) => part.key === "model")) {
    return null;
  }
  const thinking = bar.parts.find((part) => part.key === "thinking");
  const text = bar.parts
    .filter((part) => part.key !== "thinking")
    .map((part) => part.text + (part.key === "model" ? thinking?.text ?? "" : ""))
    .join(bar.separator);
  return truncateToWidth(text, bar.width);
}
