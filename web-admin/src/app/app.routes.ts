import { Routes } from '@angular/router';

import { authGuard } from './core/guards/auth.guard';
import { AdminComponent } from './pages/admin/admin.component';
import { EntregasComponent } from './pages/entregas/entregas.component';
import { HomeComponent } from './pages/home/home.component';
import { LoginComponent } from './pages/login/login.component';

/** Navegacao do painel: acesso publico apenas no login. */
export const routes: Routes = [
  { path: '', redirectTo: 'home', pathMatch: 'full' },
  { path: 'login', component: LoginComponent, title: 'Acesso ao painel' },
  {
    path: 'home',
    component: HomeComponent,
    canActivate: [authGuard],
    title: 'Visao geral',
  },
  {
    path: 'admin',
    component: AdminComponent,
    canActivate: [authGuard],
    title: 'Pacientes',
  },
  {
    path: 'entregas',
    component: EntregasComponent,
    canActivate: [authGuard],
    title: 'Entregas',
  },
  { path: '**', redirectTo: 'home' },
];
