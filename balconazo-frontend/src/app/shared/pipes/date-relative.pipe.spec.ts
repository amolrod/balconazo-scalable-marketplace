import { DateRelativePipe } from './date-relative.pipe';

describe('DateRelativePipe', () => {
  let pipe: DateRelativePipe;

  beforeEach(() => {
    pipe = new DateRelativePipe();
    jasmine.clock().install();
    jasmine.clock().mockDate(new Date('2025-11-04T12:00:00Z'));
  });

  afterEach(() => {
    jasmine.clock().uninstall();
  });

  it('should create an instance', () => {
    expect(pipe).toBeTruthy();
  });

  describe('null/undefined', () => {
    it('should return empty string for null', () => {
      expect(pipe.transform(null)).toBe('');
    });

    it('should return empty string for undefined', () => {
      expect(pipe.transform(undefined)).toBe('');
    });
  });

  describe('past dates', () => {
    it('should show "ahora mismo" for very recent dates (< 10 seconds)', () => {
      const now = new Date('2025-11-04T12:00:05Z');
      expect(pipe.transform(now)).toBe('ahora mismo');
    });

    it('should show "hace unos segundos" for dates within last minute', () => {
      const date = new Date('2025-11-04T11:59:30Z');
      expect(pipe.transform(date)).toBe('hace unos segundos');
    });

    it('should show minutes for dates within last hour', () => {
      const date = new Date('2025-11-04T11:30:00Z');
      expect(pipe.transform(date)).toBe('hace 30 minutos');
    });

    it('should show "hace 1 minuto" for 1 minute ago', () => {
      const date = new Date('2025-11-04T11:59:00Z');
      expect(pipe.transform(date)).toBe('hace 1 minuto');
    });

    it('should show hours for dates within last 24 hours', () => {
      const date = new Date('2025-11-04T09:00:00Z');
      expect(pipe.transform(date)).toBe('hace 3 horas');
    });

    it('should show "ayer" for yesterday', () => {
      const date = new Date('2025-11-03T12:00:00Z');
      expect(pipe.transform(date)).toBe('ayer');
    });

    it('should show days for dates within last week', () => {
      const date = new Date('2025-11-01T12:00:00Z');
      expect(pipe.transform(date)).toBe('hace 3 días');
    });

    it('should show weeks for dates within last month', () => {
      const date = new Date('2025-10-14T12:00:00Z');
      expect(pipe.transform(date)).toBe('hace 3 semanas');
    });

    it('should show months for dates within last year', () => {
      const date = new Date('2025-08-04T12:00:00Z');
      expect(pipe.transform(date)).toBe('hace 3 meses');
    });

    it('should show years for dates older than a year', () => {
      const date = new Date('2023-11-04T12:00:00Z');
      expect(pipe.transform(date)).toBe('hace 2 años');
    });
  });

  describe('future dates', () => {
    it('should show "en unos segundos" for very soon dates', () => {
      const date = new Date('2025-11-04T12:00:30Z');
      expect(pipe.transform(date)).toBe('en unos segundos');
    });

    it('should show "en X minutos" for dates in next hour', () => {
      const date = new Date('2025-11-04T12:30:00Z');
      expect(pipe.transform(date)).toBe('en 30 minutos');
    });

    it('should show "en X horas" for dates in next 24 hours', () => {
      const date = new Date('2025-11-04T15:00:00Z');
      expect(pipe.transform(date)).toBe('en 3 horas');
    });

    it('should show "mañana" for tomorrow', () => {
      const date = new Date('2025-11-05T12:00:00Z');
      expect(pipe.transform(date)).toBe('mañana');
    });

    it('should show "en X días" for dates in next week', () => {
      const date = new Date('2025-11-07T12:00:00Z');
      expect(pipe.transform(date)).toBe('en 3 días');
    });
  });

  describe('string dates', () => {
    it('should handle ISO date strings', () => {
      const dateString = '2025-11-04T11:00:00Z';
      expect(pipe.transform(dateString)).toBe('hace 1 hora');
    });
  });
});

