#!/bin/bash
# Script wrapper para ejecutar main.py desde n8n
# Recibe el DNI por stdin

DNI=$(cat)

# Cambiar al directorio del script
cd /home/admin/Documents/chat-bot-totem/vcc-totem

# Ejecutar Python con el DNI
python3 src/main.py <<< "$DNI"
