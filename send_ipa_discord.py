import os
import sys
import json
import asyncio
import discord
from dotenv import load_dotenv

load_dotenv()

BOT_TOKEN = os.getenv("BOT_TOKEN")
CHANNEL_ID = int(os.getenv("IPA_CHANNEL_ID", "1565299006932914176"))

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

# Read version info from cloud_config.json
cloud_cfg_path = os.path.join(BASE_DIR, "cloud_config.json")
version_str = "1.6.0"
build_num = 17
if os.path.exists(cloud_cfg_path):
    try:
        with open(cloud_cfg_path, "r", encoding="utf-8") as f:
            cfg = json.load(f)
            version_str = cfg.get("app_version", "1.6.0")
            build_num = cfg.get("app_build", 17)
    except Exception:
        pass

IPA_CANDIDATES = [
    os.path.join(BASE_DIR, "ipa nuevo", f"RodriguezLawnCare_v{version_str}_Build{build_num}.ipa"),
    os.path.join(BASE_DIR, "ipa online", f"RodriguezLawnCare_v{version_str}_Build{build_num}.ipa"),
    os.path.join(BASE_DIR, "ipa here", f"RodriguezLawnCare_v{version_str}_Build{build_num}.ipa"),
    os.path.join(BASE_DIR, "ipa nuevo", "rodriguezlawncareios.ipa"),
    os.path.join(BASE_DIR, "ipa online", "rodriguezlawncareios.ipa"),
    os.path.join(BASE_DIR, "RodriguezLawnCareIosAPP", "ipa nuevo", f"RodriguezLawnCare_v{version_str}_Build{build_num}.ipa"),
    os.path.join(BASE_DIR, "RodriguezLawnCareIosAPP", "ipa online", f"RodriguezLawnCare_v{version_str}_Build{build_num}.ipa"),
    os.path.join(BASE_DIR, "RodriguezLawnCareIosAPP", "ipa here", f"RodriguezLawnCare_v{version_str}_Build{build_num}.ipa"),
]

ipa_file_path = None
for p in IPA_CANDIDATES:
    if os.path.exists(p) and os.path.getsize(p) > 100000:
        ipa_file_path = p
        break

if not ipa_file_path:
    print("ERROR: Could not find any valid IPA file to upload!")
    sys.exit(1)

file_name_display = os.path.basename(ipa_file_path)
if file_name_display == "rodriguezlawncareios.ipa" or file_name_display == "RodriguezLawnCare.ipa":
    file_name_display = f"RodriguezLawnCare_v{version_str}_Build{build_num}.ipa"

file_size_bytes = os.path.getsize(ipa_file_path)
file_size_mb = file_size_bytes / (1024 * 1024)
print(f"Found IPA at: {ipa_file_path} ({file_size_mb:.2f} MB)")

intents = discord.Intents.default()
client = discord.Client(intents=intents)

async def main():
    if not BOT_TOKEN:
        print("ERROR: BOT_TOKEN is empty!")
        sys.exit(1)
        
    await client.login(BOT_TOKEN)
    channel = await client.fetch_channel(CHANNEL_ID)
    print(f"Target channel found: #{getattr(channel, 'name', channel.id)} (ID: {channel.id})")
    
    embed = discord.Embed(
        title="🌿 Rodriguez Lawn Care • Nueva Versión iOS IPA Compilada",
        description=(
            "**¡Tu aplicación iOS está lista para instalar!**\n\n"
            "Puedes instalar este archivo `.ipa` directamente en tu iPhone usando **GBox**, **Scarlet**, **TrollStore**, **AltStore** o **Sideloadly** sin necesidad de computadora."
        ),
        color=0x22C55E
    )
    
    embed.add_field(name="📦 Archivo", value=f"`{file_name_display}`", inline=True)
    embed.add_field(name="🔢 Versión", value=f"**v{version_str} (Build {build_num})**", inline=True)
    embed.add_field(name="⚖️ Tamaño", value=f"**{file_size_mb:.2f} MB**", inline=True)
    
    embed.add_field(
        name="✨ Novedades & Funciones Incluidas:",
        value=(
            "• 🗺️ **Optimización de Rutas del Día**: Organiza tus paradas y ábrelas en Apple Maps / Google Maps.\n"
            "• 📸 **Cámara Antes & Después**: Comparativa con marca de agua y publicación en vivo a la galería web.\n"
            "• 💵 **Pagos Zelle & Cash App en Invoice**: Datos de pago listos para cobrar por WhatsApp y en la factura.\n"
            "• 🔁 **Clientes Recurrentes**: Control semanal/quincenal, estado de pago y recordatorios automáticos por WhatsApp.\n"
            "• 🌧️ **Clima & Alerta de Lluvias en Killeen**: Pronóstico en vivo y botón para mover citas por lluvia.\n"
            "• 📐 **Medidor Satelital de Jardín**: Mide el terreno en sq ft y acres por GPS para calcular precios exactos.\n"
            "• 🔔 **Sonidos de Alerta & Haptics**: Avisos audibles cuando entran cotizaciones o confirmas trabajos.\n"
            "• 🎨 **Icono Oficial R Esmeralda**: Diseño nítido de alta fidelidad.\n"
            "• 📲 **Sincronización Total 24/7 en la Nube**: Conexión permanente con Railway y Discord."
        ),
        inline=False
    )
    
    embed.add_field(
        name="📲 ¿Cómo instalar con GBox (Evitando Caché Viejo)?",
        value=f"1. Toca el archivo adjunto `{file_name_display}` aquí en Discord.\n2. Presiona el botón de **Compartir** y selecciona **GBox**.\n3. En GBox, toca **Instalar** (al tener nombre único nuevo, GBox firma e instala la versión real v{version_str} Build {build_num}) y ¡listo!",
        inline=False
    )
    
    embed.set_footer(text="Rodriguez Lawn Care • Sistema Autónomo de Entrega Continua")
    
    # Clean up previous bot messages to avoid spam and keep channel clean
    try:
        async for old_msg in channel.history(limit=100):
            try:
                await old_msg.delete()
                print(f"Cleaned up previous message {old_msg.id}")
            except Exception as del_err:
                print(f"Notice delete message {old_msg.id}: {del_err}")
    except Exception as hist_err:
        print(f"Notice history cleanup: {hist_err}")
    
    with open(ipa_file_path, "rb") as f:
        discord_file = discord.File(f, filename=file_name_display)
        msg = await channel.send(
            content="🚀 **¡Nueva actualización de la App iOS disponible para descargar!**",
            embed=embed,
            file=discord_file
        )
        print(f"IPA successfully delivered to channel #{getattr(channel, 'name', channel.id)}! Message ID: {msg.id}")
        
    await client.close()

if __name__ == "__main__":
    asyncio.run(main())
