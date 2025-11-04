import { PricePipe } from './price.pipe';

describe('PricePipe', () => {
  let pipe: PricePipe;

  beforeEach(() => {
    pipe = new PricePipe();
  });

  it('should create an instance', () => {
    expect(pipe).toBeTruthy();
  });

  describe('EUR currency (default)', () => {
    it('should convert cents to euros with decimals', () => {
      expect(pipe.transform(2500)).toBe('€25.00');
      expect(pipe.transform(10000)).toBe('€100.00');
      expect(pipe.transform(150)).toBe('€1.50');
    });

    it('should convert cents to euros without decimals when showDecimals is false', () => {
      expect(pipe.transform(2500, 'EUR', false)).toBe('€25');
      expect(pipe.transform(2550, 'EUR', false)).toBe('€26');
    });

    it('should handle zero value', () => {
      expect(pipe.transform(0)).toBe('€0.00');
    });

    it('should handle null and undefined', () => {
      expect(pipe.transform(null)).toBe('€0.00');
      expect(pipe.transform(undefined)).toBe('€0.00');
    });
  });

  describe('USD currency', () => {
    it('should convert cents to dollars with decimals', () => {
      expect(pipe.transform(2500, 'USD')).toBe('$25.00');
      expect(pipe.transform(10000, 'USD')).toBe('$100.00');
    });

    it('should convert cents to dollars without decimals', () => {
      expect(pipe.transform(2500, 'USD', false)).toBe('$25');
    });

    it('should handle null with USD currency', () => {
      expect(pipe.transform(null, 'USD')).toBe('$0.00');
    });
  });

  describe('edge cases', () => {
    it('should handle very large amounts', () => {
      expect(pipe.transform(100000000)).toBe('€1000000.00');
    });

    it('should handle fractional cents (round to 2 decimals)', () => {
      expect(pipe.transform(2501)).toBe('€25.01');
    });
  });
});

