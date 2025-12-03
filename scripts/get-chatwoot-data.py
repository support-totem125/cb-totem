#!/usr/bin/env python3

"""
Script para obtener usuarios de Chatwoot y ver sus labels
Exporta datos a JSON y CSV opcionales
"""

import subprocess
import json
import csv
from datetime import datetime
from pathlib import Path
import sys

class ChatwootDataExporter:
    def __init__(self):
        self.data = {
            'usuarios': [],
            'labels': [],
            'contactos': [],
            'conversaciones': [],
            'resumen': {}
        }
        self.timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        
    def run_query(self, query):
        """Ejecuta una query SQL en Chatwoot"""
        cmd = [
            'docker', 'compose', 'exec', '-T', 'postgres_db',
            'psql', '-U', 'postgres', '-d', 'chatwoot',
            '-c', query, '--json'
        ]
        
        try:
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                check=True
            )
            # Remover líneas vacías y parse JSON
            lines = [l for l in result.stdout.split('\n') if l.strip()]
            if lines:
                return json.loads(lines[-1])
            return []
        except subprocess.CalledProcessError as e:
            print(f"❌ Error ejecutando query: {e.stderr}")
            return []
    
    def get_usuarios(self):
        """Obtiene todos los usuarios"""
        print("📋 Obteniendo usuarios...")
        query = """
        SELECT 
            id,
            name,
            email,
            role,
            confirmed_at IS NOT NULL as confirmado,
            created_at::text as fecha_creacion
        FROM users
        ORDER BY id;
        """
        self.data['usuarios'] = self.run_query(query)
        return len(self.data['usuarios'])
    
    def get_labels(self):
        """Obtiene todos los labels"""
        print("🏷️  Obteniendo labels...")
        query = """
        SELECT 
            id,
            title,
            description,
            color,
            account_id,
            created_at::text as fecha_creacion
        FROM labels
        ORDER BY title;
        """
        self.data['labels'] = self.run_query(query)
        return len(self.data['labels'])
    
    def get_contactos(self):
        """Obtiene contactos y sus labels"""
        print("👥 Obteniendo contactos con labels...")
        query = """
        SELECT 
            c.id as contacto_id,
            c.name as contacto_nombre,
            c.phone_number,
            c.email,
            STRING_AGG(l.title, ', ') as labels,
            c.created_at::text as fecha_creacion
        FROM contacts c
        LEFT JOIN taggings t ON c.id = t.taggable_id AND t.taggable_type = 'Contact'
        LEFT JOIN tags tag ON t.tag_id = tag.id
        LEFT JOIN labels l ON tag.id = l.tag_id
        GROUP BY c.id, c.name, c.phone_number, c.email, c.created_at
        ORDER BY c.name;
        """
        self.data['contactos'] = self.run_query(query)
        return len(self.data['contactos'])
    
    def get_conversaciones(self):
        """Obtiene conversaciones y sus labels"""
        print("💬 Obteniendo conversaciones con labels...")
        query = """
        SELECT 
            conv.id as conversacion_id,
            conv.display_id,
            c.name as contacto,
            a.name as agente,
            conv.status,
            STRING_AGG(DISTINCT l.title, ', ') as labels,
            conv.message_count,
            conv.created_at::text as fecha_inicio,
            EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - conv.created_at))/3600 as horas_activa
        FROM conversations conv
        LEFT JOIN contacts c ON conv.contact_id = c.id
        LEFT JOIN users a ON conv.assignee_id = a.id
        LEFT JOIN taggings t ON conv.id = t.taggable_id AND t.taggable_type = 'Conversation'
        LEFT JOIN tags tag ON t.tag_id = tag.id
        LEFT JOIN labels l ON tag.id = l.tag_id
        GROUP BY conv.id, c.name, a.name, conv.status, conv.message_count, conv.created_at
        ORDER BY conv.created_at DESC
        LIMIT 50;
        """
        self.data['conversaciones'] = self.run_query(query)
        return len(self.data['conversaciones'])
    
    def get_resumen(self):
        """Obtiene estadísticas generales"""
        print("📊 Obteniendo estadísticas...")
        
        queries = {
            'total_usuarios': 'SELECT COUNT(*) as total FROM users;',
            'total_contactos': 'SELECT COUNT(*) as total FROM contacts;',
            'total_conversaciones': 'SELECT COUNT(*) as total FROM conversations;',
            'total_labels': 'SELECT COUNT(*) as total FROM labels;',
            'usuarios_por_rol': """
                SELECT role, COUNT(*) as cantidad
                FROM users GROUP BY role;
            """,
            'conversaciones_por_estado': """
                SELECT status, COUNT(*) as cantidad
                FROM conversations GROUP BY status;
            """
        }
        
        for key, query in queries.items():
            result = self.run_query(query)
            self.data['resumen'][key] = result
    
    def print_resumen(self):
        """Imprime un resumen formateado"""
        print("\n" + "="*60)
        print("📊 RESUMEN DE DATOS - CHATWOOT")
        print("="*60 + "\n")
        
        resumen = self.data['resumen']
        
        # Estadísticas totales
        if resumen.get('total_usuarios'):
            print(f"👤 Total de usuarios: {resumen['total_usuarios'][0]['total']}")
        if resumen.get('total_contactos'):
            print(f"👥 Total de contactos: {resumen['total_contactos'][0]['total']}")
        if resumen.get('total_conversaciones'):
            print(f"💬 Total de conversaciones: {resumen['total_conversaciones'][0]['total']}")
        if resumen.get('total_labels'):
            print(f"🏷️  Total de labels: {resumen['total_labels'][0]['total']}")
        
        # Usuarios por rol
        if resumen.get('usuarios_por_rol'):
            print("\n📋 Usuarios por rol:")
            for row in resumen['usuarios_por_rol']:
                print(f"   - {row['role']}: {row['cantidad']}")
        
        # Conversaciones por estado
        if resumen.get('conversaciones_por_estado'):
            print("\n💬 Conversaciones por estado:")
            for row in resumen['conversaciones_por_estado']:
                print(f"   - {row['status']}: {row['cantidad']}")
        
        print("\n" + "="*60 + "\n")
    
    def print_usuarios(self):
        """Imprime tabla de usuarios"""
        if not self.data['usuarios']:
            return
        
        print("\n📋 USUARIOS CHATWOOT")
        print("-" * 80)
        print(f"{'ID':<5} {'Nombre':<25} {'Email':<30} {'Rol':<12} {'Confirmado':<10}")
        print("-" * 80)
        
        for user in self.data['usuarios']:
            confirmado = "✓" if user.get('confirmado') else "✗"
            print(f"{user.get('id'):<5} {user.get('name', ''):<25} {user.get('email', ''):<30} {user.get('role', ''):<12} {confirmado:<10}")
        
        print("-" * 80 + "\n")
    
    def print_labels(self):
        """Imprime tabla de labels"""
        if not self.data['labels']:
            return
        
        print("\n🏷️  LABELS DISPONIBLES")
        print("-" * 100)
        print(f"{'ID':<5} {'Título':<25} {'Descripción':<40} {'Color':<10}")
        print("-" * 100)
        
        for label in self.data['labels']:
            desc = (label.get('description') or 'N/A')[:40]
            print(f"{label.get('id'):<5} {label.get('title', ''):<25} {desc:<40} {label.get('color', ''):<10}")
        
        print("-" * 100 + "\n")
    
    def print_contactos(self):
        """Imprime tabla de contactos"""
        if not self.data['contactos']:
            print("❌ Sin contactos")
            return
        
        print("\n👥 CONTACTOS CON LABELS")
        print("-" * 120)
        print(f"{'ID':<5} {'Nombre':<25} {'Teléfono':<15} {'Labels':<50}")
        print("-" * 120)
        
        for contact in self.data['contactos'][:20]:  # Primeros 20
            labels = contact.get('labels') or 'Sin labels'
            labels = (labels[:50] + '...') if len(labels) > 50 else labels
            print(f"{contact.get('contacto_id'):<5} {contact.get('contacto_nombre', ''):<25} {contact.get('phone_number', ''):<15} {labels:<50}")
        
        if len(self.data['contactos']) > 20:
            print(f"\n... y {len(self.data['contactos']) - 20} contactos más")
        
        print("-" * 120 + "\n")
    
    def print_conversaciones(self):
        """Imprime tabla de conversaciones"""
        if not self.data['conversaciones']:
            print("❌ Sin conversaciones")
            return
        
        print("\n💬 ÚLTIMAS CONVERSACIONES CON LABELS")
        print("-" * 130)
        print(f"{'ID':<5} {'Display':<10} {'Contacto':<20} {'Agente':<15} {'Estado':<10} {'Labels':<50}")
        print("-" * 130)
        
        for conv in self.data['conversaciones'][:15]:  # Primeras 15
            labels = conv.get('labels') or 'Sin labels'
            labels = (labels[:45] + '...') if len(labels) > 45 else labels
            contacto = (conv.get('contacto') or 'N/A')[:20]
            agente = (conv.get('agente') or 'Sin asignar')[:15]
            print(f"{conv.get('conversacion_id'):<5} {conv.get('display_id', ''):<10} {contacto:<20} {agente:<15} {conv.get('status', ''):<10} {labels:<50}")
        
        if len(self.data['conversaciones']) > 15:
            print(f"\n... y {len(self.data['conversaciones']) - 15} conversaciones más")
        
        print("-" * 130 + "\n")
    
    def export_json(self):
        """Exporta datos a JSON"""
        filename = f"chatwoot_export_{self.timestamp}.json"
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(self.data, f, indent=2, ensure_ascii=False)
        print(f"✓ Datos exportados a: {filename}")
        return filename
    
    def run(self):
        """Ejecuta el proceso completo"""
        print("🚀 Iniciando extracción de datos de Chatwoot...\n")
        
        try:
            self.get_usuarios()
            self.get_labels()
            self.get_contactos()
            self.get_conversaciones()
            self.get_resumen()
            
            # Mostrar resultados
            self.print_resumen()
            self.print_usuarios()
            self.print_labels()
            self.print_contactos()
            self.print_conversaciones()
            
            # Exportar a JSON
            json_file = self.export_json()
            
            print("\n✅ Proceso completado exitosamente")
            print(f"📁 Archivo JSON disponible: {json_file}")
            
        except Exception as e:
            print(f"❌ Error: {e}")
            sys.exit(1)

if __name__ == "__main__":
    exporter = ChatwootDataExporter()
    exporter.run()
