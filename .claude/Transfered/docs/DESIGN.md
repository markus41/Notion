# Design System

## Figma

Our design system and UI components are documented in Figma.

**Figma File**: [Agent Framework Design System](https://www.figma.com/file/placeholder)

_Note: Replace with actual Figma link when available_

## Design Tokens

Design tokens are defined in Tailwind configuration and synchronized with Figma.

### Colors

- **Primary**: Blue scale (50-950)
- **Gray**: Neutral scale
- **Success**: Green
- **Warning**: Yellow
- **Error**: Red

### Typography

- **Font Family**: System fonts
- **Font Sizes**: text-xs, text-sm, text-base, text-lg, text-xl, text-2xl
- **Font Weights**: 400 (normal), 500 (medium), 600 (semibold), 700 (bold)

### Spacing

- **Scale**: 4px base unit
- **Common**: 0, 1, 2, 3, 4, 6, 8, 12, 16, 24, 32

### Breakpoints

- **sm**: 640px
- **md**: 768px
- **lg**: 1024px
- **xl**: 1280px
- **2xl**: 1536px

## Component Library

See [Storybook](./STORYBOOK.md) for interactive component documentation.

## Design Principles

1. **Consistency**: Use design tokens consistently
2. **Accessibility**: WCAG 2.1 AA compliance
3. **Responsive**: Mobile-first approach
4. **Performance**: Optimize for fast load times
5. **Clarity**: Clear visual hierarchy

## Requesting Changes

1. Open GitHub issue with design request
2. Tag with `design` label
3. Include mockups or examples
4. Link related Figma file

## Contributing

When implementing designs:
1. Use Tailwind utility classes
2. Follow component naming conventions
3. Add Storybook stories
4. Test responsive behavior
5. Verify accessibility
