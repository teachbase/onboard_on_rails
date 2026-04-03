window.OnboardOnRails = window.OnboardOnRails || {};

OnboardOnRails.SelectorGenerator = {
  generate(element) {
    if (element.id) return `#${element.id}`;
    const unique = this.findUniqueClass(element);
    if (unique) return unique;
    return this.buildPath(element);
  },
  findUniqueClass(element) {
    for (const cls of element.classList) {
      if (cls.startsWith("js-") || cls.startsWith("oor-")) continue;
      const matches = document.querySelectorAll(`.${CSS.escape(cls)}`);
      if (matches.length === 1) return `.${cls}`;
    }
    return null;
  },
  buildPath(element) {
    const parts = [];
    let current = element;
    while (current && current !== document.body) {
      let selector = current.tagName.toLowerCase();
      if (current.id) { parts.unshift(`#${current.id}`); break; }
      const parent = current.parentElement;
      if (parent) {
        const siblings = Array.from(parent.children).filter(c => c.tagName === current.tagName);
        if (siblings.length > 1) { const index = siblings.indexOf(current) + 1; selector += `:nth-of-type(${index})`; }
      }
      parts.unshift(selector);
      current = parent;
    }
    return parts.join(" > ");
  }
};
