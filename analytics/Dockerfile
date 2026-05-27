FROM python:3.11-slim

WORKDIR /app

# Actualizar pip primero — evita conflictos de instalación
RUN pip install --upgrade pip

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8000
CMD ["python", "app.py"]
