# Research: Escáner de documentos

Decisiones técnicas de la funcionalidad 009. Cada una indica la alternativa descartada.

## R1. Qué escáner

**Decisión**: el escáner de documentos de Google ML Kit, con el paquete
`google_mlkit_document_scanner` 0.5.0. Es la última versión que resuelve con Flutter 3.35
(la 0.7.0 exige uno más nuevo). Usa `play-services-mlkit-document-scanner` 16.0.0:
- la interfaz (cámara, bordes, recorte y filtros) la pone Google Play;
- el procesamiento es en el teléfono;
- no hace falta cuenta, clave ni el permiso de cámara de la app.

**Alternativas**:
- Detección de bordes propia (por ejemplo, con OpenCV): mucho código nativo y más peso.
- Paquetes de terceros con cámara propia: más permisos y menos precisión.

## R2. Modo del escáner

**Decisión**: `ScannerMode.filter`, que da recorte, giro y filtros, con salida JPEG y sin
importar desde la galería (para eso está «Elegir imagen guardada»).

**Alternativa**: `ScannerMode.full`, que además borra manchas y dedos con aprendizaje
automático. Podría borrar trazos de la escritura (constitución §3, fidelidad).

## R3. Cancelar y errores

Según el código del complemento (`DocumentScanner.kt`):
- cancelar llega como error con el mensaje `Operation cancelled`; la app lo trata como
  «no se eligió nada» [ED-H1-E5];
- si el escáner no puede abrirse (sin servicios de Google Play o sin el módulo), el
  mensaje es `Failed to start document scanner`, y la app usa `scannerUnavailable`, que
  ofrece tomar una fotografía [ED-H2-E1];
- cualquier otro error es `scannerFailed` [ED-H2-E2].

## R4. Archivos del escáner

**Decisión**: el escáner deja sus JPEG en la caché de la app. El servicio los lee en
memoria (`XFile.fromData`), los borra enseguida y cierra el escáner. Así, como con el
selector de 004, solo quedan las copias de trabajo de la app [ED-H3-E1].

## R5. Dónde entra en el flujo

**Decisión**: un origen nuevo, `ImageOrigin.scanner`, en el mismo camino de la galería y
la cámara (`_addImages` del controlador). Las hojas pasan por las mismas validaciones,
copias y límite de páginas [ED-H3-E2]. Reemplazar una hoja escaneada vuelve a abrir el
escáner con una página [ED-H3-E3].

## R6. Aviso con acción

**Decisión**: una acción nueva de aviso, `StatusAction.takePhoto`. En el inicio, el aviso
de escáner no disponible muestra «Tomar fotografía» [SC-904].

## R7. Qué agrega al APK

Revisado con `aapt2` en la versión final:
- la actividad del escáner de Google (`GmsDocumentScanningDelegateActivity`);
- el permiso `ACCESS_NETWORK_STATE`, que pide ML Kit;
- la biblioteca interna `com.google.firebase.components`, que ML Kit usa para registrar
  sus partes.

**No usa ningún servicio de Firebase** (ni cuenta, ni base de datos, ni analíticas), así
que se respeta la constitución §2 («Firebase no se adopta»). No pide permisos de
almacenamiento ni de ubicación.
