import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { NavbarComponent } from '../navbar/navbar';

/**
 * AppShell Component
 * Layout wrapper con navbar + router-outlet + footer
 */
@Component({
  selector: 'app-shell',
  standalone: true,
  imports: [CommonModule, RouterModule, NavbarComponent],
  templateUrl: './app-shell.html',
  styleUrl: './app-shell.scss'
})
export class AppShellComponent {
  currentYear = new Date().getFullYear();
}

