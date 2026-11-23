# Plan de cierre de Cartagena Segura

En la revisión local pasaron 65 pruebas de Flutter y 13 del backend. Se compiló la web y el APK candidato 1.2.3 (build 6). En Chrome y en el emulador Android se envió un reporte con foto y se abrió su detalle desde la notificación. El ensayo aislado verificó la persistencia en GridFS, los permisos y el reenvío idempotente. El APK local usa firma de prueba. La actualización desde el APK público requiere la firma oficial.

## 1. Proteger los datos y revisar Render

- Mantener `DEMO_SEED_ENABLED=false` en producción. Usar una base aislada para la demostración con datos sintéticos.
- Confirmar que la portada, `/Login`, `/actuator/health` y `/api/System/Version` respondan. Revisar el arranque del último despliegue en Render si vuelve a faltar respuesta.
- Probar el mapa sin sesión, la lectura de evidencias con los roles correspondientes y la persistencia de archivos tras recrear el backend.

## 2. Verificar Android

- Compilar **1.2.3 (build 6)**. Ejecutar `flutter analyze` y `flutter test`. En GitHub Actions, `sign_candidate` genera el APK con la firma oficial sin publicarlo. La compilación comprueba la firma, el identificador y el incremento de versión con `scripts/verify_android_update.sh`.
- Instalar el APK oficial 1.2.2, iniciar sesión y guardar un borrador. Instalar el candidato encima y verificar que conserva la sesión y el borrador.
- Probar un recordatorio en segundo plano, con permiso denegado y después de cancelar o enviar el reporte. Confirmar un solo aviso por recordatorio.

## 3. Ensayar la entrega

- En la web y Android, crear un reporte con foto como ciudadano, actualizar el estado como administrador y abrir el reporte desde la notificación. Repetir el envío tras simular una pérdida de conexión y comprobar que existe un solo reporte.
- Ejecutar `scripts/smoke_report.py` contra una instancia local aislada. El workflow web y backend prepara cuentas temporales y verifica evidencia, acceso por rol, idempotencia, cambio de estado y notificación.
- Revisar que el panel y el informe identifiquen las cifras predictivas como ilustrativas.

## 4. Publicar el candidato aprobado

- Coordinar la salida del APK y del backend con evidencia privada. El APK 1.2.2 pide las imágenes gestionadas sin credenciales. Tras activar la protección, las fotos privadas se consultan desde la web actualizada o el APK nuevo.
- Publicar desde el mismo commit del candidato firmado que se probó y comprobar el archivo que se descarga desde `app-latest`. Ajustar `ANDROID_LATEST_VERSION` en Render cuando el binario 1.2.3 esté accesible.
- Verificar la descarga, la actualización sobre 1.2.2 y la versión anunciada por la API. Repetir la prueba de salud y el flujo de la demostración.
