import { Controller } from "@hotwired/stimulus"

// Draws a simple SVG ring based on data-ring-percent-value
export default class extends Controller {
  static values = { percent: Number }

  connect() { 
    this.draw() 
  }

  percentValueChanged() {
    this.draw()
  }

  draw() {
    const p = Math.max(0, Math.min(100, Math.round(this.percentValue || 0)));
    const size = 88;
    const stroke = 8;
    const r = (size - stroke) / 2;
    const c = 2 * Math.PI * r;
    
    // Create SVG element
    const el = document.createElementNS("http://www.w3.org/2000/svg", "svg");
    el.setAttribute("viewBox", `0 0 ${size} ${size}`);
    el.classList.add("w-100", "h-100");
    el.setAttribute("role", "img");
    el.setAttribute("aria-label", `Progress: ${p}%`);

    // Background circle
    const bg = document.createElementNS(el.namespaceURI, "circle");
    bg.setAttribute("cx", size / 2);
    bg.setAttribute("cy", size / 2);
    bg.setAttribute("r", r);
    bg.setAttribute("stroke-width", stroke);
    bg.setAttribute("stroke", "#e5e7eb");
    bg.setAttribute("fill", "none");

    // Progress circle
    const fg = document.createElementNS(el.namespaceURI, "circle");
    fg.setAttribute("cx", size / 2);
    fg.setAttribute("cy", size / 2);
    fg.setAttribute("r", r);
    fg.setAttribute("stroke-width", stroke);
    fg.setAttribute("stroke-linecap", "round");
    fg.setAttribute("stroke", "#3b82f6");
    fg.setAttribute("fill", "none");
    fg.setAttribute("stroke-dasharray", c);
    fg.setAttribute("stroke-dashoffset", c * (1 - p / 100));
    fg.style.transition = "stroke-dashoffset 0.6s ease";
    fg.style.transform = "rotate(-90deg)";
    fg.style.transformOrigin = "center";

    // Percentage text
    const text = document.createElementNS(el.namespaceURI, "text");
    text.setAttribute("x", "50%");
    text.setAttribute("y", "50%");
    text.setAttribute("dominant-baseline", "middle");
    text.setAttribute("text-anchor", "middle");
    text.setAttribute("font-size", "16");
    text.setAttribute("font-weight", "600");
    text.setAttribute("fill", "#111827");
    text.textContent = `${p}%`;

    // Assemble and insert
    el.append(bg, fg, text);
    this.element.innerHTML = "";
    this.element.appendChild(el);
  }
}