import { Component } from '@angular/core';
import { ToastComponent } from './shared/toast/toast';
import { AppShellComponent } from './shared/components/app-shell/app-shell';

@Component({
  selector: 'app-root',
  imports: [AppShellComponent, ToastComponent],
  templateUrl: './app.html',
  styleUrl: './app.scss'
})
export class App {
  title = 'Balconazo';
}
