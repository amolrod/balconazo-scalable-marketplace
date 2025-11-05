import { Component, Input, Output, EventEmitter } from '@angular/core';
import { CommonModule } from '@angular/common';
import { SpaceImage } from '../../core/models/space.model';
import { SpaceImagesService } from '../../core/services/space-images.service';
import { ToastService } from '../../core/services/toast.service';

@Component({
  selector: 'app-image-gallery-manager',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './image-gallery-manager.html',
  styleUrl: './image-gallery-manager.scss'
})
export class ImageGalleryManagerComponent {
  @Input() spaceId!: string;
  @Input() images: SpaceImage[] = [];
  @Input() maxImages: number = 10;
  @Output() imagesChange = new EventEmitter<SpaceImage[]>();

  uploading = false;
  dragOver = false;

  constructor(
    private imagesService: SpaceImagesService,
    private toastService: ToastService
  ) {}

  onFileSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    if (input.files && input.files.length > 0) {
      this.uploadFiles(Array.from(input.files));
    }
  }

  onDrop(event: DragEvent): void {
    event.preventDefault();
    this.dragOver = false;

    if (event.dataTransfer?.files && event.dataTransfer.files.length > 0) {
      this.uploadFiles(Array.from(event.dataTransfer.files));
    }
  }

  onDragOver(event: DragEvent): void {
    event.preventDefault();
    this.dragOver = true;
  }

  onDragLeave(event: DragEvent): void {
    event.preventDefault();
    this.dragOver = false;
  }

  private uploadFiles(files: File[]): void {
    if (this.images.length + files.length > this.maxImages) {
      this.toastService.error(`Máximo ${this.maxImages} imágenes por espacio`);
      return;
    }

    // Validar archivos
    const validFiles = files.filter(file => {
      if (!file.type.startsWith('image/')) {
        this.toastService.error(`${file.name} no es una imagen válida`);
        return false;
      }
      if (file.size > 5 * 1024 * 1024) { // 5MB
        this.toastService.error(`${file.name} supera los 5MB`);
        return false;
      }
      return true;
    });

    if (validFiles.length === 0) return;

    this.uploading = true;

    // Subir cada archivo
    let uploaded = 0;
    validFiles.forEach((file, index) => {
      const isPrimary = this.images.length === 0 && index === 0;

      console.log(`📤 Subiendo ${index + 1}/${validFiles.length}:`, file.name);

      this.imagesService.uploadImage(this.spaceId, file, isPrimary).subscribe({
        next: (image: SpaceImage) => {
          console.log('✅ Imagen subida:', image);
          this.images.push(image);
          uploaded++;

          if (uploaded === validFiles.length) {
            this.uploading = false;
            this.sortImages();
            this.imagesChange.emit(this.images);
            this.toastService.success(`${uploaded} imagen(es) subidas correctamente`);
          }
        },
        error: (error: any) => {
          console.error('❌ Error subiendo imagen:', {
            fileName: file.name,
            status: error.status,
            statusText: error.statusText,
            error: error.error,
            message: error.message
          });

          let errorMsg = 'Error al subir la imagen';
          if (error.status === 400) {
            errorMsg = error.error?.message || 'Formato de imagen inválido';
          } else if (error.status === 413) {
            errorMsg = 'Imagen demasiado grande (máx 5MB)';
          } else if (error.status === 401) {
            errorMsg = 'No autorizado. Inicia sesión nuevamente';
          }

          this.toastService.error(`${file.name}: ${errorMsg}`);
          uploaded++;

          if (uploaded === validFiles.length) {
            this.uploading = false;
          }
        }
      });
    });
  }

  deleteImage(image: SpaceImage): void {
    if (!confirm(`¿Eliminar la imagen "${image.altText || 'sin nombre'}"?`)) return;

    console.log('🗑️ Eliminando imagen:', image.id);

    this.imagesService.deleteImage(this.spaceId, image.id).subscribe({
      next: () => {
        console.log('✅ Imagen eliminada del backend:', image.id);

        // Filtrar la imagen eliminada
        const updatedImages = this.images.filter(img => img.id !== image.id);
        console.log(`📊 Imágenes restantes: ${updatedImages.length} (antes: ${this.images.length})`);

        // Actualizar el array local
        this.images = updatedImages;

        // Emitir cambio al componente padre
        this.imagesChange.emit([...this.images]); // Enviar copia para evitar mutación

        this.toastService.success('Imagen eliminada correctamente');
      },
      error: (error: any) => {
        console.error('❌ Error eliminando imagen:', error);
        this.toastService.error('Error al eliminar la imagen');
      }
    });
  }

  setPrimary(image: SpaceImage): void {
    this.imagesService.setPrimaryImage(this.spaceId, image.id).subscribe({
      next: (updatedImage: SpaceImage) => {
        // Desmarcar todas
        this.images.forEach(img => img.isPrimary = false);
        // Marcar la seleccionada
        const index = this.images.findIndex(img => img.id === image.id);
        if (index !== -1) {
          this.images[index] = updatedImage;
        }
        this.imagesChange.emit(this.images);
        this.toastService.success('Imagen principal actualizada');
      },
      error: (error: any) => {
        console.error('Error:', error);
        this.toastService.error('Error al establecer imagen principal');
      }
    });
  }

  private sortImages(): void {
    this.images.sort((a, b) => a.displayOrder - b.displayOrder);
  }

  get canUploadMore(): boolean {
    return this.images.length < this.maxImages;
  }

  get primaryImage(): SpaceImage | undefined {
    return this.images.find(img => img.isPrimary);
  }
}

