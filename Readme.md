# RaspeSetup 🍓🛠️

![Badge](https://img.shields.io/badge/License-MIT-blue)
![Badge](https://img.shields.io/badge/Version-1.0.0-green)

**RaspeSetup** es un script de instalación automatizada para dejar mi Raspberry Pi configurada como necesito: con servicios de sincronización, impresión 3D, compartición de archivos y una interfaz OLED personalizada. Está pensado para mi uso personal, pero puede servir como base para otros setups similares.

---

## 🎯 ¿Qué hace este script?

Este script configura todo lo necesario para que mi Raspberry Pi funcione como quiero, instalando y activando servicios clave como:

| Servicio             | Puerto(s)                    | Descripción                                                          |
| -------------------- | ---------------------------- | -------------------------------------------------------------------- |
| 🔄 Syncthing         | `8384`, `22000`, `21027/udp` | Sincronización de archivos entre mis dispositivos.                   |
| 🖨️ OctoPrint        | `5000`                       | Control de mi impresora 3D desde una interfaz web.                   |
| 🌐 DUFS              | `8000`                       | Servidor web simple para compartir archivos desde una carpeta local. |
| 📁 vsftpd            | `21`, `40000–50000`          | Acceso FTP seguro con chroot.                                        |
| 📟 OledFanButtonRasp | —                            | Control de ventilador y visualización en pantalla OLED vía I2C.      |

---

## ⚙️ Cómo usar

1. Clona el repositorio en tu Raspberry Pi.
2. Ejecuta el script como `sudo`:

```bash
git clone https://github.com/senchpimy/RaspeSetup.git
cd RaspeSetup
sudo ./instalar.sh
```

> ⚠️ **Importante**: El script debe ejecutarse con `sudo`, ya que configura servicios del sistema, usuarios y puertos.

---


## 🛠️ ¿Qué instala exactamente?

1. **Paquetes base:** `curl`, `git`, `python3`, `build-essential`, etc.
2. **Firewall (UFW):** Abre solo los puertos necesarios para los servicios anteriores.
3. **Syncthing:** Se instala desde el repositorio oficial y se activa como servicio.
4. **OctoPrint:** Se instala en un entorno virtual Python y corre como servicio.
5. **DUFS:** Se compila desde Rust y se instala como servicio web.
6. **vsftpd:** Configurado con jaula chroot para acceso controlado a archivos.
7. **OLED + ventilador:** Instala librerías de Python, activa I2C y configura el servicio `ofb.service`.

---

## 🧪 Estado

Este script es parte de mi setup personal, pero puedes adaptarlo a tus necesidades. Algunas secciones contienen `#TODO` para revisar:

* Verificar servicios con nombres hardcodeados como `plof`.
* Confirmar versiones específicas de DUFS u otras herramientas.

---

## 📝 Licencia

Este proyecto está licenciado bajo la **MIT License**.

