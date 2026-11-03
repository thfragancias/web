# Configurar el panel privado de TH Fragancias

El panel permite agregar, editar, ocultar y eliminar perfumes; cambiar precios y descripciones; asignar género, aromas y temporadas; y subir fotos. La tienda pública lee el catálogo de Supabase.

## 1. Crear el proyecto

1. Entrá en [Supabase](https://supabase.com/) y creá un proyecto.
2. Elegí una contraseña segura para la base de datos y guardala en un lugar seguro.
3. Cuando termine de crearse, abrí **Project Settings → API Keys** (o **Connect**) y copiá:
   - **Project URL**
   - **Publishable key** (empieza normalmente por `sb_publishable_`).

No copies ni compartas la **Secret key** ni una clave `service_role`. El sitio usa solamente la Publishable key; los permisos reales se controlan con RLS en la base de datos.

## 2. Crear las tablas y permisos

1. En Supabase abrí **SQL Editor → New query**.
2. Abrí el archivo `supabase-setup.sql` de este repositorio, copiá todo su contenido y pegalo en el editor.
3. Ejecutá la consulta. Esto crea las tablas, los permisos, el almacenamiento de fotos y carga los dos perfumes que ya están en el catálogo.

## 3. Crear tu usuario administrador

1. En Supabase abrí **Authentication → Users → Add user → Create new user**.
2. Creá tu usuario con tu correo y una contraseña propia. No necesitás habilitar el registro público.
3. Copiá el **UID** de ese usuario.
4. Volvé al **SQL Editor** y ejecutá, reemplazando el UUID de ejemplo por tu UID:

```sql
insert into public.admin_users (user_id)
values ('PEGAR-ACA-EL-UID');
```

Solamente los UID agregados a `admin_users` pueden escribir, modificar o borrar productos.

## 4. Conectar la web

1. En GitHub abrí el archivo `supabase-config.js`.
2. Reemplazá los valores vacíos por el Project URL y la Publishable key de tu proyecto:

```js
window.TH_SUPABASE_CONFIG = {
  url: "https://TU-PROYECTO.supabase.co",
  publishableKey: "sb_publishable_TU_CLAVE"
};
```

3. Guardá el archivo con **Commit changes**. La Publishable key está diseñada para usarse en el navegador; nunca pongas una Secret key o service_role aquí.

## 5. Entrar al panel

Cuando GitHub Pages termine de publicar, abrí:

[https://thfragancias.github.io/web/admin.html](https://thfragancias.github.io/web/admin.html)

Ingresá con el correo y la contraseña que creaste en Supabase. Desde ahí podés agregar, editar, ocultar, eliminar y subir fotos de perfumes.

## Importante

- Los dos perfumes actuales se cargan desde el SQL. Sus fotos actuales se conservan en la tienda como respaldo hasta que reemplaces/subas una imagen desde el panel.
- Para imágenes nuevas se aceptan JPG, PNG o WEBP de hasta 5 MB.
- La tienda solo muestra productos activos.
- Las cuentas que no estén en `admin_users` no pueden modificar el catálogo.
- No compartas contraseñas, Secret keys ni service_role.
