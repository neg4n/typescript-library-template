/**
 * A simple greeting function for testing the build process
 */
export function greet(name: string): string {
  return `Hello, ${name}!`;
}

/**
 * A utility function that demonstrates tree-shaking
 */
export function add(a: number, b: number): number {
  return a + b;
}

/**
 * Another utility function for tree-shaking demonstration
 */
export function multiply(a: number, b: number): number {
  return a * b;
}

/**
 * Default export for testing
 */
export default {
  greet,
  add,
  multiply,
};