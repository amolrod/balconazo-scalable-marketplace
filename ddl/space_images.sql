-- Tabla de imágenes de espacios
CREATE TABLE IF NOT EXISTS catalog.space_images (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    space_id UUID NOT NULL REFERENCES catalog.spaces(id) ON DELETE CASCADE,
    url VARCHAR(500) NOT NULL,
    display_order INTEGER NOT NULL DEFAULT 0,
    is_primary BOOLEAN NOT NULL DEFAULT FALSE,
    alt_text VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Índices para mejorar performance
CREATE INDEX IF NOT EXISTS idx_space_images_space_id ON catalog.space_images(space_id);
CREATE INDEX IF NOT EXISTS idx_space_images_display_order ON catalog.space_images(space_id, display_order);
CREATE INDEX IF NOT EXISTS idx_space_images_primary ON catalog.space_images(space_id, is_primary) WHERE is_primary = TRUE;

-- Comentarios
COMMENT ON TABLE catalog.space_images IS 'Imágenes de los espacios';
COMMENT ON COLUMN catalog.space_images.display_order IS 'Orden de visualización (0 = primera)';
COMMENT ON COLUMN catalog.space_images.is_primary IS 'Indica si es la imagen principal del espacio';

