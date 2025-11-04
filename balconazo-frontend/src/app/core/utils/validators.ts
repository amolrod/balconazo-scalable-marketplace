import { AbstractControl, ValidationErrors, ValidatorFn } from '@angular/forms';

/**
 * Custom Validators
 * Validadores personalizados para formularios de Angular
 */

/**
 * Valida que el email tenga formato correcto
 */
export function emailValidator(): ValidatorFn {
  return (control: AbstractControl): ValidationErrors | null => {
    if (!control.value) {
      return null; // Don't validate empty values (use Validators.required for that)
    }

    const emailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
    const valid = emailRegex.test(control.value);

    return valid ? null : { invalidEmail: { value: control.value } };
  };
}

/**
 * Valida que el precio esté dentro del rango permitido
 */
export function priceRangeValidator(min: number = 5, max: number = 500): ValidatorFn {
  return (control: AbstractControl): ValidationErrors | null => {
    if (!control.value && control.value !== 0) {
      return null;
    }

    const price = Number(control.value);

    if (isNaN(price)) {
      return { invalidPrice: { value: control.value } };
    }

    if (price < min) {
      return { priceMin: { min, actual: price } };
    }

    if (price > max) {
      return { priceMax: { max, actual: price } };
    }

    return null;
  };
}

/**
 * Valida que la capacidad sea un número positivo
 */
export function capacityValidator(): ValidatorFn {
  return (control: AbstractControl): ValidationErrors | null => {
    if (!control.value && control.value !== 0) {
      return null;
    }

    const capacity = Number(control.value);

    if (isNaN(capacity)) {
      return { invalidCapacity: { value: control.value } };
    }

    if (capacity < 1) {
      return { capacityMin: { min: 1, actual: capacity } };
    }

    if (capacity > 1000) {
      return { capacityMax: { max: 1000, actual: capacity } };
    }

    return null;
  };
}

/**
 * Valida coordenadas de latitud
 */
export function latitudeValidator(): ValidatorFn {
  return (control: AbstractControl): ValidationErrors | null => {
    if (!control.value && control.value !== 0) {
      return null;
    }

    const lat = Number(control.value);

    if (isNaN(lat)) {
      return { invalidLatitude: { value: control.value } };
    }

    if (lat < -90 || lat > 90) {
      return { latitudeRange: { min: -90, max: 90, actual: lat } };
    }

    return null;
  };
}

/**
 * Valida coordenadas de longitud
 */
export function longitudeValidator(): ValidatorFn {
  return (control: AbstractControl): ValidationErrors | null => {
    if (!control.value && control.value !== 0) {
      return null;
    }

    const lon = Number(control.value);

    if (isNaN(lon)) {
      return { invalidLongitude: { value: control.value } };
    }

    if (lon < -180 || lon > 180) {
      return { longitudeRange: { min: -180, max: 180, actual: lon } };
    }

    return null;
  };
}

/**
 * Valida que la fecha sea futura
 */
export function futureDateValidator(): ValidatorFn {
  return (control: AbstractControl): ValidationErrors | null => {
    if (!control.value) {
      return null;
    }

    const inputDate = new Date(control.value);
    const now = new Date();

    if (inputDate <= now) {
      return { pastDate: { value: control.value } };
    }

    return null;
  };
}

/**
 * Valida que dos controles tengan el mismo valor (útil para confirmar contraseña)
 */
export function matchFieldsValidator(fieldName: string): ValidatorFn {
  return (control: AbstractControl): ValidationErrors | null => {
    if (!control.parent) {
      return null;
    }

    const field = control.parent.get(fieldName);
    if (!field) {
      return null;
    }

    if (control.value !== field.value) {
      return { fieldsDoNotMatch: { field: fieldName } };
    }

    return null;
  };
}

/**
 * Valida longitud mínima de caracteres
 */
export function minLengthValidator(minLength: number): ValidatorFn {
  return (control: AbstractControl): ValidationErrors | null => {
    if (!control.value) {
      return null;
    }

    const value = String(control.value);

    if (value.length < minLength) {
      return { minLength: { requiredLength: minLength, actualLength: value.length } };
    }

    return null;
  };
}

/**
 * Valida longitud máxima de caracteres
 */
export function maxLengthValidator(maxLength: number): ValidatorFn {
  return (control: AbstractControl): ValidationErrors | null => {
    if (!control.value) {
      return null;
    }

    const value = String(control.value);

    if (value.length > maxLength) {
      return { maxLength: { requiredLength: maxLength, actualLength: value.length } };
    }

    return null;
  };
}

/**
 * Valida que el valor sea un número positivo
 */
export function positiveNumberValidator(): ValidatorFn {
  return (control: AbstractControl): ValidationErrors | null => {
    if (!control.value && control.value !== 0) {
      return null;
    }

    const value = Number(control.value);

    if (isNaN(value)) {
      return { notANumber: { value: control.value } };
    }

    if (value <= 0) {
      return { notPositive: { value } };
    }

    return null;
  };
}

/**
 * Valida formato de URL
 */
export function urlValidator(): ValidatorFn {
  return (control: AbstractControl): ValidationErrors | null => {
    if (!control.value) {
      return null;
    }

    try {
      new URL(control.value);
      return null;
    } catch {
      return { invalidUrl: { value: control.value } };
    }
  };
}

/**
 * Valida que el área esté dentro del rango permitido (m²)
 */
export function areaSqmValidator(min: number = 1, max: number = 10000): ValidatorFn {
  return (control: AbstractControl): ValidationErrors | null => {
    if (!control.value && control.value !== 0) {
      return null;
    }

    const area = Number(control.value);

    if (isNaN(area)) {
      return { invalidArea: { value: control.value } };
    }

    if (area < min) {
      return { areaMin: { min, actual: area } };
    }

    if (area > max) {
      return { areaMax: { max, actual: area } };
    }

    return null;
  };
}

