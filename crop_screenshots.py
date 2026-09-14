import tkinter as tk
from tkinter import filedialog, messagebox
from PIL import Image
import os

def crop_to_9_16(image_path):
    try:
        img = Image.open(image_path)
        width, height = img.size
        
        # Proporción objetivo 9:16 = 0.5625
        target_ratio = 9 / 16.0
        current_ratio = width / height
        
        if abs(current_ratio - target_ratio) < 0.01:
            print(f"La imagen {os.path.basename(image_path)} ya tiene proporción 9:16.")
            # Solo redimensionar si es necesario, o guardarla
            img_resized = img.resize((1080, 1920), Image.Resampling.LANCZOS)
        elif current_ratio > target_ratio:
            # La imagen es muy ancha, recortar los lados (width)
            new_width = int(height * target_ratio)
            left = (width - new_width) / 2
            right = left + new_width
            top = 0
            bottom = height
            img = img.crop((left, top, right, bottom))
            img_resized = img.resize((1080, 1920), Image.Resampling.LANCZOS)
        else:
            # La imagen es muy alta, recortar arriba y abajo (height)
            new_height = int(width / target_ratio)
            top = (height - new_height) / 2
            bottom = top + new_height
            left = 0
            right = width
            img = img.crop((left, top, right, bottom))
            img_resized = img.resize((1080, 1920), Image.Resampling.LANCZOS)
        
        # Guardar la nueva imagen
        base, ext = os.path.splitext(image_path)
        if ext.lower() not in ['.png', '.jpg', '.jpeg']:
            ext = '.png'
        new_path = f"{base}_9x16{ext}"
        
        # Convertir RGBA a RGB si es JPEG
        if ext.lower() in ['.jpg', '.jpeg'] and img_resized.mode == 'RGBA':
            img_resized = img_resized.convert('RGB')
            
        img_resized.save(new_path, quality=95)
        return new_path
    except Exception as e:
        print(f"Error procesando {image_path}: {e}")
        return None

def main():
    root = tk.Tk()
    root.withdraw() # Ocultar la ventana principal
    
    # Mostrar la ventana en macOS
    root.call('wm', 'attributes', '.', '-topmost', True)
    
    file_paths = filedialog.askopenfilenames(
        title='Selecciona las capturas de pantalla de tu juego',
        filetypes=[('Imágenes', '*.png *.jpg *.jpeg')]
    )
    
    if file_paths:
        procesadas = 0
        for path in file_paths:
            print(f"Procesando: {os.path.basename(path)}...")
            if crop_to_9_16(path):
                procesadas += 1
                
        mensaje = f"¡Listo! Se procesaron {procesadas} imágenes.\nSe guardaron con el sufijo '_9x16' en la misma carpeta original."
        print(mensaje)
        messagebox.showinfo("Proceso Terminado", mensaje)
    else:
        print("No se seleccionó ninguna imagen.")

if __name__ == '__main__':
    main()
