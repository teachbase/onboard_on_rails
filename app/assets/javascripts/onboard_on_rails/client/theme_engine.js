window.OnboardOnRails = window.OnboardOnRails || {};

OnboardOnRails.ThemeEngine = {
  applyTheme(container, theme, tourOverrides, stepOverrides) {
    container.className = "oor-tour-step";
    container.classList.add(`oor-theme-${theme}`);
    const overrides = Object.assign({}, tourOverrides || {}, stepOverrides || {});
    if (overrides.background) container.style.setProperty("--oor-step-bg", overrides.background);
    if (overrides.text_color) container.style.setProperty("--oor-step-text", overrides.text_color);
    if (overrides.font_family) container.style.setProperty("--oor-step-font", overrides.font_family);
    if (overrides.font_size) container.style.setProperty("--oor-step-font-size", overrides.font_size);
    if (overrides.border_radius) container.style.setProperty("--oor-step-radius", overrides.border_radius);
    if (overrides.button_color) container.style.setProperty("--oor-step-btn-bg", overrides.button_color);
    if (overrides.max_width) container.style.setProperty("--oor-step-max-width", overrides.max_width);
  }
};
