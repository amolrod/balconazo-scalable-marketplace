import { Routes } from '@angular/router';
import { LoginComponent } from './features/auth/components/login/login';
import { RegisterComponent } from './features/auth/components/register/register';
import { HomeComponent } from './features/home/home';
import { ExploreComponent } from './features/explore/explore';
import { SpaceDetailComponent } from './features/spaces/space-detail/space-detail';
import { MyBookingsComponent } from './features/bookings/my-bookings/my-bookings';
import { HostDashboardComponent } from './features/host/host-dashboard/host-dashboard';

export const routes: Routes = [
  {
    path: '',
    component: HomeComponent
  },
  {
    path: 'login',
    component: LoginComponent
  },
  {
    path: 'register',
    component: RegisterComponent
  },
  {
    path: 'explore',
    component: ExploreComponent
  },
  {
    path: 'spaces',
    component: ExploreComponent
  },
  {
    path: 'spaces/:id',
    component: SpaceDetailComponent
  },
  {
    path: 'my-bookings',
    component: MyBookingsComponent
  },
  {
    path: 'host/dashboard',
    component: HostDashboardComponent
  },
  {
    path: '**',
    redirectTo: '/'
  }
];
