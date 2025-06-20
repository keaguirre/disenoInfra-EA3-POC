FROM python:3.13-alpine

# Instala dependencias del sistema necesarias para compilar paquetes de Python
RUN apk add --no-cache git gcc musl-dev libffi-dev python3-dev py3-pip

# Establece el directorio de trabajo
WORKDIR /app

# Clona el repositorio desde GitHub
RUN git clone https://github.com/keaguirre/disenoInfra-EA3-POC . 

# Instala las dependencias desde requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Expone el puerto en el que Flask va a correr
EXPOSE 5000

# Comando por defecto para iniciar la aplicación
CMD ["python", "app.py"]
