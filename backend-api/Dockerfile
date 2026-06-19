# 1. Usamos una versión estable y ligera de Node.js
FROM node:18-alpine

# 2. Creamos el directorio de trabajo dentro del contenedor
WORKDIR /app

# 3. Copiamos los archivos de dependencias
COPY package*.json ./

# 4. Instalamos las dependencias
RUN npm install

# 5. Copiamos el resto del código del backend
COPY . .

# 6. Exponemos el puerto del servidor
EXPOSE 3000

# 7. Comando para arrancar la app
CMD ["node", "server.js"]