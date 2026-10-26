# Sirve el build web ya compilado (`flutter build web --release`) —
# no compila adentro del contenedor a propósito: evita tener que
# instalar el SDK de Flutter completo en la imagen solo para servir
# archivos estáticos. Correr `flutter build web` antes de construir
# esta imagen (ver README/instrucciones de despliegue local).
FROM nginx:1.27-alpine

COPY build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
