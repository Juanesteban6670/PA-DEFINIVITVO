const GEOLOCATION_OPTIONS = {
  enableHighAccuracy: true,
  maximumAge: 15_000,
  timeout: 20_000,
}

export function getLocationErrorMessage(error) {
  if (!window.isSecureContext) {
    return 'Safari solo permite usar el GPS en una página HTTPS. Abre la versión segura del sitio y vuelve a intentarlo.'
  }

  if (error?.code === 1) {
    return 'No se concedió el permiso de ubicación. Permítelo para este sitio en los ajustes del navegador y verifica que la Localización del dispositivo esté activa.'
  }
  if (error?.code === 2) {
    return 'El dispositivo no pudo determinar tu ubicación. Comprueba que Localización esté activa e inténtalo de nuevo.'
  }
  if (error?.code === 3) {
    return 'La ubicación tardó demasiado. Muévete a un lugar con mejor señal e inténtalo de nuevo.'
  }
  return 'No se pudo obtener la ubicación. Revisa los permisos y los servicios de localización e inténtalo de nuevo.'
}

export function getCurrentPosition(options = {}) {
  if (!window.isSecureContext) {
    return Promise.reject(new Error(getLocationErrorMessage()))
  }
  if (!navigator.geolocation) {
    return Promise.reject(new Error('Este navegador no ofrece servicios de ubicación.'))
  }

  return new Promise((resolve, reject) => {
    navigator.geolocation.getCurrentPosition(
      resolve,
      error => reject(new Error(getLocationErrorMessage(error))),
      { ...GEOLOCATION_OPTIONS, ...options },
    )
  })
}
