import { describe, expect, it } from 'vitest'
import { add, greet, multiply } from '../src/index'

describe('greet', () => {
  it('should return a greeting message', () => {
    expect(greet('World')).toBe('Hello, World!')
  })

  it('should handle empty string', () => {
    expect(greet('')).toBe('Hello, !')
  })
})

describe('add', () => {
  it('should add two positive numbers', () => {
    expect(add(2, 3)).toBe(5)
  })

  it('should add negative numbers', () => {
    expect(add(-1, -2)).toBe(-3)
  })

  it('should add zero', () => {
    expect(add(5, 0)).toBe(5)
  })
})

describe('multiply', () => {
  it('should multiply two positive numbers', () => {
    expect(multiply(3, 4)).toBe(12)
  })

  it('should multiply by zero', () => {
    expect(multiply(5, 0)).toBe(0)
  })

  it('should multiply negative numbers', () => {
    expect(multiply(-2, 3)).toBe(-6)
  })
})
