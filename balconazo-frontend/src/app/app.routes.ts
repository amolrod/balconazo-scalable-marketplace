import { Routes } from '@angular/router';
import { LoginComponent } from './features/auth/components/login/login';
import { HomeComponent } from './features/home/home';
import { SpaceDetailComponent } from './features/spaces/space-detail/space-detail';

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
    path: 'spaces/:id',
    component: SpaceDetailComponent
  },
  {
    path: '**',
    redirectTo: '/'
  }
];
