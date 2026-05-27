@echo off
title StockMind — Iniciador del Sistema
echo  Sistema Inteligente de Gestion de Inventario
echo  -----------------------------------------------
echo.
color 0E
echo  ANTES DE CONTINUAR, VERIFICA LO SIGUIENTE:
echo.
echo  [1] XAMPP esta abierto y MySQL esta en verde (Started) (net start MySQL80)
echo  [2] La base de datos stockmind_db esta creada en phpMyAdmin
echo  [3] Los scripts schema.sql y seed.sql ya fueron ejecutados
echo.
color 0C
echo  Si alguno de esos puntos NO esta listo, cierra esta ventana
echo  y configura XAMPP primero antes de continuar.
echo.
color 0A
pause
echo.
color 0F
echo  Todo listo? Perfecto. Iniciando servicios...
echo.
echo  [1/4] Iniciando Backend Java (Puerto 8080)...
start "StockMind — Java Backend" cmd /k "cd /d %~dp0backend && mvn spring-boot:run"
timeout /t 2 /nobreak >nul
echo  [2/4] Iniciando Microservicio Python (Puerto 8000)...
start "StockMind — Python Analytics" cmd /k "cd /d %~dp0analytics && venv\Scripts\activate && python app.py"
timeout /t 2 /nobreak >nul
echo  [3/4] Iniciando Gateway Node.js (Puerto 3000)...
start "StockMind — Node Gateway" cmd /k "cd /d %~dp0gateway && npm start"
timeout /t 2 /nobreak >nul
echo  [4/4] Iniciando Frontend React (Puerto 5173)...
start "StockMind — Frontend React" cmd /k "cd /d %~dp0frontend && npm run dev"
timeout /t 2 /nobreak >nul
echo.
color 0A
echo  ============================================
echo   Todos los servicios iniciando...
echo  ============================================
echo.
echo   Frontend  →  http://localhost:5173
echo   Gateway   →  http://localhost:3000
echo   Java      →  http://localhost:8080
echo   Python    →  http://localhost:8000
echo.
echo  IMPORTANTE: Espera 30-40 segundos a que Java
echo  termine de arrancar antes de abrir el sistema.
echo  Cuando veas "Started StockmindApplication"
echo  en la ventana de Java, ya podas entrar.
echo.
echo  Usuario: admin
echo  Password: admin123
echo.
echo  ============================================
echo.
timeout /t 5 /nobreak >nul
start http://localhost:5173
echo  Abriendo el navegador automaticamente...
echo  Si no abre, entra manualmente a http://localhost:5173
echo.
pause