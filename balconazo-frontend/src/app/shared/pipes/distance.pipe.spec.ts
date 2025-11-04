import { DistancePipe } from './distance.pipe';

describe('DistancePipe', () => {
  let pipe: DistancePipe;

  beforeEach(() => {
    pipe = new DistancePipe();
  });

  it('should create an instance', () => {
    expect(pipe).toBeTruthy();
  });

  describe('meters (< 1000m)', () => {
    it('should show distance in meters', () => {
      expect(pipe.transform(500)).toBe('500 m');
      expect(pipe.transform(999)).toBe('999 m');
      expect(pipe.transform(50)).toBe('50 m');
    });

    it('should round meters', () => {
      expect(pipe.transform(500.6)).toBe('501 m');
      expect(pipe.transform(500.4)).toBe('500 m');
    });
  });

  describe('kilometers (>= 1000m)', () => {
    it('should show distance in kilometers with 1 decimal by default', () => {
      expect(pipe.transform(1000)).toBe('1.0 km');
      expect(pipe.transform(1500)).toBe('1.5 km');
      expect(pipe.transform(2345)).toBe('2.3 km');
    });

    it('should respect custom decimal places', () => {
      expect(pipe.transform(1234, 0)).toBe('1 km');
      expect(pipe.transform(1234, 2)).toBe('1.23 km');
      expect(pipe.transform(1500, 0)).toBe('2 km');
    });

    it('should handle very large distances', () => {
      expect(pipe.transform(50000)).toBe('50.0 km');
      expect(pipe.transform(100000, 0)).toBe('100 km');
    });
  });

  describe('edge cases', () => {
    it('should handle zero', () => {
      expect(pipe.transform(0)).toBe('0 m');
    });

    it('should handle null and undefined', () => {
      expect(pipe.transform(null)).toBe('0 m');
      expect(pipe.transform(undefined)).toBe('0 m');
    });

    it('should handle boundary case (exactly 1000m)', () => {
      expect(pipe.transform(1000)).toBe('1.0 km');
    });
  });
});

