Cambios Propuestos
1. UI / Pantallas

    UploadDocumentScreen – Formulario con:

        Entrada de texto para el nombre del documento.

        Entrada de etiquetas (selector de chips o lista separada por comas).

        Botón selector de archivos.

        Botón de envío con validación.

    ProfileScreen – Mostrar información del usuario, un botón para navegar a una subpantalla de configuración, lista de favoritos del usuario y lista de documentos subidos.

    DocumentViewerScreen – Visor centralizado que detecta el tipo de archivo:

        PDF: usar flutter_pdfview o pdfx.

        Imagen: Image.memory/Image.file.

        Enlace: abrir con url_launcher.

        Proporcionar acciones para compartir/descargar.


2. Gestión de Estado / Providers

    SearchProvider – Completar la lógica faltante para almacenar consultas de búsqueda recientes, manejar paginación y exponer un método viewDocument que proporcione el documento seleccionado a DocumentViewerScreen.

    AuthProvider – Asegurar que el flujo de registro capture todos los campos requeridos (rol, IDs de carrera) y almacene el token de autenticación de forma segura (ej., shared_preferences).

    DocumentProvider (nuevo) – Gestionar lista de documentos, estado de carga, favoritos y operaciones CRUD.

3. Integración con el Backend

    Añadir endpoints de API en ApiService para:

        Cargar un documento (POST /documents).

        Actualizar perfil de usuario (PUT /users/{id}).

        Marcar favoritos (POST /documents/{id}/favorite).

    Implementar manejo adecuado de errores, indicadores de carga y lógica de reintento.

5. Misceláneos

    Eliminar todos los comentarios TODO de los archivos de compilación de Android/iOS o reemplazarlos con la configuración adecuada.

    Escribir pruebas unitarias para los providers y el servicio de API.

    Añadir pruebas de integración para los flujos principales de usuario (login → panel de control → ver/cargar documento).

    Optimizar el rendimiento: habilitar caché de imágenes, cargar listas de documentos de forma diferida y usar ContentVisibility cuando sea posible.

Plan de Verificación
Pruebas Automatizadas

    Ejecutar flutter test después de añadir pruebas unitarias para cada provider.

    Ejecutar la suite de pruebas de integración flutter drive que cubra el recorrido completo del usuario.

Verificación Manual

    Compilar la aplicación en simuladores de Android e iOS; verificar que la UI coincida exactamente con los dos mockups de diseño (ubicación del logo, colores, espaciado, microanimaciones).

    Probar la carga de documentos PDF, imagen y enlace; asegurar una renderización adecuada en el visor.

    Confirmar que el panel de control muestra estadísticas de resumen correctas y que la navegación funciona.

    Validar que las ediciones de perfil persistan y que los favoritos se almacenen correctamente.