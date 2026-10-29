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
    os.path.join(BASE_DIR, "ipa online", "rodriguezlawncareios.ipa"),
    os.path.join(BASE_DIR, "RodriguezLawnCareIosAPP", "ipa online", "rodriguezlawncareios.ipa"),
    os.path.join(BASE_DIR, "ipa here", "rodriguezlawncareios.ipa"),
    os.path.join(BASE_DIR, "ipa here", "RodriguezLawnCare.ipa"),
]

ipa_file_path = None
for p in IPA_CANDIDATES:
    if os.path.exists(p) and os.path.getsize(p) > 100000:
        ipa_file_path = p
        break

if not ipa_file_path:
    print("ERROR: Could not find any valid IPA file to upload!")
    sys.exit(1)

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
    
    embed.add_field(name="📦 Archivo", value="`rodriguezlawncareios.ipa`", inline=True)
    embed.add_field(name="🔢 Versión", value=f"**v{version_str} (Build {build_num})**", inline=True)
    embed.add_field(name="⚖️ Tamaño", value=f"**{file_size_mb:.2f} MB**", inline=True)
    
    embed.add_field(
        name="✨ Novedades & Funciones Incluidas:",
        value=(
            "• 🎨 **Nuevo Icono Oficial de Alta Fidelidad**: Logo R esmeralda con pasto.\n"
            "• 🤖 **IA Estimate Real-Time**: Cotización con fotos y búsqueda de precios reales en Home Depot, Lowe's y Tractor Supply en Killeen, TX.\n"
            "• 📅 **Calendario Profesional Diario**: Bloqueo de días Normal 🟢 / Lleno 🔴 y visualización de citas de clientes.\n"
            "• 🧾 **Generador de Facturas (Invoices)**: Crea invoices con logo de Rodriguez Lawn Care y envíalos por WhatsApp o guárdalos en fotos.\n"
            "• 🔥 **Promociones Web 24h**: Lanza ofertas flash con banner dinámico y temporizador en la página web.\n"
            "• 📸 **Fotos de Clientes en Citas**: Las imágenes que los clientes suben en la web llegan directamente a tu app.\n"
            "• ✨ **Fondo con Partículas Glow**: Efecto visual moderno y fluido en toda la app.\n"
            "• 📲 **Sincronización Total en la Nube**: Conexión permanente con Railway y Discord."
        ),
        inline=False
    )
    
    embed.add_field(
        name="📲 ¿Cómo instalar con GBox?",
        value="1. Toca el archivo adjunto `rodriguezlawncareios.ipa` aquí en Discord.\n2. Presiona el botón de **Compartir** y selecciona **GBox**.\n3. En GBox, toca **Instalar** y ¡listo!",
        inline=False
    )
    
    embed.set_footer(text="Rodriguez Lawn Care • Sistema Autónomo de Entrega Continua")
    
    # Clean up previous bot messages to avoid spam and keep channel clean
    try:
        async for old_msg in channel.history(limit=50):
            if old_msg.author.id == client.user.id:
                try:
                    await old_msg.delete()
                    print(f"Cleaned up previous message {old_msg.id}")
                except Exception as del_err:
                    print(f"Notice delete message {old_msg.id}: {del_err}")
    except Exception as hist_err:
        print(f"Notice history cleanup: {hist_err}")
    
    with open(ipa_file_path, "rb") as f:
        discord_file = discord.File(f, filename="rodriguezlawncareios.ipa")
        msg = await channel.send(
            content="🚀 **¡Nueva actualización de la App iOS disponible para descargar!**",
            embed=embed,
            file=discord_file
        )
        print(f"IPA successfully delivered to channel #{getattr(channel, 'name', channel.id)}! Message ID: {msg.id}")
        
    await client.close()

if __name__ == "__main__":
    asyncio.run(main())
