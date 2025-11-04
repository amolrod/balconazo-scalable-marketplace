import { TestBed } from '@angular/core/testing';
import { Router } from '@angular/router';
import { roleGuard, hostGuard, guestGuard } from './role.guard';
import { AuthService } from '../services/auth.service';

describe('RoleGuard', () => {
  let authService: jasmine.SpyObj<AuthService>;
  let router: jasmine.SpyObj<Router>;

  beforeEach(() => {
    const authServiceSpy = jasmine.createSpyObj('AuthService', [
      'isAuthenticated',
      'getUserRole'
    ]);
    const routerSpy = jasmine.createSpyObj('Router', ['navigate']);

    TestBed.configureTestingModule({
      providers: [
        { provide: AuthService, useValue: authServiceSpy },
        { provide: Router, useValue: routerSpy }
      ]
    });

    authService = TestBed.inject(AuthService) as jasmine.SpyObj<AuthService>;
    router = TestBed.inject(Router) as jasmine.SpyObj<Router>;
  });

  describe('roleGuard', () => {
    it('should allow access when user is authenticated and has allowed role', () => {
      authService.isAuthenticated.and.returnValue(true);
      authService.getUserRole.and.returnValue('HOST');

      const guard = TestBed.runInInjectionContext(() => roleGuard(['HOST'])());

      expect(guard).toBe(true);
      expect(router.navigate).not.toHaveBeenCalled();
    });

    it('should deny access when user is not authenticated', () => {
      authService.isAuthenticated.and.returnValue(false);

      const guard = TestBed.runInInjectionContext(() => roleGuard(['HOST'])());

      expect(guard).toBe(false);
      expect(router.navigate).toHaveBeenCalledWith(['/login']);
    });

    it('should deny access when user role is not in allowed roles', () => {
      authService.isAuthenticated.and.returnValue(true);
      authService.getUserRole.and.returnValue('GUEST');

      const guard = TestBed.runInInjectionContext(() => roleGuard(['HOST'])());

      expect(guard).toBe(false);
      expect(router.navigate).toHaveBeenCalledWith(['/']);
    });

    it('should allow access when user has one of multiple allowed roles', () => {
      authService.isAuthenticated.and.returnValue(true);
      authService.getUserRole.and.returnValue('GUEST');

      const guard = TestBed.runInInjectionContext(() => roleGuard(['HOST', 'GUEST'])());

      expect(guard).toBe(true);
      expect(router.navigate).not.toHaveBeenCalled();
    });
  });

  describe('hostGuard', () => {
    it('should allow access for HOST role', () => {
      authService.isAuthenticated.and.returnValue(true);
      authService.getUserRole.and.returnValue('HOST');

      const guard = TestBed.runInInjectionContext(() => hostGuard()());

      expect(guard).toBe(true);
    });

    it('should deny access for GUEST role', () => {
      authService.isAuthenticated.and.returnValue(true);
      authService.getUserRole.and.returnValue('GUEST');

      const guard = TestBed.runInInjectionContext(() => hostGuard()());

      expect(guard).toBe(false);
    });
  });

  describe('guestGuard', () => {
    it('should allow access for GUEST role', () => {
      authService.isAuthenticated.and.returnValue(true);
      authService.getUserRole.and.returnValue('GUEST');

      const guard = TestBed.runInInjectionContext(() => guestGuard()());

      expect(guard).toBe(true);
    });

    it('should deny access for HOST role', () => {
      authService.isAuthenticated.and.returnValue(true);
      authService.getUserRole.and.returnValue('HOST');

      const guard = TestBed.runInInjectionContext(() => guestGuard()());

      expect(guard).toBe(false);
    });
  });
});

