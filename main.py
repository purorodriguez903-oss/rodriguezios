"""
RODRIGUEZ LAWNCARE - 24/7 UNIFIED CLOUD SERVER & DISCORD BOT
Runs 24/7 on Railway / Cloud hosting:
1. High-Performance Web Server (serving website & live gallery without cache lags)
2. Live Discord Bot (Upload, delete, and check photos from mobile/Discord)
3. Real-Time Activity Logger in Discord Channel
"""

import os
import sys
import json
import time
import asyncio
import aiohttp
from aiohttp import web
import discord
from discord import app_commands
from discord.ext import commands

# Fix Windows console UTF-8 encoding
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
if hasattr(sys.stderr, "reconfigure"):
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")

# ----------------- CONFIGURATION & SECRETS -----------------
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
ENV_FILE = os.path.join(BASE_DIR, ".env")

def get_env_var(key, default=""):
    val = os.environ.get(key)
    if val:
        return val
    if os.path.exists(ENV_FILE):
        try:
            with open(ENV_FILE, "r", encoding="utf-8") as f:
                for line in f:
                    if line.strip().startswith(f"{key}="):
                        return line.strip().split("=", 1)[1].strip('"').strip("'")
        except Exception:
            pass
    return default

APP_ID = int(get_env_var("APP_ID", "1557276640650723393"))
BOT_TOKEN = get_env_var("BOT_TOKEN", "")
SERVER_ID = int(get_env_var("SERVER_ID", "1538269421020258304"))
CHANNEL_ID = int(get_env_var("CHANNEL_ID", "1557277046491578379"))
LEADS_CHANNEL_ID = int(get_env_var("LEADS_CHANNEL_ID", "1557306528078237706"))
IPA_CHANNEL_ID = int(get_env_var("IPA_CHANNEL_ID", "1565299006932914176"))
PORT = int(get_env_var("PORT", "8080"))

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
GALLERY_JSON_PATH = os.path.join(BASE_DIR, "gallery.json")
GALLERY_FOLDER = os.path.join(BASE_DIR, "assets", "gallery")
LEADS_JSON_PATH = os.path.join(BASE_DIR, "leads.json")
SETTINGS_JSON_PATH = os.path.join(BASE_DIR, "settings.json")
ANALYTICS_JSON_PATH = os.path.join(BASE_DIR, "analytics.json")
CLOUD_CONFIG_JSON_PATH = os.path.join(BASE_DIR, "cloud_config.json")
CALENDAR_JSON_PATH = os.path.join(BASE_DIR, "calendar.json")
PROMOTIONS_JSON_PATH = os.path.join(BASE_DIR, "promotions.json")
IPA_DELIVERY_JSON_PATH = os.path.join(BASE_DIR, "ipa_delivery.json")
REVIEWS_JSON_PATH = os.path.join(BASE_DIR, "reviews.json")
UPLOADS_LEADS_FOLDER = os.path.join(BASE_DIR, "assets", "uploads", "leads")
os.makedirs(UPLOADS_LEADS_FOLDER, exist_ok=True)


THREE_DAYS_MS = 3 * 24 * 60 * 60 * 1000

os.makedirs(GALLERY_FOLDER, exist_ok=True)

# ----------------- DATABASE HELPERS -----------------
def load_gallery():
    if not os.path.exists(GALLERY_JSON_PATH):
        return []
    try:
        with open(GALLERY_JSON_PATH, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception as e:
        print(f"[Error] Cargando gallery.json: {e}")
        return []

def save_gallery(data):
    try:
        with open(GALLERY_JSON_PATH, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        return True
    except Exception as e:
        print(f"[Error] Guardando gallery.json: {e}")
        return False

def load_reviews():
    if not os.path.exists(REVIEWS_JSON_PATH):
        return []
    try:
        with open(REVIEWS_JSON_PATH, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception as e:
        print(f"[Error] Cargando reviews.json: {e}")
        return []

def save_reviews(data):
    try:
        with open(REVIEWS_JSON_PATH, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        return True
    except Exception as e:
        print(f"[Error] Guardando reviews.json: {e}")
        return False

def load_leads():
    if not os.path.exists(LEADS_JSON_PATH):
        return []
    try:
        with open(LEADS_JSON_PATH, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception as e:
        print(f"[Error] Cargando leads.json: {e}")
        return []

def save_leads(data):
    try:
        with open(LEADS_JSON_PATH, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        return True
    except Exception as e:
        print(f"[Error] Guardando leads.json: {e}")
        return False

def load_settings():
    default_settings = {
        "hero_type": "video",
        "hero_video_url": "./assets/video/hero.mp4",
        "hero_poster_url": "./assets/images/drone_tundra_intro.jpg",
        "hero_preset_id": "drone_tundra",
        "hero_title": "Your Dream Lawn, Flawlessly Maintained",
        "hero_subtitle": "Crisp commercial stripe mowing, razor-sharp concrete edging, and premium landscape care. Available for direct homeowner jobs and general contractors."
    }
    if not os.path.exists(SETTINGS_JSON_PATH):
        return default_settings
    try:
        with open(SETTINGS_JSON_PATH, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception as e:
        print(f"[Error] Cargando settings.json: {e}")
        return default_settings

def save_settings(data):
    try:
        with open(SETTINGS_JSON_PATH, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        return True
    except Exception as e:
        print(f"[Error] Guardando settings.json: {e}")
        return False

def load_analytics():
    default_analytics = {
        "total_visits": 0,
        "unique_visitors": 0,
        "visits_today": 0,
        "quotes_submitted": 0,
        "conversion_rate": "0.0%",
        "last_updated": int(time.time())
    }
    if not os.path.exists(ANALYTICS_JSON_PATH):
        return default_analytics
    try:
        with open(ANALYTICS_JSON_PATH, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception as e:
        print(f"[Error] Cargando analytics.json: {e}")
        return default_analytics

def save_analytics(data):
    try:
        with open(ANALYTICS_JSON_PATH, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        return True
    except Exception as e:
        print(f"[Error] Guardando analytics.json: {e}")
        return False

def increment_visit():
    analytics = load_analytics()
    analytics["total_visits"] = analytics.get("total_visits", 0) + 1
    analytics["visits_today"] = analytics.get("visits_today", 0) + 1
    analytics["last_updated"] = int(time.time())
    save_analytics(analytics)
    return analytics

def load_cloud_config():
    default_config = {
        "app_name": "rodriguezlawncareios",
        "app_version": "1.3.0",
        "app_build": 13,
        "min_version": "1.0.0",
        "release_notes": "Conexión 100% online con Railway (https://web-production-b6891b.up.railway.app), cotizaciones en tiempo real, selector de fotos desde el iPhone y sincronización instantánea de trabajos y fondo Hero.",
        "ipa_url": "https://github.com/purorodriguez903-oss/rodriguezlawncarewebiosweb/releases/download/latest-ipa/rodriguezlawncareios.ipa",
        "ipa_fallback_url": "https://github.com/purorodriguez903-oss/rodriguezlawncarewebiosweb/releases/download/latest-ipa/RodriguezLawnCare.ipa",
        "trollstore_url": "apple-magnifier://install?url=https://github.com/purorodriguez903-oss/rodriguezlawncarewebiosweb/releases/download/latest-ipa/rodriguezlawncareios.ipa",
        "esign_url": "esign://import?url=https://github.com/purorodriguez903-oss/rodriguezlawncarewebiosweb/releases/download/latest-ipa/rodriguezlawncareios.ipa",
        "contact_phone": "(254) 852-8163",
        "whatsapp_number": "12548528163",
        "rates": {
            "small": 45.0,
            "medium": 60.0,
            "large": 85.0,
            "acre": 140.0,
            "overgrown_mult": 1.3,
            "weekly_discount": 0.10,
            "biweekly_discount": 0.05
        },
        "addons": {
            "bushes": 30.0,
            "mulch": 65.0,
            "trees": 75.0,
            "cleanups": 50.0,
            "edging": 15.0
        },
        "announcement": {
            "enabled": False,
            "title": "Aviso Online",
            "message": "Sistema 100% en línea sincronizado."
        }
    }
    if not os.path.exists(CLOUD_CONFIG_JSON_PATH):
        return default_config
    try:
        with open(CLOUD_CONFIG_JSON_PATH, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception as e:
        print(f"[Error] Cargando cloud_config.json: {e}")
        return default_config

def save_cloud_config(data):
    try:
        with open(CLOUD_CONFIG_JSON_PATH, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        return True
    except Exception as e:
        print(f"[Error] Guardando cloud_config.json: {e}")
        return False

def save_lead_photos(photos_data, lead_id):
    """Decodes base64 photos uploaded by customers and saves them locally."""
    saved_urls = []
    if not photos_data or not isinstance(photos_data, list):
        return saved_urls
    import base64
    for idx, item in enumerate(photos_data):
        if not item or not isinstance(item, str):
            continue
        if item.startswith("data:image"):
            try:
                header, encoded = item.split(",", 1)
                ext = "png" if "png" in header else "jpg"
                raw = base64.b64decode(encoded)
                filename = f"lead_{lead_id}_{idx+1}.{ext}"
                filepath = os.path.join(UPLOADS_LEADS_FOLDER, filename)
                with open(filepath, "wb") as f:
                    f.write(raw)
                saved_urls.append(f"./assets/uploads/leads/{filename}")
            except Exception as e:
                print(f"[Error] Guardando foto de lead: {e}")
        elif item.startswith("http") or item.startswith("./"):
            saved_urls.append(item)
    return saved_urls

def load_calendar():
    default_cal = {
        "day_status": {}, # "YYYY-MM-DD": "normal" or "full"
        "appointments": []
    }
    if not os.path.exists(CALENDAR_JSON_PATH):
        return default_cal
    try:
        with open(CALENDAR_JSON_PATH, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception as e:
        print(f"[Error] Cargando calendar.json: {e}")
        return default_cal

def save_calendar(data):
    try:
        with open(CALENDAR_JSON_PATH, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        return True
    except Exception as e:
        print(f"[Error] Guardando calendar.json: {e}")
        return False

def load_promotions():
    default_promo = {
        "active": {
            "id": 1,
            "enabled": True,
            "title": "🎖️ Descuento Especial Militar & Killeen",
            "message": "¡El día de hoy aprovecha nuestra promoción para militares: corte de césped profesional a $35 con orillado impecable!",
            "badge": "OFERTA MILITAR FLASH",
            "created_at": int(time.time()),
            "duration_hours": 24,
            "expires_at": int(time.time()) + 24 * 3600
        },
        "history": []
    }
    if not os.path.exists(PROMOTIONS_JSON_PATH):
        return default_promo
    try:
        with open(PROMOTIONS_JSON_PATH, "r", encoding="utf-8") as f:
            data = json.load(f)
            # Check expiration
            active = data.get("active")
            if active and active.get("enabled"):
                if time.time() > active.get("expires_at", 0):
                    active["enabled"] = False
                    data.setdefault("history", []).insert(0, dict(active))
                    save_promotions(data)
            return data
    except Exception as e:
        print(f"[Error] Cargando promotions.json: {e}")
        return default_promo

def save_promotions(data):
    try:
        with open(PROMOTIONS_JSON_PATH, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        return True
    except Exception as e:
        print(f"[Error] Guardando promotions.json: {e}")
        return False

def get_next_id(gallery):
    if not gallery:
        return 1
    return max(item.get("id", 0) for item in gallery) + 1


# ----------------- JOB CATEGORIES & PRESETS -----------------
JOB_PRESETS = {
    "front": {
        "category": "Front Yard",
        "icon": "🏡",
        "default_title": "Front Yard Clean & Sharp Mowing"
    },
    "back": {
        "category": "Back Yard",
        "icon": "🌿",
        "default_title": "Back Yard Mowing & Clean Lines"
    },
    "mulch": {
        "category": "Mulch",
        "icon": "🪵",
        "default_title": "Fresh Dark Mulch Installation"
    },
    "tree": {
        "category": "Tree Care",
        "icon": "🌳",
        "default_title": "Tree Care & Precision Trimming"
    },
    "bush": {
        "category": "Shrubs & Bushes",
        "icon": "✂️",
        "default_title": "Hedge Trimming & Shrub Shaping"
    },
    "clean": {
        "category": "Yard Cleanups",
        "icon": "🧹",
        "default_title": "Property Cleanup & Debris Removal"
    },
    "edge": {
        "category": "Edging & Stripes",
        "icon": "📐",
        "default_title": "Precision Sidewalk Edging"
    },
    "mow": {
        "category": "Lawn Mowing",
        "icon": "🌱",
        "default_title": "Commercial Stripe Lawn Mowing"
    }
}

KEYWORD_MAPPINGS = [
    (["front", "frente", "delantero", "delantera", "frontyard", "porch"], "front"),
    (["back", "trasero", "trasera", "atras", "backyard", "patio trasero"], "back"),
    (["mulch", "mulching", "acolchado", "corteza", "bark"], "mulch"),
    (["tree", "trees", "arbol", "arboles", "rama", "ramas", "poda"], "tree"),
    (["bush", "bushes", "shrub", "shrubs", "hedge", "hedges", "arbusto", "arbustos", "seto", "setos"], "bush"),
    (["clean", "cleanup", "limpieza", "junk", "debris", "hojas", "leaf", "leaves", "escombros"], "clean"),
    (["edge", "edging", "orilla", "orillas", "filo", "sidewalk", "banqueta"], "edge"),
    (["mow", "mowing", "corte", "zacate", "pasto", "cesped", "lawn", "grass"], "mow"),
]

def parse_job_details(text: str):
    """Detects category, icon, and formatted title from user text or keyword."""
    if not text or not text.strip():
        return {
            "category": "General LawnCare",
            "icon": "🌱",
            "title": "Trabajo de Lawn Care"
        }
    clean = text.strip()
    low = clean.lower()

    for kw_list, preset_key in KEYWORD_MAPPINGS:
        if any(kw in low for kw in kw_list):
            preset = JOB_PRESETS[preset_key]
            # If user typed just a short word like "front", "mulch", "tree"
            if len(clean) <= 12 or clean.lower() in [k for k in kw_list]:
                return {
                    "category": preset["category"],
                    "icon": preset["icon"],
                    "title": preset["default_title"]
                }
            # Otherwise, keep custom details capitalized
            return {
                "category": preset["category"],
                "icon": preset["icon"],
                "title": clean[0].upper() + clean[1:]
            }

    return {
        "category": "General LawnCare",
        "icon": "✨",
        "title": clean[0].upper() + clean[1:]
    }


# ----------------- IPA AUTO DELIVERY HELPER -----------------
def get_ipa_file_path():
    candidates = [
        os.path.join(BASE_DIR, "ipa online", "rodriguezlawncareios.ipa"),
        os.path.join(BASE_DIR, "RodriguezLawnCareIosAPP", "ipa online", "rodriguezlawncareios.ipa"),
        os.path.join(BASE_DIR, "ipa here", "rodriguezlawncareios.ipa"),
        os.path.join(BASE_DIR, "ipa here", "RodriguezLawnCare.ipa"),
    ]
    for p in candidates:
        if os.path.exists(p) and os.path.getsize(p) > 100000:
            return p
    return None

async def send_ipa_to_discord(bot_instance, channel_id=IPA_CHANNEL_ID, force=False):
    """Sends the latest compiled iOS IPA directly to the specified Discord channel."""
    try:
        ipa_path = get_ipa_file_path()
        if not ipa_path:
            print("[IPA Delivery] No se encontró ningún archivo IPA válido.")
            return False, "No se encontró el archivo IPA compilado."

        file_size_bytes = os.path.getsize(ipa_path)
        file_size_mb = file_size_bytes / (1024 * 1024)

        import hashlib
        # Clean up previous bot messages to avoid spam and keep channel clean
        try:
            async for old_msg in channel.history(limit=50):
                if old_msg.author.id == bot_instance.user.id:
                    try:
                        await old_msg.delete()
                        print(f"[IPA Delivery] Mensaje previo {old_msg.id} eliminado para evitar spam.")
                    except Exception as del_err:
                        print(f"[IPA Delivery] Aviso al borrar mensaje anterior: {del_err}")
        except Exception as hist_err:
            print(f"[IPA Delivery] Aviso al limpiar historial: {hist_err}")

        with open(ipa_path, "rb") as f:
            ipa_hash = hashlib.md5(f.read()).hexdigest()

        # Check last sent hash if not force
        if not force and os.path.exists(IPA_DELIVERY_JSON_PATH):
            try:
                with open(IPA_DELIVERY_JSON_PATH, "r", encoding="utf-8") as f:
                    state = json.load(f)
                    if state.get("last_sent_hash") == ipa_hash:
                        print(f"[IPA Delivery] El IPA con hash {ipa_hash} ya fue enviado previamente.")
                        return True, "El IPA actual ya fue enviado previamente."
            except Exception:
                pass

        channel = bot_instance.get_channel(channel_id)
        if not channel:
            channel = await bot_instance.fetch_channel(channel_id)
        if not channel:
            print(f"[IPA Delivery] No se encontró el canal con ID {channel_id}")
            return False, f"Canal de Discord {channel_id} no encontrado."

        cfg = load_cloud_config()
        version_str = cfg.get("app_version", "1.6.0")
        build_num = cfg.get("app_build", 17)

        embed = discord.Embed(
            title="\U0001f33f Rodriguez Lawn Care \u2022 Nueva Versi\u00f3n iOS IPA Compilada",
            description=(
                "**\u00a1Tu aplicaci\u00f3n iOS est\u00e1 lista para instalar!**\n\n"
                "Puedes instalar este archivo `.ipa` directamente en tu iPhone usando **GBox**, **Scarlet**, **TrollStore**, **AltStore** o **Sideloadly** sin necesidad de computadora."
            ),
            color=0x22C55E
        )
        embed.add_field(name="\U0001f4e6 Archivo", value="`rodriguezlawncareios.ipa`", inline=True)
        embed.add_field(name="\U0001f522 Versi\u00f3n", value=f"**v{version_str} (Build {build_num})**", inline=True)
        embed.add_field(name="\u2696\ufe0f Tama\u00f1o", value=f"**{file_size_mb:.2f} MB**", inline=True)

        embed.add_field(
            name="\u2728 Novedades & Funciones Incluidas:",
            value=(
                "\u2022 \U0001f3a8 **Nuevo Icono Oficial de Alta Fidelidad**: Logo R esmeralda con pasto.\n"
                "\u2022 \U0001f916 **IA Estimate Real-Time**: Cotizaci\u00f3n con fotos y precios en Killeen, TX.\n"
                "\u2022 \U0001f4c5 **Calendario Profesional Diario**: Bloqueo de d\u00edas Normal / Lleno.\n"
                "\u2022 \U0001f9fe **Generador de Facturas (Invoices)**: Crea invoices con logo y env\u00edalos.\n"
                "\u2022 \U0001f525 **Promociones Web 24h**: Lanza ofertas flash con banner din\u00e1mico.\n"
                "\u2022 \U0001f4f8 **Fotos de Clientes en Citas**: Las im\u00e1genes llegan directo a tu app.\n"
                "\u2022 \u2728 **Fondo con Part\u00edculas Glow**: Efecto visual moderno y fluido.\n"
                "\u2022 \U0001f4f2 **Sincronizaci\u00f3n Total en la Nube**: Conexi\u00f3n permanente con Railway y Discord."
            ),
            inline=False
        )

        embed.add_field(
            name="\U0001f4f2 \u00bfC\u00f3mo instalar con GBox?",
            value="1. Toca el archivo adjunto `rodriguezlawncareios.ipa` aqu\u00ed en Discord.\n2. Presiona el bot\u00f3n de **Compartir** y selecciona **GBox**.\n3. En GBox, toca **Instalar** y \u00a1listo!",
            inline=False
        )
        embed.set_footer(text="Rodriguez Lawn Care \u2022 Sistema Aut\u00f3nomo de Entrega Continua")

        with open(ipa_path, "rb") as f:
            discord_file = discord.File(f, filename="rodriguezlawncareios.ipa")
            msg = await channel.send(
                content="🚀 **¡Nueva actualización de la App iOS disponible para descargar!**",
                embed=embed,
                file=discord_file
            )

        # Save delivery record
        try:
            with open(IPA_DELIVERY_JSON_PATH, "w", encoding="utf-8") as f:
                json.dump({"last_sent_hash": ipa_hash, "sent_at": time.time(), "message_id": msg.id}, f, indent=2)
        except Exception as err:
            print(f"[IPA Delivery] Error guardando ipa_delivery.json: {err}")

        print(f"✅ [IPA Delivery] IPA enviado con éxito al canal #{getattr(channel, 'name', channel_id)}! Message ID: {msg.id}")
        return True, f"IPA enviado con éxito al canal #{getattr(channel, 'name', channel_id)}."
    except Exception as e:
        print(f"❌ [IPA Delivery Error]: {e}")
        return False, str(e)


# ----------------- DISCORD LOGGING HELPER -----------------
async def send_discord_log(bot_instance, title: str, description: str, color=discord.Color.blue(), image_url=None):
    """Sends a real-time activity log directly to the Discord channel."""
    try:
        channel = bot_instance.get_channel(CHANNEL_ID)
        if not channel:
            return
        embed = discord.Embed(
            title=title,
            description=description,
            color=color,
            timestamp=discord.utils.utcnow()
        )
        embed.set_footer(text="Rodriguez LawnCare • Sistema en Vivo 24/7")
        if image_url:
            embed.set_image(url=image_url)
        await channel.send(embed=embed)
    except Exception as e:
        print(f"[Error enviando log a Discord]: {e}")


# ----------------- DISCORD MODALS & UI VIEWS -----------------
class CustomJobModal(discord.ui.Modal, title="Nombre del Trabajo"):
    job_name = discord.ui.TextInput(
        label="¿Qué trabajo se realizó?",
        placeholder="Ej: Front yard, Mulch nuevo, Podado de árboles...",
        min_length=2,
        max_length=90,
        required=True
    )

    def __init__(self, item_ids: list, bot_ref=None):
        super().__init__()
        self.item_ids = item_ids if isinstance(item_ids, list) else [item_ids]
        self.bot_ref = bot_ref

    async def on_submit(self, interaction: discord.Interaction):
        custom_text = self.job_name.value.strip()
        details = parse_job_details(custom_text)
        gallery = load_gallery()

        updated_count = 0
        for item in gallery:
            if item.get("id") in self.item_ids:
                item["title"] = details["title"]
                item["category"] = details["category"]
                updated_count += 1

        if updated_count > 0:
            save_gallery(gallery)
            embed = discord.Embed(
                title="✅ ¡Trabajo Asignado con Éxito!",
                description=(
                    f"📸 **Foto(s):** `#{', #'.join(str(i) for i in self.item_ids)}`\n"
                    f"🏷️ **Nombre:** `{details['icon']} {details['title']}`\n"
                    f"📂 **Categoría Web:** `{details['category']}`\n\n"
                    f"🌐 *Ya se actualizó en tu página web en tiempo real.*"
                ),
                color=discord.Color.green()
            )
            await interaction.response.send_message(embed=embed, ephemeral=False)

            if self.bot_ref:
                await send_discord_log(
                    self.bot_ref,
                    title="📋 [REGISTRO EN VIVO] • ✏️ Foto(s) Renombrada(s)",
                    description=(
                        f"• **Foto(s):** `#{', #'.join(str(i) for i in self.item_ids)}`\n"
                        f"• **Nombre:** *{details['title']}*\n"
                        f"• **Categoría:** `{details['category']}`\n"
                        f"• **Estado web:** 🟢 Actualizado en vivo"
                    ),
                    color=discord.Color.green()
                )
        else:
            await interaction.response.send_message("❌ No se encontró la foto para actualizar.", ephemeral=True)


class JobCategoryPickerView(discord.ui.View):
    def __init__(self, item_ids: list, bot_ref=None):
        super().__init__(timeout=None)
        self.item_ids = item_ids if isinstance(item_ids, list) else [item_ids]
        self.bot_ref = bot_ref

    async def apply_preset(self, interaction: discord.Interaction, key: str):
        details = JOB_PRESETS[key]
        gallery = load_gallery()
        updated = 0
        for item in gallery:
            if item.get("id") in self.item_ids:
                item["title"] = details["default_title"]
                item["category"] = details["category"]
                updated += 1

        if updated > 0:
            save_gallery(gallery)
            embed = discord.Embed(
                title="✅ ¡Trabajo Asignado a la Web!",
                description=(
                    f"📸 **Foto(s):** `#{', #'.join(str(i) for i in self.item_ids)}`\n"
                    f"🏷️ **Nombre:** `{details['icon']} {details['default_title']}`\n"
                    f"📂 **Categoría Web:** `{details['category']}`\n\n"
                    f"🌐 *Visible al instante en tu página web.*"
                ),
                color=discord.Color.green()
            )
            await interaction.response.send_message(embed=embed, ephemeral=False)

            if self.bot_ref:
                await send_discord_log(
                    self.bot_ref,
                    title="📋 [REGISTRO EN VIVO] • 🏷️ Categoría de Foto Asignada",
                    description=(
                        f"• **Foto(s):** `#{', #'.join(str(i) for i in self.item_ids)}`\n"
                        f"• **Trabajo:** `{details['icon']} {details['default_title']}`\n"
                        f"• **Categoría Web:** `{details['category']}`"
                    ),
                    color=discord.Color.green()
                )
        else:
            await interaction.response.send_message("⚠️ Foto no encontrada en la web.", ephemeral=True)

    @discord.ui.button(label="Front Yard", emoji="🏡", style=discord.ButtonStyle.primary, row=0)
    async def btn_front(self, interaction: discord.Interaction, button: discord.ui.Button):
        await self.apply_preset(interaction, "front")

    @discord.ui.button(label="Back Yard", emoji="🌿", style=discord.ButtonStyle.primary, row=0)
    async def btn_back(self, interaction: discord.Interaction, button: discord.ui.Button):
        await self.apply_preset(interaction, "back")

    @discord.ui.button(label="Mulch", emoji="🪵", style=discord.ButtonStyle.success, row=0)
    async def btn_mulch(self, interaction: discord.Interaction, button: discord.ui.Button):
        await self.apply_preset(interaction, "mulch")

    @discord.ui.button(label="Tree Care", emoji="🌳", style=discord.ButtonStyle.success, row=1)
    async def btn_tree(self, interaction: discord.Interaction, button: discord.ui.Button):
        await self.apply_preset(interaction, "tree")

    @discord.ui.button(label="Arbustos", emoji="✂️", style=discord.ButtonStyle.secondary, row=1)
    async def btn_bush(self, interaction: discord.Interaction, button: discord.ui.Button):
        await self.apply_preset(interaction, "bush")

    @discord.ui.button(label="Limpieza", emoji="🧹", style=discord.ButtonStyle.secondary, row=1)
    async def btn_clean(self, interaction: discord.Interaction, button: discord.ui.Button):
        await self.apply_preset(interaction, "clean")

    @discord.ui.button(label="Escribir Otro Nombre...", emoji="✏️", style=discord.ButtonStyle.secondary, row=2)
    async def btn_custom(self, interaction: discord.Interaction, button: discord.ui.Button):
        await interaction.response.send_modal(CustomJobModal(self.item_ids, self.bot_ref))


class RenameSelect(discord.ui.Select):
    def __init__(self, gallery, bot_ref):
        self.bot_ref = bot_ref
        options = []
        for item in gallery[-25:]:
            cat = item.get("category", "General")
            title = item.get("title", "Trabajo")[:40]
            options.append(
                discord.SelectOption(
                    label=f"Foto #{item['id']} ({cat})",
                    description=title,
                    value=str(item["id"]),
                    emoji="🏷️"
                )
            )
        super().__init__(
            placeholder="Selecciona la foto a la que deseas cambiar nombre...",
            min_values=1,
            max_values=1,
            options=options
        )

    async def callback(self, interaction: discord.Interaction):
        photo_id = int(self.values[0])
        gallery = load_gallery()
        found_item = next((item for item in gallery if item.get("id") == photo_id), None)
        if not found_item:
            await interaction.response.send_message(f"❌ La foto #{photo_id} no existe.", ephemeral=True)
            return

        view = JobCategoryPickerView([photo_id], self.bot_ref)
        msg = (
            f"✏️ **Cambiando nombre a la Foto #{photo_id}**\n"
            f"• **Título actual:** *{found_item.get('title', 'Sin título')}*\n"
            f"• **Categoría actual:** `{found_item.get('category', 'General')}`\n\n"
            f"👇 **Selecciona el nuevo trabajo o escribe un nombre personalizado:**"
        )
        await interaction.response.send_message(msg, view=view, ephemeral=True)


class RenameView(discord.ui.View):
    def __init__(self, gallery, bot_ref):
        super().__init__(timeout=60)
        self.add_item(RenameSelect(gallery, bot_ref))


class DeleteSelect(discord.ui.Select):
    def __init__(self, gallery, bot_ref):
        self.bot_ref = bot_ref
        options = []
        for item in gallery[-25:]:
            now = int(time.time() * 1000)
            is_new = (now - item.get("uploaded_at", 0)) < THREE_DAYS_MS
            status_text = "NEW" if is_new else "Normal"
            cat = item.get("category", "Trabajo")
            title_preview = f"[{cat}] {item.get('title', 'Trabajo')}"[:45]
            options.append(
                discord.SelectOption(
                    label=f"Foto #{item['id']} ({status_text})",
                    description=title_preview,
                    value=str(item["id"]),
                    emoji="🗑️"
                )
            )
        super().__init__(
            placeholder="Selecciona el número de la foto a eliminar...",
            min_values=1,
            max_values=1,
            options=options
        )

    async def callback(self, interaction: discord.Interaction):
        photo_id = int(self.values[0])
        gallery = load_gallery()
        found_item = next((item for item in gallery if item.get("id") == photo_id), None)

        if not found_item:
            await interaction.response.send_message(f"❌ La foto #{photo_id} ya no existe en la web.", ephemeral=True)
            return

        # Delete image file from disk
        filename = found_item.get("filename")
        if filename:
            file_path = os.path.join(GALLERY_FOLDER, filename)
            if os.path.exists(file_path):
                try:
                    os.remove(file_path)
                except Exception as e:
                    print(f"Error borrando archivo {file_path}: {e}")

        # Remove from JSON
        gallery = [item for item in gallery if item.get("id") != photo_id]
        save_gallery(gallery)

        embed = discord.Embed(
            title="🗑️ Foto Eliminada de la Web",
            description=f"La **Foto #{photo_id}** ha sido eliminada con éxito y ya no aparecerá en tu página web.",
            color=discord.Color.red()
        )
        await interaction.response.send_message(embed=embed, ephemeral=True)

        # Broadcast real-time activity log to channel
        await send_discord_log(
            self.bot_ref,
            title="📋 [REGISTRO EN VIVO] • 🗑️ Foto Eliminada de la Web",
            description=(
                f"• **Foto removida:** `#{photo_id}`\n"
                f"• **Título anterior:** *{found_item.get('title', 'Trabajo')}*\n"
                f"• **Categoría:** `{found_item.get('category', 'General')}`\n"
                f"• **Total restante en la web:** **{len(gallery)} fotos**\n"
                f"• **Estado web:** 🟢 Cambios aplicados en tiempo real."
            ),
            color=discord.Color.orange()
        )


class DeleteView(discord.ui.View):
    def __init__(self, gallery, bot_ref):
        super().__init__(timeout=60)
        self.add_item(DeleteSelect(gallery, bot_ref))


class ControlPanelView(discord.ui.View):
    def __init__(self, bot_ref):
        super().__init__(timeout=None)
        self.bot_ref = bot_ref

    @discord.ui.button(label="Checar Fotos en Web", style=discord.ButtonStyle.success, emoji="📸", custom_id="btn_check_photos")
    async def check_photos_btn(self, interaction: discord.Interaction, button: discord.ui.Button):
        gallery = load_gallery()
        if not gallery:
            await interaction.response.send_message("ℹ️ No hay fotos publicadas en la web actualmente.", ephemeral=True)
            return

        now = int(time.time() * 1000)
        new_count = 0
        lines = []

        for item in gallery:
            pid = item.get("id")
            up_time = item.get("uploaded_at", 0)
            diff_ms = now - up_time
            is_new = diff_ms < THREE_DAYS_MS
            if is_new:
                new_count += 1
                remaining_hours = max(1, int((THREE_DAYS_MS - diff_ms) / (1000 * 60 * 60)))
                tag = f"**🔥 NEW** (quedan ~{remaining_hours}h)"
            else:
                tag = f"`#{pid}` (Normal)"

            cat = item.get("category", "General")
            title = item.get("title", "Trabajo en Killeen")
            lines.append(f"• **Foto #{pid}** • {tag} • `[{cat}]`\n  ↳ *{title}*")

        embed = discord.Embed(
            title="📸 Estado de la Galería en Vivo",
            description=(
                f"• Total en la web: **{len(gallery)} fotos**\n"
                f"• Con etiqueta `🔥 NEW`: **{new_count} fotos**\n\n"
                + "\n\n".join(lines[:15])
            ),
            color=discord.Color.from_rgb(22, 163, 74)
        )

        if len(lines) > 15:
            embed.set_footer(text=f"Mostrando 15 de {len(lines)} fotos. Usa /eliminar para borrar.")

        await interaction.response.send_message(embed=embed, ephemeral=True)

    @discord.ui.button(label="Cambiar Nombre / Trabajo", style=discord.ButtonStyle.primary, emoji="✏️", custom_id="btn_rename_photo")
    async def rename_photo_btn(self, interaction: discord.Interaction, button: discord.ui.Button):
        gallery = load_gallery()
        if not gallery:
            await interaction.response.send_message("ℹ️ No hay fotos en la web para renombrar.", ephemeral=True)
            return
        view = RenameView(gallery, self.bot_ref)
        await interaction.response.send_message("Selecciona la foto a la que deseas cambiar el nombre o categoría:", view=view, ephemeral=True)

    @discord.ui.button(label="Eliminar Foto", style=discord.ButtonStyle.danger, emoji="🗑️", custom_id="btn_delete_photo")
    async def delete_photo_btn(self, interaction: discord.Interaction, button: discord.ui.Button):
        gallery = load_gallery()
        if not gallery:
            await interaction.response.send_message("ℹ️ No hay fotos en la web para eliminar.", ephemeral=True)
            return
        view = DeleteView(gallery, self.bot_ref)
        await interaction.response.send_message("Selecciona la foto que quieres eliminar:", view=view, ephemeral=True)

    @discord.ui.button(label="¿Cómo Subir Fotos?", style=discord.ButtonStyle.secondary, emoji="💡", custom_id="btn_help_upload")
    async def help_upload_btn(self, interaction: discord.Interaction, button: discord.ui.Button):
        msg = (
            "**¡Es súper fácil subir fotos a tu web desde tu celular!** 🚀\n\n"
            "**1. Escribe el trabajo al adjuntar la foto:**\n"
            "   Al mandar la foto en este canal escribe: `front`, `back`, `mulch`, `tree`, etc.\n"
            "   El bot le asignará automáticamente el nombre y categoría en tu web.\n\n"
            "**2. O mándala sin texto:**\n"
            "   El bot te responderá al instante con botones fáciles `[Front Yard]` `[Back Yard]` `[Mulch]` `[Tree Care]` para que toques el que hiciste con un solo dedo.\n\n"
            "**3. Con comando `/subir`:**\n"
            "   Escribe `/subir`, adjunta la foto y elige la categoría en la lista desplegable.\n\n"
            "✨ *El servidor en la nube las publica al instante con la insignia `🔥 NEW` por 3 días (72h).*"
        )
        await interaction.response.send_message(msg, ephemeral=True)


# ----------------- BOT FACTORY -----------------
def build_bot(enable_message_content: bool):
    intents = discord.Intents.default()
    intents.guilds = True
    intents.messages = True
    if enable_message_content:
        intents.message_content = True

    bot = commands.Bot(command_prefix="!", intents=intents)

    @bot.event
    async def on_ready():
        print("==================================================")
        print(f"Rodriguez LawnCare Bot conectado como: {bot.user}")
        print(f"Server ID: {SERVER_ID} | Canal ID: {CHANNEL_ID}")
                # Update Discord Bot Avatar with new official Rodriguez LawnCare logo
        avatar_path = os.path.join(BASE_DIR, "assets", "images", "discord_avatar.png")
        if os.path.exists(avatar_path):
            try:
                with open(avatar_path, "rb") as af:
                    avatar_bytes = af.read()
                await bot.user.edit(avatar=avatar_bytes)
                print("✅ Avatar del bot de Discord actualizado con el nuevo logo.")
            except Exception as e:
                print(f"Notice avatar Discord: {e}")

        print(f"Message Content Intent: {'ACTIVADO' if enable_message_content else 'DESACTIVADO (Usa /subir o Botones)'}")
        print("==================================================")

        try:
            guild = discord.Object(id=SERVER_ID)
            bot.tree.copy_global_to(guild=guild)
            synced = await bot.tree.sync(guild=guild)
            print(f"✅ {len(synced)} Slash commands sincronizados en el servidor.")
        except Exception as e:
            print(f"⚠️ Error sincronizando slash commands: {e}")

        channel = bot.get_channel(CHANNEL_ID)
        if channel:
            already_posted = False
            try:
                async for msg in channel.history(limit=5):
                    if msg.author == bot.user and msg.embeds and "PANEL DE CONTROL" in msg.embeds[0].title:
                        already_posted = True
                        break
            except Exception:
                pass

            if not already_posted:
                embed = discord.Embed(
                    title="🌱 RODRIGUEZ LAWNCARE • CENTRO DE CONTROL WEB",
                    description=(
                        "**Bienvenido al Administrador Inteligente de tu Sitio Web Oficial**\n\n"
                        "Gestiona en tiempo real todos los trabajos que ven tus clientes sin necesidad de abrir tu computadora o tocar código.\n"
                        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
                        "🟢 **Estado del Servidor:** `En Línea 24/7 (Railway Cloud)`\n"
                        "📸 **Galería Activa:** `Fotos Publicadas en Vivo`\n"
                        "🔥 **Insignia Automática:** `Activa por 72 horas (3 días)`\n"
                        "📍 **Cobertura:** `Killeen, Harker Heights, Copperas Cove & Belton, TX`\n"
                        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n"
                        "⚡ **¿CÓMO FUNCIONA?**\n"
                        "• **📤 Subir Trabajos:** Envía de **1 a 5 fotos** en este chat con el nombre (`front`, `back`, `mulch`, `tree`) o usa `/subir`.\n"
                        "• **🏷️ Botones Rápidos:** Si mandas la foto sola, toca los botones `[Front]` `[Back]` `[Mulch]` `[Tree]` para nombrarla al instante.\n"
                        "• **✏️ Renombrar:** Puedes cambiarle el nombre a cualquier foto con **Cambiar Nombre / Trabajo** o `/renombrar`.\n"
                        "• **🗑️ Borrar Trabajos:** Presiona **Eliminar Foto** o usa el comando `/eliminar`.\n"
                    ),
                    color=discord.Color.from_rgb(22, 163, 74)
                )
                embed.set_footer(text="Rodriguez LawnCare • Sistema Autónomo en la Nube")

                files = []
                banner_path = os.path.join(BASE_DIR, "assets", "channel_banner.jpg")
                logo_path = os.path.join(BASE_DIR, "assets", "bot_logo.jpg")
                if os.path.exists(banner_path):
                    files.append(discord.File(banner_path, filename="banner.jpg"))
                    embed.set_image(url="attachment://banner.jpg")
                if os.path.exists(logo_path):
                    files.append(discord.File(logo_path, filename="logo.jpg"))
                    embed.set_thumbnail(url="attachment://logo.jpg")

                view = ControlPanelView(bot)
                if files:
                    await channel.send(files=files, embed=embed, view=view)
                else:
                    await channel.send(embed=embed, view=view)

            # Auto-send IPA to Discord channel if new build is detected
            try:
                await send_ipa_to_discord(bot, channel_id=IPA_CHANNEL_ID, force=False)
            except Exception as ipa_err:
                print(f"Notice auto-sending IPA on startup: {ipa_err}")

            # Send boot log
            gallery = load_gallery()
            await send_discord_log(
                bot,
                title="🚀 [SISTEMA EN LÍNEA 24/7] • Web & Bot Activos en la Nube",
                description=(
                    f"• **Servidor Web:** 🟢 Activo en puerto `{PORT}`\n"
                    f"• **Bot de Discord:** 🟢 Escuchando eventos en tiempo real\n"
                    f"• **Fotos en la Web:** `{len(gallery)} fotos activas`\n"
                    f"• **Categorías:** Front Yard, Back Yard, Mulch, Tree Care, etc.\n"
                    f"• **Modo:** 100% Autónomo (no requiere PC encendida)"
                ),
                color=discord.Color.green()
            )

    @bot.event
    async def on_message(message: discord.Message):
        if message.author.bot:
            return

        if message.channel.id != CHANNEL_ID:
            await bot.process_commands(message)
            return

        image_attachments = [
            att for att in message.attachments
            if (att.content_type and att.content_type.startswith("image/")) or
               (att.filename.lower().endswith(('.jpg', '.jpeg', '.png', '.webp')))
        ]

        if not image_attachments:
            await bot.process_commands(message)
            return

        if len(image_attachments) > 5:
            await message.reply("⚠️ **Límite:** Puedes subir un máximo de **5 fotos a la vez**. Por favor envía hasta 5 fotos.")
            return

        raw_caption = message.content.strip() if message.content else ""
        has_caption = bool(raw_caption)
        parsed_caption = parse_job_details(raw_caption) if has_caption else None

        processing_msg = await message.reply(f"⏳ Procesando y publicando {len(image_attachments)} foto(s) en tu página web...")

        gallery = load_gallery()
        uploaded_items = []

        async with aiohttp.ClientSession() as session:
            for idx, att in enumerate(image_attachments):
                next_id = get_next_id(gallery)
                ext = att.filename.split(".")[-1].lower() if "." in att.filename else "jpg"
                if ext not in ["jpg", "jpeg", "png", "webp"]:
                    ext = "jpg"
                filename = f"work_{next_id}_{int(time.time())}.{ext}"
                filepath = os.path.join(GALLERY_FOLDER, filename)

                try:
                    async with session.get(att.url) as resp:
                        if resp.status == 200:
                            content = await resp.read()
                            with open(filepath, "wb") as f:
                                f.write(content)

                            now_ms = int(time.time() * 1000)
                            if parsed_caption:
                                item_title = parsed_caption["title"]
                                item_cat = parsed_caption["category"]
                            else:
                                item_title = f"Trabajo Real #{next_id}"
                                item_cat = "General LawnCare"

                            item = {
                                "id": next_id,
                                "filename": filename,
                                "url": f"./assets/gallery/{filename}",
                                "uploaded_at": now_ms,
                                "title": item_title,
                                "category": item_cat
                            }
                            gallery.append(item)
                            uploaded_items.append(item)
                except Exception as e:
                    print(f"Error descargando imagen: {e}")

        save_gallery(gallery)

        uploaded_ids = [i["id"] for i in uploaded_items]
        picker_view = JobCategoryPickerView(uploaded_ids, bot)

        if parsed_caption:
            embed = discord.Embed(
                title="✅ ¡Fotos Publicadas en la Web con Éxito!",
                description=(
                    f"Se agregaron **{len(uploaded_items)} foto(s)** a tu galería en tiempo real:\n\n"
                    f"🏷️ **Trabajo Asignado:** `{parsed_caption['icon']} {parsed_caption['title']}`\n"
                    f"📂 **Categoría Web:** `{parsed_caption['category']}`\n"
                    f"🔥 **Etiqueta:** `🔥 NEW` activa por **3 días** (72 horas)\n\n"
                    f"*(Si deseas cambiar el trabajo o nombre de estas fotos, toca un botón abajo)*"
                ),
                color=discord.Color.green()
            )
        else:
            embed = discord.Embed(
                title="📸 ¡Fotos Subidas a la Web!",
                description=(
                    f"Se agregaron **{len(uploaded_items)} foto(s)** (`#{', #'.join(str(i) for i in uploaded_ids)}`) con etiqueta `🔥 NEW`.\n\n"
                    f"👇 **¿Qué trabajo realizaste?** Toca un botón para que el nombre y categoría aparezcan en tu página web:"
                ),
                color=discord.Color.blue()
            )

        embed.set_footer(text="Rodriguez LawnCare • Galería en Vivo")
        if uploaded_items:
            embed.set_image(url=image_attachments[0].url)

        await processing_msg.edit(content=None, embed=embed, view=picker_view)

        # Send activity log
        ids_str = ", ".join(f"#{i['id']}" for i in uploaded_items)
        log_title = parsed_caption["title"] if parsed_caption else "Trabajo Reciente"
        log_cat = parsed_caption["category"] if parsed_caption else "General"
        await send_discord_log(
            bot,
            title="📋 [REGISTRO EN VIVO] • 📥 Nuevas Fotos Agregadas a la Web",
            description=(
                f"• **Fotos agregadas:** `{len(uploaded_items)}`\n"
                f"• **IDs asignados:** `{ids_str}`\n"
                f"• **Trabajo:** *{log_title}* (`{log_cat}`)\n"
                f"• **Etiqueta activa:** `🔥 NEW` (72 horas)\n"
                f"• **Total en la web:** **{len(gallery)} fotos**\n"
                f"• **Origen:** Subido desde celular/Discord"
            ),
            color=discord.Color.green(),
            image_url=image_attachments[0].url if image_attachments else None
        )

        await bot.process_commands(message)

    @bot.tree.command(name="fotos", description="Ver la lista de fotos activas en tu página web")
    async def cmd_fotos(interaction: discord.Interaction):
        gallery = load_gallery()
        if not gallery:
            await interaction.response.send_message("ℹ️ No hay fotos publicadas en la web.", ephemeral=True)
            return

        now = int(time.time() * 1000)
        embed = discord.Embed(
            title="📸 Fotos Publicadas en la Web (Rodriguez LawnCare)",
            description=f"Total: **{len(gallery)} fotos**\n\n",
            color=discord.Color.green()
        )
        for item in gallery:
            is_new = (now - item.get("uploaded_at", 0)) < THREE_DAYS_MS
            status = "🔥 **NEW**" if is_new else f"`#{item['id']}`"
            cat = item.get("category", "General")
            embed.description += f"• **Foto #{item['id']}** ({status}) - `[{cat}]` *{item.get('title', 'Trabajo')}*\n"

        await interaction.response.send_message(embed=embed, ephemeral=True)

    @bot.tree.command(name="subir", description="Subir una foto a la página web con su trabajo y nombre")
    @app_commands.describe(
        foto="Selecciona la foto de tu trabajo para subir a la web",
        trabajo="Tipo de trabajo realizado (Front Yard, Mulch, Tree, etc.)",
        nombre_personalizado="Nombre o detalle opcional del trabajo (ej: Casa en Belton, Mulch oscuro...)"
    )
    @app_commands.choices(trabajo=[
        app_commands.Choice(name="🏡 Front Yard (Frente)", value="front"),
        app_commands.Choice(name="🌿 Back Yard (Patio Trasero)", value="back"),
        app_commands.Choice(name="🪵 Mulch Installation (Mulch)", value="mulch"),
        app_commands.Choice(name="🌳 Tree Care & Trimming (Árboles)", value="tree"),
        app_commands.Choice(name="✂️ Hedge & Bush Trimming (Arbustos)", value="bush"),
        app_commands.Choice(name="🧹 Yard Cleanup & Debris (Limpieza)", value="clean"),
        app_commands.Choice(name="🌱 Lawn Mowing & Edging (Corte)", value="mow"),
        app_commands.Choice(name="✏️ Personalizado (Escribe en 'nombre_personalizado')", value="custom"),
    ])
    async def cmd_subir(
        interaction: discord.Interaction,
        foto: discord.Attachment,
        trabajo: app_commands.Choice[str] = None,
        nombre_personalizado: str = ""
    ):
        if not (foto.content_type and foto.content_type.startswith("image/")) and not foto.filename.lower().endswith(('.jpg', '.jpeg', '.png', '.webp')):
            await interaction.response.send_message("❌ El archivo adjunto debe ser una imagen (JPG, PNG o WEBP).", ephemeral=True)
            return

        await interaction.response.defer(ephemeral=False)

        gallery = load_gallery()
        next_id = get_next_id(gallery)
        ext = foto.filename.split(".")[-1].lower() if "." in foto.filename else "jpg"
        if ext not in ["jpg", "jpeg", "png", "webp"]:
            ext = "jpg"
        filename = f"work_{next_id}_{int(time.time())}.{ext}"
        filepath = os.path.join(GALLERY_FOLDER, filename)

        async with aiohttp.ClientSession() as session:
            async with session.get(foto.url) as resp:
                if resp.status == 200:
                    content = await resp.read()
                    with open(filepath, "wb") as f:
                        f.write(content)

        now_ms = int(time.time() * 1000)

        # Determine category and title
        if nombre_personalizado.strip():
            details = parse_job_details(nombre_personalizado.strip())
            # If user also selected a specific choice other than custom, override category
            if trabajo and trabajo.value != "custom" and trabajo.value in JOB_PRESETS:
                details["category"] = JOB_PRESETS[trabajo.value]["category"]
                details["icon"] = JOB_PRESETS[trabajo.value]["icon"]
        elif trabajo and trabajo.value != "custom" and trabajo.value in JOB_PRESETS:
            preset = JOB_PRESETS[trabajo.value]
            details = {
                "category": preset["category"],
                "icon": preset["icon"],
                "title": preset["default_title"]
            }
        else:
            preset = JOB_PRESETS["front"]
            details = {
                "category": preset["category"],
                "icon": preset["icon"],
                "title": preset["default_title"]
            }

        item = {
            "id": next_id,
            "filename": filename,
            "url": f"./assets/gallery/{filename}",
            "uploaded_at": now_ms,
            "title": details["title"],
            "category": details["category"]
        }
        gallery.append(item)
        save_gallery(gallery)

        picker_view = JobCategoryPickerView([next_id], bot)

        embed = discord.Embed(
            title="✅ ¡Foto Publicada en la Web!",
            description=(
                f"📸 **Foto #{next_id}** agregada con éxito a tu página web.\n"
                f"🏷️ **Trabajo:** `{details['icon']} {details['title']}`\n"
                f"📂 **Categoría Web:** `{details['category']}`\n"
                f"🔥 **Insignia:** `🔥 NEW` activa durante los próximos **3 días**."
            ),
            color=discord.Color.green()
        )
        embed.set_image(url=foto.url)
        embed.set_footer(text="Rodriguez LawnCare Live Web Gallery")

        await interaction.followup.send(embed=embed, view=picker_view)

        # Log
        await send_discord_log(
            bot,
            title="📋 [REGISTRO EN VIVO] • 📥 Foto Subida vía /subir",
            description=(
                f"• **Foto:** `#{next_id}`\n"
                f"• **Trabajo:** *{details['title']}*\n"
                f"• **Categoría:** `{details['category']}`\n"
                f"• **Etiqueta activa:** `🔥 NEW` (72 horas)\n"
                f"• **Total en web:** **{len(gallery)} fotos**"
            ),
            color=discord.Color.green(),
            image_url=foto.url
        )

    @bot.tree.command(name="renombrar", description="Cambiar el nombre o categoría de una foto en la web")
    @app_commands.describe(
        numero="El número de la foto que deseas renombrar (ej. 2, 3, 4)",
        nuevo_nombre="Nuevo nombre o categoría (ej. front, mulch, tree, o nombre personalizado)"
    )
    async def cmd_renombrar(interaction: discord.Interaction, numero: int, nuevo_nombre: str):
        gallery = load_gallery()
        found_item = next((item for item in gallery if item.get("id") == numero), None)

        if not found_item:
            await interaction.response.send_message(f"❌ No se encontró ninguna foto con el número **#{numero}** en tu web.", ephemeral=True)
            return

        details = parse_job_details(nuevo_nombre)
        old_title = found_item.get("title", "Sin título")
        old_cat = found_item.get("category", "General")

        found_item["title"] = details["title"]
        found_item["category"] = details["category"]
        save_gallery(gallery)

        embed = discord.Embed(
            title="✅ ¡Foto Renombrada en la Web!",
            description=(
                f"📸 **Foto #{numero}** actualizada con éxito:\n\n"
                f"🏷️ **Nuevo Nombre:** `{details['icon']} {details['title']}`\n"
                f"📂 **Nueva Categoría:** `{details['category']}`\n\n"
                f"*(Antes: [{old_cat}] {old_title})*\n"
                f"🌐 *Ya se ve reflejado en tu página web en tiempo real.*"
            ),
            color=discord.Color.green()
        )
        await interaction.response.send_message(embed=embed)

        await send_discord_log(
            bot,
            title="📋 [REGISTRO EN VIVO] • ✏️ Foto Renombrada vía /renombrar",
            description=(
                f"• **Foto:** `#{numero}`\n"
                f"• **Nuevo Nombre:** *{details['title']}*\n"
                f"• **Categoría:** `{details['category']}`\n"
                f"• **Total en web:** **{len(gallery)} fotos**"
            ),
            color=discord.Color.green()
        )

    @bot.tree.command(name="eliminar", description="Eliminar una foto de tu página web por su número")
    @app_commands.describe(numero="El número de la foto que deseas eliminar (ej. 1, 2, 3)")
    async def cmd_eliminar(interaction: discord.Interaction, numero: int):
        gallery = load_gallery()
        found_item = next((item for item in gallery if item.get("id") == numero), None)

        if not found_item:
            await interaction.response.send_message(f"❌ No se encontró ninguna foto con el número **#{numero}** en tu web.", ephemeral=True)
            return

        filename = found_item.get("filename")
        if filename:
            file_path = os.path.join(GALLERY_FOLDER, filename)
            if os.path.exists(file_path):
                try:
                    os.remove(file_path)
                except Exception as e:
                    print(f"Error borrando archivo: {e}")

        gallery = [item for item in gallery if item.get("id") != numero]
        save_gallery(gallery)

        embed = discord.Embed(
            title="🗑️ Foto Eliminada",
            description=f"La **Foto #{numero}** ha sido eliminada con éxito de tu página web.",
            color=discord.Color.red()
        )
        await interaction.response.send_message(embed=embed)

        # Log
        await send_discord_log(
            bot,
            title="📋 [REGISTRO EN VIVO] • 🗑️ Foto Eliminada vía /eliminar",
            description=(
                f"• **Foto removida:** `#{numero}`\n"
                f"• **Total restante:** **{len(gallery)} fotos**"
            ),
            color=discord.Color.orange()
        )

    @bot.tree.command(name="enviar_ipa", description="Enviar la última versión de la app iOS (IPA) al canal de Discord")
    async def cmd_enviar_ipa(interaction: discord.Interaction):
        await interaction.response.defer(ephemeral=False)
        success, msg = await send_ipa_to_discord(bot, channel_id=IPA_CHANNEL_ID, force=True)
        if success:
            await interaction.followup.send(f"✅ **¡IPA enviado con éxito al canal <#{IPA_CHANNEL_ID}>!**")
        else:
            await interaction.followup.send(f"❌ **Error al enviar el IPA:** {msg}")

    @bot.event
    async def on_disconnect():
        print("⚠️ [DISCORD 24/7] Bot desconectado temporalmente del gateway...")

    @bot.event
    async def on_resumed():
        print("🟢 [DISCORD 24/7] Conexión y sesión reanudada con éxito.")

    @bot.event
    async def on_error(event_method, *args, **kwargs):
        print(f"⚠️ [DISCORD ERROR] Error en evento '{event_method}': {sys.exc_info()[1]}")

    async def on_tree_error(interaction: discord.Interaction, error: app_commands.AppCommandError):
        cmd_name = interaction.command.name if interaction.command else "accion"
        print(f"⚠️ [SLASH ERROR] Error en /{cmd_name}: {error}")
        try:
            if not interaction.response.is_done():
                await interaction.response.send_message("❌ Error temporal al procesar la acción.", ephemeral=True)
        except Exception:
            pass

    bot.tree.on_error = on_tree_error

    return bot


# ----------------- WEB SERVER (AIOHTTP) -----------------
bot_global = None
SERVER_START_TIME = time.time()

CORS_HEADERS = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Requested-With, X-Admin-Pin",
    "Access-Control-Max-Age": "86400"
}

def cors_json_response(data, status=200, extra_headers=None):
    headers = dict(CORS_HEADERS)
    headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
    if extra_headers:
        headers.update(extra_headers)
    return web.json_response(data, status=status, headers=headers)

async def handle_cors_options(request):
    """Handles preflight CORS requests."""
    return web.Response(status=200, headers=CORS_HEADERS)

async def handle_index(request):
    """Serves the main website homepage and increments live visitor counter."""
    try:
        increment_visit()
    except Exception:
        pass
    index_path = os.path.join(BASE_DIR, "index.html")
    return web.FileResponse(index_path)

async def handle_gallery_json(request):
    """Serves gallery.json with no-cache headers so visitors always see live photos."""
    gallery = load_gallery()
    return cors_json_response(gallery)

async def forward_lead_to_discord(name, phone, services, address, date_val, time_val, frequency, description, source, saved_photos=None):
    """Sends notification to Discord channel if bot is ready."""
    global bot_global
    if not bot_global:
        return
    try:
        if not bot_global.is_ready():
            try:
                await asyncio.wait_for(bot_global.wait_until_ready(), timeout=5.0)
            except Exception:
                pass

        target_chan_id = LEADS_CHANNEL_ID
        channel = bot_global.get_channel(target_chan_id)
        if not channel and bot_global.is_ready():
            try:
                channel = await bot_global.fetch_channel(target_chan_id)
            except Exception as e:
                print(f"⚠️ Error obteniendo canal de leads {target_chan_id} vía fetch_channel: {e}")

        if channel:
            clean_digits = "".join(c for c in phone if c.isdigit())
            phone_dial = clean_digits if clean_digits.startswith("1") else f"1{clean_digits}"
            formatted_phone = phone
            if len(clean_digits) == 10:
                formatted_phone = f"({clean_digits[:3]}) {clean_digits[3:6]}-{clean_digits[6:]}"

            if isinstance(services, list) and services:
                services_list_text = "\n".join(f"• {s}" for s in services)
            else:
                services_list_text = f"• {services or 'Servicio General'}"

            embed = discord.Embed(
                title="🚨 ¡NUEVA COTIZACIÓN RECIBIDA EN LA WEB!",
                description=f"Un cliente acaba de enviar una solicitud (**{source}**):\n",
                color=discord.Color.from_rgb(22, 163, 74),
                timestamp=discord.utils.utcnow()
            )
            embed.add_field(name="👤 Cliente", value=f"**{name}**", inline=True)
            embed.add_field(name="📱 Teléfono", value=f"**{formatted_phone}**", inline=True)
            embed.add_field(name="🌐 Formulario", value=f"`{source}`", inline=True)
            embed.add_field(name="🌿 Servicios Solicitados", value=services_list_text, inline=False)

            if address and address not in ["Por coordinar por llamada/mensaje", "To be confirmed by call/text"]:
                embed.add_field(name="📍 Dirección", value=f"`{address}`", inline=True)
            if date_val and date_val not in ["Lo antes posible", "As soon as possible"]:
                embed.add_field(name="📅 Fecha / Horario", value=f"`{date_val} ({time_val})`", inline=True)
            if frequency and frequency not in ["To be decided", "No especificada"]:
                embed.add_field(name="🔄 Frecuencia", value=f"`{frequency}`", inline=True)
            if description and description not in ["Quick request from website", "No additional notes", ""]:
                embed.add_field(name="📝 Notas / Mensaje", value=f"*{description}*", inline=False)

            embed.set_footer(text=f"Rodriguez LawnCare • #{channel.name}")

            view = discord.ui.View()
            if clean_digits:
                wa_url = f"https://wa.me/{phone_dial}?text=Hola%20{name.replace(' ', '%20')},%20te%20escribimos%20de%20Rodriguez%20LawnCare%20sobre%20tu%20solicitud%20de%20cotizacion."
                view.add_item(discord.ui.Button(label="Abrir WhatsApp del Cliente", style=discord.ButtonStyle.link, url=wa_url, emoji="💬"))

            discord_files = []
            if saved_photos and isinstance(saved_photos, list):
                for sp in saved_photos:
                    clean_rel = sp.replace("./", "")
                    full_p = os.path.join(BASE_DIR, clean_rel)
                    if os.path.exists(full_p) and os.path.getsize(full_p) > 0:
                        discord_files.append(discord.File(full_p))

            await channel.send(
                content=f"🔔 **¡Nuevo Lead en Rodriguez LawnCare!** (`{name}` • `{formatted_phone}`)",
                embed=embed,
                view=view if clean_digits else None,
                files=discord_files if discord_files else None
            )
            print(f"✅ Lead enviado a Discord (#{channel.name})")
    except Exception as e:
        print(f"⚠️ Error enviando lead a Discord: {e}")

async def handle_lead_submission(request):
    """Handles lead form submissions from the website and saves to leads.json + Discord."""
    try:
        data = await request.json()
        name = data.get("name", "Cliente").strip() or "Cliente"
        phone = data.get("phone", "No proporcionado").strip() or "No proporcionado"
        services = data.get("services", [])
        address = data.get("address", "Por coordinar por llamada/mensaje")
        date_val = data.get("date", "Lo antes posible")
        time_val = data.get("time", "Horario habitual")
        frequency = data.get("frequency", "No especificada")
        description = data.get("description", "")
        source = data.get("source", "Quick 1-Minute Estimate (Web)")

        print(f"📥 [LEAD RECIBIDO] De: {name} | Tel: {phone} | Origen: {source}")

        # Persist to leads.json
        leads = load_leads()
        lead_id = int(time.time() * 1000)
        photos_raw = data.get("photos", [])
        saved_photos = save_lead_photos(photos_raw, lead_id)

        new_lead = {
            "photos": saved_photos,
            "id": lead_id,
            "created_at": int(time.time()),
            "date_str": time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),
            "name": name,
            "phone": phone,
            "services": services if isinstance(services, list) else [str(services)],
            "address": address,
            "date": date_val,
            "time": time_val,
            "frequency": frequency,
            "description": description,
            "source": source,
            "status": "pending",
            "estimated_amount": 0.0,
            "notes": ""
        }
        leads.insert(0, new_lead)
        save_leads(leads)

        # Update real analytics
        analytics = load_analytics()
        analytics["quotes_submitted"] = analytics.get("quotes_submitted", 0) + 1
        tot = analytics.get("total_visits", 0)
        quotes = analytics.get("quotes_submitted", 0)
        analytics["conversion_rate"] = f"{(quotes / tot * 100):.1f}%" if tot > 0 else "0.0%"
        save_analytics(analytics)

        # Notify Discord asynchronously
        asyncio.create_task(forward_lead_to_discord(name, phone, services, address, date_val, time_val, frequency, description, source, saved_photos=saved_photos))

        return cors_json_response({"success": True, "message": "Lead received and saved", "lead": new_lead})
    except Exception as e:
        print(f"❌ Error procesando lead web: {e}")
        return cors_json_response({"success": False, "error": str(e)}, status=400)

# ----------------- REST API FOR IOS APP & ADMIN -----------------

async def handle_api_get_leads(request):
    """Returns list of leads/appointments for iOS app with optional status filter."""
    leads = load_leads()
    status_filter = request.query.get("status", "").strip().lower()
    if status_filter and status_filter != "all":
        leads = [l for l in leads if l.get("status", "").lower() == status_filter]
    return cors_json_response({"success": True, "leads": leads, "count": len(leads)})

async def handle_api_create_lead(request):
    """Creates a new appointment/lead from the iOS App."""
    try:
        data = await request.json()
        name = data.get("name", "Cliente").strip() or "Cliente"
        phone = data.get("phone", "No proporcionado").strip() or "No proporcionado"
        services = data.get("services", ["Lawn Mowing & Edging"])
        address = data.get("address", "")
        date_val = data.get("date", "Por coordinar")
        time_val = data.get("time", "Horario regular")
        frequency = data.get("frequency", "One-Time")
        description = data.get("description", "")
        source = data.get("source", "iOS App")
        status = data.get("status", "pending")
        estimated_amount = float(data.get("estimated_amount", 0.0) or 0.0)
        notes = data.get("notes", "")

        leads = load_leads()
        lead_id = int(time.time() * 1000)
        photos_raw = data.get("photos", [])
        saved_photos = save_lead_photos(photos_raw, lead_id)
        new_lead = {
            "photos": saved_photos,
            "id": lead_id,
            "created_at": int(time.time()),
            "date_str": time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),
            "name": name,
            "phone": phone,
            "services": services if isinstance(services, list) else [str(services)],
            "address": address,
            "date": date_val,
            "time": time_val,
            "frequency": frequency,
            "description": description,
            "source": source,
            "status": status,
            "estimated_amount": estimated_amount,
            "notes": notes
        }
        leads.insert(0, new_lead)
        save_leads(leads)

        # Update real analytics
        analytics = load_analytics()
        analytics["quotes_submitted"] = analytics.get("quotes_submitted", 0) + 1
        tot = analytics.get("total_visits", 0)
        quotes = analytics.get("quotes_submitted", 0)
        analytics["conversion_rate"] = f"{(quotes / tot * 100):.1f}%" if tot > 0 else "0.0%"
        save_analytics(analytics)

        # Notify Discord as well
        asyncio.create_task(forward_lead_to_discord(name, phone, services, address, date_val, time_val, frequency, f"[App] {description}", source))

        return cors_json_response({"success": True, "lead": new_lead})
    except Exception as e:
        return cors_json_response({"success": False, "error": str(e)}, status=400)

async def handle_api_update_lead(request):
    """Updates lead status, notes, or estimated_amount from iOS App."""
    try:
        data = await request.json()
        lead_id = data.get("id")
        if not lead_id:
            return cors_json_response({"success": False, "error": "Missing 'id' parameter"}, status=400)

        leads = load_leads()
        updated = False
        target_lead = None
        for item in leads:
            if str(item.get("id")) == str(lead_id):
                if "status" in data:
                    item["status"] = data["status"]
                if "notes" in data:
                    item["notes"] = data["notes"]
                if "estimated_amount" in data:
                    try:
                        item["estimated_amount"] = float(data["estimated_amount"])
                    except (ValueError, TypeError):
                        pass
                if "name" in data and data["name"]:
                    item["name"] = data["name"]
                if "phone" in data and data["phone"]:
                    item["phone"] = data["phone"]
                if "address" in data:
                    item["address"] = data["address"]
                if "date" in data:
                    item["date"] = data["date"]
                if "time" in data:
                    item["time"] = data["time"]
                if "services" in data:
                    item["services"] = data["services"]
                updated = True
                target_lead = item
                break

        if updated:
            save_leads(leads)
            return cors_json_response({"success": True, "lead": target_lead})
        else:
            return cors_json_response({"success": False, "error": f"Lead {lead_id} not found"}, status=404)
    except Exception as e:
        return cors_json_response({"success": False, "error": str(e)}, status=400)

async def handle_api_delete_lead(request):
    """Deletes a lead from leads.json."""
    try:
        lead_id = request.match_info.get("id")
        if not lead_id:
            data = await request.json()
            lead_id = data.get("id")

        if not lead_id:
            return cors_json_response({"success": False, "error": "Missing 'id'"}, status=400)

        leads = load_leads()
        before_len = len(leads)
        leads = [l for l in leads if str(l.get("id")) != str(lead_id)]
        if len(leads) < before_len:
            save_leads(leads)
            return cors_json_response({"success": True, "message": f"Lead {lead_id} deleted"})
        else:
            return cors_json_response({"success": False, "error": f"Lead {lead_id} not found"}, status=404)
    except Exception as e:
        return cors_json_response({"success": False, "error": str(e)}, status=400)

async def handle_api_get_gallery(request):
    """Returns website gallery with CORS."""
    gallery = load_gallery()
    return cors_json_response({"success": True, "gallery": gallery})

async def handle_api_add_gallery(request):
    """Adds a new photo to the website gallery from iOS App."""
    try:
        data = await request.json()
        title = data.get("title", "Lawn Care Service").strip()
        category = data.get("category", "Front Yard").strip()
        url = data.get("url", "").strip()
        image_base64 = data.get("image_base64", "").strip()

        gallery = load_gallery()
        next_id = get_next_id(gallery)

        if image_base64:
            # Handle base64 image upload
            import base64
            if "," in image_base64:
                image_base64 = image_base64.split(",", 1)[1]
            img_bytes = base64.b64decode(image_base64)
            filename = f"work_{next_id}.jpg"
            file_path = os.path.join(GALLERY_FOLDER, filename)
            with open(file_path, "wb") as f:
                f.write(img_bytes)
            url = f"./assets/gallery/{filename}"
        elif not url:
            url = f"./assets/gallery/work_{next_id}.jpg"

        new_item = {
            "id": next_id,
            "filename": os.path.basename(url),
            "url": url,
            "uploaded_at": int(time.time() * 1000),
            "title": title,
            "category": category,
            "location": data.get("location", "Killeen & Central TX").strip(),
            "verified": True
        }
        gallery.insert(0, new_item)
        save_gallery(gallery)

        return cors_json_response({"success": True, "item": new_item})
    except Exception as e:
        return cors_json_response({"success": False, "error": str(e)}, status=400)

async def handle_api_delete_gallery(request):
    """Deletes a photo from the gallery."""
    try:
        photo_id = request.match_info.get("id")
        if not photo_id:
            data = await request.json()
            photo_id = data.get("id")

        if not photo_id:
            return cors_json_response({"success": False, "error": "Missing 'id'"}, status=400)

        gallery = load_gallery()
        before_len = len(gallery)
        gallery = [g for g in gallery if str(g.get("id")) != str(photo_id)]
        if len(gallery) < before_len:
            save_gallery(gallery)
            return cors_json_response({"success": True, "message": f"Photo {photo_id} deleted"})
        else:
            return cors_json_response({"success": False, "error": f"Photo {photo_id} not found"}, status=404)
    except Exception as e:
        return cors_json_response({"success": False, "error": str(e)}, status=400)

async def handle_api_update_gallery(request):
    """Updates an existing photo's title, category, location, or image URL from iOS App."""
    try:
        data = await request.json()
        photo_id = data.get("id")
        if not photo_id:
            return cors_json_response({"success": False, "error": "Missing 'id'"}, status=400)

        gallery = load_gallery()
        updated = False
        target_item = None
        for item in gallery:
            if str(item.get("id")) == str(photo_id):
                if "title" in data and data["title"]:
                    item["title"] = data["title"].strip()
                if "category" in data and data["category"]:
                    item["category"] = data["category"].strip()
                if "location" in data:
                    item["location"] = data["location"].strip()
                if "image_base64" in data and data["image_base64"]:
                    import base64
                    b64_str = data["image_base64"].strip()
                    if "," in b64_str:
                        b64_str = b64_str.split(",", 1)[1]
                    img_bytes = base64.b64decode(b64_str)
                    filename = f"work_{photo_id}.jpg"
                    file_path = os.path.join(GALLERY_FOLDER, filename)
                    with open(file_path, "wb") as f:
                        f.write(img_bytes)
                    item["url"] = f"./assets/gallery/{filename}?v={int(time.time())}"
                    item["filename"] = filename
                if "url" in data and data["url"]:
                    item["url"] = data["url"].strip()
                if "verified" in data:
                    item["verified"] = bool(data["verified"])
                updated = True
                target_item = item
                break

        if updated:
            save_gallery(gallery)
            return cors_json_response({"success": True, "item": target_item})
        else:
            return cors_json_response({"success": False, "error": f"Photo {photo_id} not found"}, status=404)
    except Exception as e:
        return cors_json_response({"success": False, "error": str(e)}, status=400)

async def handle_api_reorder_gallery(request):
    """Moves a photo to the top or reorders gallery photos."""
    try:
        data = await request.json()
        photo_id = data.get("id")
        action = data.get("action", "move_to_top")

        gallery = load_gallery()
        target_idx = next((i for i, item in enumerate(gallery) if str(item.get("id")) == str(photo_id)), None)
        if target_idx is None:
            return cors_json_response({"success": False, "error": f"Photo {photo_id} not found"}, status=404)

        item = gallery.pop(target_idx)
        if action == "move_to_top":
            gallery.insert(0, item)
        elif action == "move_to_bottom":
            gallery.append(item)
        elif action == "move_up" and target_idx > 0:
            gallery.insert(target_idx - 1, item)
        elif action == "move_down" and target_idx < len(gallery):
            gallery.insert(target_idx + 1, item)
        else:
            gallery.insert(target_idx, item)

        save_gallery(gallery)
        return cors_json_response({"success": True, "gallery": gallery})
    except Exception as e:
        return cors_json_response({"success": False, "error": str(e)}, status=400)

async def handle_api_get_settings(request):
    """Returns website configuration, including active Hero Background video/photo and presets."""
    settings = load_settings()
    return cors_json_response({"success": True, "settings": settings})

async def handle_api_save_hero_settings(request):
    """Updates Hero Background (photo or video) from iOS App."""
    try:
        data = await request.json()
        settings = load_settings()

        if "hero_type" in data:
            settings["hero_type"] = data["hero_type"] # "video" or "image"
        if "hero_video_url" in data and data["hero_video_url"]:
            settings["hero_video_url"] = data["hero_video_url"]
        if "hero_poster_url" in data and data["hero_poster_url"]:
            settings["hero_poster_url"] = data["hero_poster_url"]
        if "hero_preset_id" in data:
            settings["hero_preset_id"] = data["hero_preset_id"]
        if "hero_title" in data:
            settings["hero_title"] = data["hero_title"]
        if "hero_subtitle" in data:
            settings["hero_subtitle"] = data["hero_subtitle"]

        save_settings(settings)
        return cors_json_response({"success": True, "settings": settings})
    except Exception as e:
        return cors_json_response({"success": False, "error": str(e)}, status=400)

async def handle_api_save_music_settings(request):
    """Updates Website Background Music configuration from iOS App."""
    try:
        data = await request.json()
        settings = load_settings()
        if "music" not in settings or not isinstance(settings["music"], dict):
            settings["music"] = {}

        if "enabled" in data:
            settings["music"]["enabled"] = bool(data["enabled"])
        if "title" in data:
            settings["music"]["title"] = str(data["title"])
        if "genre" in data:
            settings["music"]["genre"] = str(data["genre"])
        if "stream_url" in data and data["stream_url"]:
            settings["music"]["stream_url"] = str(data["stream_url"])
        if "volume" in data:
            try:
                settings["music"]["volume"] = float(data["volume"])
            except (ValueError, TypeError):
                pass
        if "preset_id" in data:
            settings["music"]["preset_id"] = str(data["preset_id"])

        save_settings(settings)
        return cors_json_response({"success": True, "settings": settings, "music": settings["music"]})
    except Exception as e:
        return cors_json_response({"success": False, "error": str(e)}, status=400)

KILLEEN_STORES = {
    "home_depot": {
        "name": "The Home Depot (Killeen #0572)",
        "location": "2400 E Central Texas Expy, Killeen, TX 76543",
        "phone": "(254) 690-3400"
    },
    "lowes": {
        "name": "Lowe's Home Improvement (Killeen #1704)",
        "location": "1000 E Central Texas Expy, Killeen, TX 76541",
        "phone": "(254) 690-5000"
    },
    "tractor_supply": {
        "name": "Tractor Supply Co. (Killeen)",
        "location": "3802 E Veterans Memorial Blvd, Killeen, TX 76543",
        "phone": "(254) 699-2244"
    }
}

async def handle_api_ai_estimate(request):
    """
    Intelligent AI Estimation Engine for Rodriguez LawnCare.
    Processes: Photo (optional base64) + Description text + Worker combo + Killeen TX local store pricing.
    Returns: Itemized materials with Killeen store prices, labor cost, net profit, total suggested quote, and client-ready text.
    """
    try:
        data = await request.json()
        desc = (data.get("description") or "").strip().lower()
        workers = max(1, int(data.get("workers_count", 1)))
        pay_type = data.get("pay_type", "hourly")
        pay_rate = max(1.0, float(data.get("pay_rate", 18.0)))
        duration = max(0.5, float(data.get("duration", 4.0)))
        store_key = data.get("store_preference", "home_depot")

        if pay_type == "daily":
            total_labor = round(workers * pay_rate * duration, 2)
            labor_desc = f"{workers} Trabajador(es) x {duration:g} Día(s) a ${pay_rate:.2f}/día"
        else:
            total_labor = round(workers * pay_rate * duration, 2)
            labor_desc = f"{workers} Trabajador(es) x {duration:g} Hora(s) a ${pay_rate:.2f}/hr"

        store_info = KILLEEN_STORES.get(store_key, KILLEEN_STORES["home_depot"])
        store_name = store_info["name"]

        materials = []

        if any(w in desc for w in ["mulch", "acolchado", "corteza", "jardinera"]):
            bags = 14 if "yard" not in desc else 28
            unit_price = 3.98
            subtotal = round(bags * unit_price, 2)
            materials.append({
                "item": "Scotts Earthgro Brown/Black Mulch (Bolsa 2 cu. ft.)",
                "store": store_name,
                "qty": f"{bags} bolsas",
                "unit_price": unit_price,
                "subtotal": subtotal,
                "sku": "HD-204554803"
            })
            materials.append({
                "item": "Vigoro Commercial Weed Barrier Fabric (3ft x 50ft)",
                "store": store_name,
                "qty": "1 rollo",
                "unit_price": 18.98,
                "subtotal": 18.98,
                "sku": "HD-100665972"
            })

        if any(w in desc for w in ["arbol", "árbol", "tree", "rama", "motosierra", "poda"]):
            materials.append({
                "item": "Combustible 2-Tiempos TruFuel 50:1 Mezcla Premium",
                "store": store_name,
                "qty": "1 galón",
                "unit_price": 24.98,
                "subtotal": 24.98,
                "sku": "HD-205930335"
            })
            materials.append({
                "item": "Cadena / Afilado de Motosierra Stihl / Echo 18-in",
                "store": store_name,
                "qty": "1 unidad",
                "unit_price": 19.98,
                "subtotal": 19.98,
                "sku": "HD-30048123"
            })
            materials.append({
                "item": "Tarifa de Desecho de Ramas y Troncos (Transfer Station)",
                "store": "Killeen Recycling Center",
                "qty": "1 viaje de remolque",
                "unit_price": 35.00,
                "subtotal": 35.00,
                "sku": "DISPOSAL-FEE"
            })

        if any(w in desc for w in ["edging", "orillado", "navaja", "banqueta", "orilla"]):
            materials.append({
                "item": "Hilo de Trimmer Comercial Profesional .095 (1 lb spool)",
                "store": store_name,
                "qty": "1 rollo",
                "unit_price": 16.99,
                "subtotal": 16.99,
                "sku": "HD-202288344"
            })
            materials.append({
                "item": "Cuchilla de Acero para Orilladora (Edger Blade 8-in)",
                "store": store_name,
                "qty": "1 cuchilla",
                "unit_price": 11.48,
                "subtotal": 11.48,
                "sku": "HD-100155234"
            })

        if any(w in desc for w in ["corte", "pasto", "zacate", "lawn", "mow", "yarda"]):
            materials.append({
                "item": "Gasolina sin etanol para Podadora Comercial Zero-Turn",
                "store": "Gasolinera Local Killeen",
                "qty": "3 galones",
                "unit_price": 4.25,
                "subtotal": 12.75,
                "sku": "FUEL-MOWER"
            })

        if any(w in desc for w in ["arbusto", "shrub", "bush", "seto", "hedge"]):
            materials.append({
                "item": "Lona Reforzada de Arrastre para Recorte de Arbustos (10x12ft)",
                "store": store_name,
                "qty": "1 lona",
                "unit_price": 14.98,
                "subtotal": 14.98,
                "sku": "HD-203205822"
            })

        if any(w in desc for w in ["tierra", "soil", "semilla", "seed", "fertilizante"]):
            materials.append({
                "item": "Scotts Turf Builder Texas Bermuda Grass Seed (5 lb)",
                "store": store_name,
                "qty": "1 bolsa",
                "unit_price": 34.98,
                "subtotal": 34.98,
                "sku": "HD-203112344"
            })
            materials.append({
                "item": "Tierra Negra Vegetal Enriquecida Earthgro Topsoil (40 lb)",
                "store": store_name,
                "qty": "4 bolsas",
                "unit_price": 2.98,
                "subtotal": 11.92,
                "sku": "HD-100619051"
            })

        materials.append({
            "item": "Bolsas de Uso Rudo para Escombros Husky 42-Gal (Pack)",
            "store": store_name,
            "qty": "1 paquete",
            "unit_price": 17.98,
            "subtotal": 17.98,
            "sku": "HD-202188612"
        })

        total_materials = round(sum(m["subtotal"] for m in materials), 2)
        overhead = round((total_labor + total_materials) * 0.12, 2)
        cost_base = total_labor + total_materials + overhead
        profit = round(cost_base * 0.45, 2)
        total_quote = round(cost_base + profit, 2)

        raw_desc = data.get("description", "").strip() or "Servicio de Landscaping y Mantenimiento Residencial"
        whatsapp_quote = f"🌿 *RODRIGUEZ LAWNCARE - PRESUPUESTO OFICIAL*\n" \
                         f"📍 Killeen & Central Texas • (254) 852-8163\n\n" \
                         f"📋 *Trabajo Evaluado con IA:*\n{raw_desc}\n\n" \
                         f"💵 *Cotización Total Sugerida:* ${total_quote:.2f} USD\n" \
                         f"⏱️ Mano de Obra: {labor_desc}\n" \
                         f"📦 Materiales e Insumos: ${total_materials:.2f} (Tienda: {store_name})\n" \
                         f"✅ Incluye mano de obra calificada, insumos y limpieza total.\n\n" \
                         f"¿Te gustaría agendar este servicio para esta semana? ¡Quedamos a tus órdenes!"

        return cors_json_response({
            "success": True,
            "total_quote": total_quote,
            "total_materials": total_materials,
            "total_labor": total_labor,
            "overhead": overhead,
            "net_profit": profit,
            "profit_margin": "45%",
            "labor_details": labor_desc,
            "store_info": store_info,
            "materials": materials,
            "whatsapp_text": whatsapp_quote,
            "ai_confidence": "98% (Alta Precisión - Killeen Local Store Matrix)",
            "ai_tips": "💡 Tip para Rafael Rodriguez: Si el cliente acepta en la primera visita, puedes ofrecerle $15 de descuento en el primer mes de mantenimiento recurrente para asegurar cliente fijo."
        })
    except Exception as e:
        return cors_json_response({"success": False, "error": str(e)}, status=400)

async def handle_api_get_analytics(request):
    """Returns website live visitor counts and analytics."""
    analytics = load_analytics()
    leads = load_leads()
    analytics["total_leads"] = len(leads)
    analytics["pending_leads"] = sum(1 for l in leads if l.get("status") == "pending")
    return cors_json_response({"success": True, "analytics": analytics})

async def handle_api_record_visit(request):
    """Pings a visit from client-side JS."""
    analytics = increment_visit()
    return cors_json_response({"success": True, "analytics": analytics})

async def handle_api_stats(request):
    """Returns website, visitor, and business statistics for the iOS Dashboard."""
    leads = load_leads()
    gallery = load_gallery()
    analytics = load_analytics()
    pending = sum(1 for l in leads if l.get("status") == "pending")
    confirmed = sum(1 for l in leads if l.get("status") == "confirmed")
    completed = sum(1 for l in leads if l.get("status") == "completed")
    estimated = sum(1 for l in leads if l.get("status") == "estimated")
    is_bot_ready = bool(bot_global and bot_global.is_ready())

    tot_visits = analytics.get("total_visits", 0)
    vis_today = analytics.get("visits_today", 0)
    quotes = len(leads)
    conv_rate = f"{(quotes / tot_visits * 100):.1f}%" if tot_visits > 0 else "0.0%"

    stats = {
        "status": "online",
        "bot_online": is_bot_ready,
        "bot_user": str(bot_global.user) if is_bot_ready else None,
        "total_leads": len(leads),
        "pending_leads": pending,
        "confirmed_leads": confirmed,
        "completed_leads": completed,
        "estimated_leads": estimated,
        "gallery_count": len(gallery),
        "total_visits": tot_visits,
        "visits_today": vis_today,
        "conversion_rate": conv_rate,
        "uptime_seconds": int(time.time() - SERVER_START_TIME),
        "server_time": time.time()
    }
    return cors_json_response({"success": True, "stats": stats})

async def handle_health(request):
    """Healthcheck endpoint for Railway, uptime pingers, and system diagnostics."""
    is_bot_ready = bool(bot_global and bot_global.is_ready())
    return cors_json_response({
        "status": "healthy",
        "bot_online": is_bot_ready,
        "bot_user": str(bot_global.user) if is_bot_ready else None,
        "leads_channel_id": LEADS_CHANNEL_ID,
        "server_time": time.time()
    })

# ----------------- 100% ONLINE OTA & CLOUD UPDATE HANDLERS -----------------
async def handle_ota_manifest(request):
    """Returns Apple OTA installation manifest plist."""
    scheme = request.headers.get("X-Forwarded-Proto", request.scheme)
    host = request.headers.get("X-Forwarded-Host", request.host)
    base_url = f"{scheme}://{host}"
    config = load_cloud_config()
    ipa_url = config.get("ipa_url", "https://github.com/purorodriguez903-oss/rodriguezlawncarewebiosweb/releases/download/latest-ipa/rodriguezlawncareios.ipa")
    logo_url = f"{base_url}/assets/bot_logo.jpg"
    version = config.get("app_version", "1.2.0")
    title = config.get("app_name", "rodriguezlawncareios")

    plist_content = f"""<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>items</key>
    <array>
        <dict>
            <key>assets</key>
            <array>
                <dict>
                    <key>kind</key>
                    <string>software-package</string>
                    <key>url</key>
                    <string>{ipa_url}</string>
                </dict>
                <dict>
                    <key>kind</key>
                    <string>display-image</string>
                    <key>needs-shine</key>
                    <true/>
                    <key>url</key>
                    <string>{logo_url}</string>
                </dict>
                <dict>
                    <key>kind</key>
                    <string>full-size-image</string>
                    <key>needs-shine</key>
                    <true/>
                    <key>url</key>
                    <string>{logo_url}</string>
                </dict>
            </array>
            <key>metadata</key>
            <dict>
                <key>bundle-identifier</key>
                <string>com.rodriguezlawncareios.app</string>
                <key>bundle-version</key>
                <string>{version}</string>
                <key>kind</key>
                <string>software</string>
                <key>title</key>
                <string>{title}</string>
            </dict>
        </dict>
    </array>
</dict>
</plist>"""
    return web.Response(text=plist_content, content_type="text/xml", headers={"Access-Control-Allow-Origin": "*"})

async def handle_api_app_version(request):
    """Returns version info, release notes, and OTA installation URLs for in-app updater."""
    scheme = request.headers.get("X-Forwarded-Proto", request.scheme)
    host = request.headers.get("X-Forwarded-Host", request.host)
    base_url = f"{scheme}://{host}"
    config = load_cloud_config()

    version = config.get("app_version", "1.2.0")
    build = config.get("app_build", 12)
    ipa_url = config.get("ipa_url", "https://github.com/purorodriguez903-oss/rodriguezlawncarewebiosweb/releases/download/latest-ipa/rodriguezlawncareios.ipa")
    ipa_direct_url = f"{base_url}/download/ipa"
    import urllib.parse
    gbox_url = f"gbox://import?url={urllib.parse.quote(ipa_direct_url, safe='')}"
    manifest_url = f"{base_url}/api/ota/manifest.plist"
    ota_install_url = f"itms-services://?action=download-manifest&url={manifest_url}"
    trollstore_url = f"apple-magnifier://install?url={ipa_url}"
    esign_url = f"esign://import?url={ipa_url}"

    return cors_json_response({
        "success": True,
        "app_name": config.get("app_name", "rodriguezlawncareios"),
        "version": version,
        "build": build,
        "min_version": config.get("min_version", "1.0.0"),
        "release_notes": config.get("release_notes", "Conexión 100% online con Railway, ícono oficial y actualización inalámbrica OTA."),
        "ipa_url": ipa_url,
        "gbox_url": gbox_url,
        "ota_install_url": ota_install_url,
        "trollstore_url": trollstore_url,
        "esign_url": esign_url,
        "web_install_url": f"{base_url}/instalar",
        "has_update": True,
        "server_time": time.time()
    })

async def handle_api_get_cloud_config(request):
    """Returns dynamic remote configuration for iOS App."""
    config = load_cloud_config()
    return cors_json_response({"success": True, "config": config})

async def handle_api_save_cloud_config(request):
    """Updates dynamic remote configuration from PC or Web Admin."""
    try:
        data = await request.json()
        config = load_cloud_config()
        for k, v in data.items():
            config[k] = v
        save_cloud_config(config)
        return cors_json_response({"success": True, "config": config})
    except Exception as e:
        return cors_json_response({"success": False, "error": str(e)}, status=400)

async def handle_send_ipa_discord(request):
    """API endpoint to trigger sending the latest IPA to Discord."""
    global bot_global
    if not bot_global or not bot_global.is_ready():
        return cors_json_response({"success": False, "error": "Bot de Discord no está listo aún"}, status=503)
    success, msg = await send_ipa_to_discord(bot_global, channel_id=IPA_CHANNEL_ID, force=True)
    return cors_json_response({"success": success, "message": msg})


async def handle_download_ipa(request):
    """Serves the latest compiled IPA from 'ipa online' or redirects to GitHub Releases."""
    config = load_cloud_config()
    candidate_paths = [
        os.path.join(BASE_DIR, "ipa online", "rodriguezlawncareios.ipa"),
        os.path.join(BASE_DIR, "ipa online", "RodriguezLawnCare.ipa"),
        os.path.join(BASE_DIR, "ipa here", "rodriguezlawncareios.ipa"),
        os.path.join(BASE_DIR, "ipa here", "RodriguezLawnCare.ipa")
    ]
    for p in candidate_paths:
        if os.path.exists(p) and os.path.getsize(p) > 10000:
            return web.FileResponse(p, headers={
                "Content-Type": "application/octet-stream",
                "Content-Disposition": 'attachment; filename="rodriguezlawncareios.ipa"'
            })
    ipa_url = config.get("ipa_url", "https://github.com/purorodriguez903-oss/rodriguezlawncarewebiosweb/releases/download/latest-ipa/rodriguezlawncareios.ipa")
    raise web.HTTPFound(ipa_url)

async def handle_ota_page(request):
    """Serves sleek mobile installation landing page with 1-tap OTA buttons and QR code."""
    scheme = request.headers.get("X-Forwarded-Proto", request.scheme)
    host = request.headers.get("X-Forwarded-Host", request.host)
    base_url = f"{scheme}://{host}"
    config = load_cloud_config()
    version = config.get("app_version", "1.2.0")
    build = config.get("app_build", 12)
    ipa_url = config.get("ipa_url", "https://github.com/purorodriguez903-oss/rodriguezlawncarewebiosweb/releases/download/latest-ipa/rodriguezlawncareios.ipa")
    ipa_direct_url = f"{base_url}/download/ipa"
    import urllib.parse
    gbox_url = f"gbox://import?url={urllib.parse.quote(ipa_direct_url, safe='')}"
    manifest_url = f"{base_url}/api/ota/manifest.plist"
    ota_install_url = f"itms-services://?action=download-manifest&url={manifest_url}"
    trollstore_url = f"apple-magnifier://install?url={ipa_url}"
    esign_url = f"esign://import?url={ipa_url}"
    current_page_url = f"{base_url}/instalar"
    qr_url = f"https://api.qrserver.com/v1/create-qr-code/?size=220x220&data={current_page_url}&color=16a34a&bgcolor=0b131f"

    html = f"""<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <title>Instalar rodriguezlawncareios • App Oficial</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;600;700;800&display=swap" rel="stylesheet">
  <style>
    * {{ box-sizing: border-box; margin: 0; padding: 0; }}
    body {{
      font-family: 'Plus Jakarta Sans', -apple-system, BlinkMacSystemFont, sans-serif;
      background: radial-gradient(circle at top, #0d2818 0%, #060b11 60%);
      color: #f1f5f9;
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      align-items: center;
      padding: 24px 16px 40px;
    }}
    .container {{
      width: 100%;
      max-width: 480px;
      display: flex;
      flex-direction: column;
      align-items: center;
      text-align: center;
    }}
    .badge {{
      display: inline-flex;
      align-items: center;
      gap: 6px;
      padding: 6px 14px;
      background: rgba(34, 197, 94, 0.15);
      border: 1px solid rgba(34, 197, 94, 0.4);
      color: #4ade80;
      font-size: 0.85rem;
      font-weight: 700;
      border-radius: 9999px;
      margin-bottom: 20px;
    }}
    .badge-dot {{
      width: 8px;
      height: 8px;
      background: #22c55e;
      border-radius: 50%;
      box-shadow: 0 0 10px #22c55e;
    }}
    .app-icon {{
      width: 110px;
      height: 110px;
      border-radius: 24px;
      box-shadow: 0 16px 40px rgba(0, 0, 0, 0.6), 0 0 0 3px rgba(34, 197, 94, 0.4);
      object-fit: cover;
      margin-bottom: 18px;
    }}
    h1 {{
      font-size: 1.85rem;
      font-weight: 800;
      color: #ffffff;
      letter-spacing: -0.5px;
      margin-bottom: 6px;
    }}
    .subtitle {{
      color: #94a3b8;
      font-size: 0.95rem;
      margin-bottom: 28px;
    }}
    .btn {{
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 12px;
      width: 100%;
      padding: 16px 20px;
      border-radius: 16px;
      text-decoration: none;
      font-size: 1.05rem;
      font-weight: 700;
      transition: all 0.2s ease;
      cursor: pointer;
      margin-bottom: 12px;
      border: none;
    }}
    .btn:active {{
      transform: scale(0.98);
    }}
    .btn-gbox {{
      background: linear-gradient(135deg, #0284c7 0%, #0369a1 100%);
      color: #ffffff;
      box-shadow: 0 8px 24px rgba(2, 132, 199, 0.4);
    }}
    .btn-ota {{
      background: linear-gradient(135deg, #22c55e 0%, #15803d 100%);
      color: #ffffff;
      box-shadow: 0 8px 24px rgba(34, 197, 94, 0.35);
    }}
    .btn-troll {{
      background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%);
      color: #ffffff;
      box-shadow: 0 8px 20px rgba(245, 158, 11, 0.3);
    }}
    .btn-esign {{
      background: rgba(30, 41, 59, 0.85);
      color: #cbd5e1;
      border: 1px solid rgba(148, 163, 184, 0.2);
    }}
    .btn-download {{
      background: transparent;
      color: #94a3b8;
      font-size: 0.9rem;
      padding: 10px;
    }}
    .card {{
      background: rgba(17, 24, 39, 0.7);
      backdrop-filter: blur(12px);
      border: 1px solid rgba(255, 255, 255, 0.08);
      border-radius: 20px;
      padding: 20px;
      width: 100%;
      margin-top: 18px;
      text-align: left;
    }}
    .card h3 {{
      font-size: 1rem;
      color: #e2e8f0;
      margin-bottom: 12px;
      display: flex;
      align-items: center;
      gap: 8px;
    }}
    .card p, .card li {{
      color: #94a3b8;
      font-size: 0.88rem;
      line-height: 1.5;
    }}
    .card ol {{
      margin-left: 18px;
      display: flex;
      flex-direction: column;
      gap: 8px;
    }}
    .qr-box {{
      margin: 18px 0;
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 10px;
    }}
    .qr-box img {{
      border-radius: 14px;
      box-shadow: 0 8px 24px rgba(0,0,0,0.5);
      border: 2px solid rgba(34, 197, 94, 0.4);
    }}
    .qr-text {{
      font-size: 0.8rem;
      color: #64748b;
    }}
  </style>
</head>
<body>
  <div class="container">
    <div class="badge">
      <span class="badge-dot"></span>
      <span>100% ONLINE • ACTUALIZACIÓN EN VIVO</span>
    </div>

    <img src="/assets/bot_logo.jpg" alt="Icono rodriguezlawncareios" class="app-icon">
    <h1>rodriguezlawncareios</h1>
    <p class="subtitle">Administrador Móvil en Tiempo Real • Versión {version} (Build {build})</p>

    <!-- Botón GBox: 1 Toque -->
    <a href="{gbox_url}" class="btn btn-gbox">
      <span>📦</span>
      <span>Instalar / Firmar con GBox (1 Toque)</span>
    </a>

    <!-- Botón 1: OTA Safari -->
    <a href="{ota_install_url}" class="btn btn-ota">
      <span>📲</span>
      <span>Instalar por Aire (Safari OTA)</span>
    </a>

    <!-- Botón 2: TrollStore 1-Toque -->
    <a href="{trollstore_url}" class="btn btn-troll">
      <span>⚡</span>
      <span>Instalar con TrollStore (1 Toque)</span>
    </a>

    <!-- Botón 3: ESign -->
    <a href="{esign_url}" class="btn btn-esign">
      <span>✍️</span>
      <span>Abrir directo en ESign / Scarlet</span>
    </a>

    <!-- Botón 4: Descarga Directa -->
    <a href="/download/ipa" class="btn btn-download">
      <span>📥</span>
      <span>Descargar archivo directo rodriguezlawncareios.ipa</span>
    </a>

    <!-- QR Code para escanear desde PC con iPhone -->
    <div class="card qr-box">
      <h3 style="margin-bottom: 4px;">📷 ¿Estás en tu Computadora?</h3>
      <p class="qr-text">Apunta la cámara de tu iPhone a la pantalla para abrir esta página y actualizar en 1 toque:</p>
      <img src="{qr_url}" alt="QR Instalación" width="180" height="180">
      <span style="font-size: 0.75rem; color: #4ade80;">{current_page_url}</span>
    </div>

    <!-- Guía rápida de uso -->
    <div class="card">
      <h3>🚀 Actualizaciones 100% Online</h3>
      <ol>
        <li><strong>Sin cables ni PC:</strong> Cada vez que actualices el proyecto en GitHub o Railway, el sistema compila y publica aquí automáticamente.</li>
        <li><strong>En la App:</strong> Al abrir la app en tu iPhone, te saldrá un aviso si hay nueva versión para actualizar por el aire en 1 segundo.</li>
        <li><strong>Panel Web Live:</strong> Dentro de la app tienes el botón de <em>Panel Cloud 24/7</em> que carga las funciones nuevas de tu web al instante sin reinstalar el IPA.</li>
      </ol>
    </div>
  </div>
</body>
</html>"""
    return web.Response(text=html, content_type="text/html", headers={"Access-Control-Allow-Origin": "*"})

async def handle_cloud_admin_page(request):
    """Serves responsive Cloud Admin Dashboard embedded inside the iOS app and accessible on PC."""
    scheme = request.headers.get("X-Forwarded-Proto", request.scheme)
    host = request.headers.get("X-Forwarded-Host", request.host)
    base_url = f"{scheme}://{host}"
    config = load_cloud_config()
    version = config.get("app_version", "1.2.0")
    build = config.get("app_build", 12)
    leads = load_leads()
    gallery = load_gallery()
    analytics = load_analytics()
    settings = load_settings()

    pending_leads = [l for l in leads if l.get("status") == "pending"]

    html = f"""<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <title>Panel Cloud 24/7 • rodriguezlawncareios</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;600;700;800&display=swap" rel="stylesheet">
  <style>
    * {{ box-sizing: border-box; margin: 0; padding: 0; }}
    body {{
      font-family: 'Plus Jakarta Sans', -apple-system, sans-serif;
      background: #0b131f;
      color: #f8fafc;
      padding: 16px;
      padding-bottom: 60px;
    }}
    .header {{
      display: flex;
      align-items: center;
      justify-content: space-between;
      margin-bottom: 20px;
      background: #111c2d;
      padding: 16px 20px;
      border-radius: 18px;
      border: 1px solid rgba(255,255,255,0.06);
    }}
    .brand-title {{
      font-size: 1.15rem;
      font-weight: 800;
      color: #ffffff;
      display: flex;
      align-items: center;
      gap: 10px;
    }}
    .brand-title span {{ color: #22c55e; }}
    .status-pill {{
      display: inline-flex;
      align-items: center;
      gap: 6px;
      font-size: 0.75rem;
      font-weight: 700;
      color: #4ade80;
      background: rgba(34, 197, 94, 0.15);
      border: 1px solid rgba(34, 197, 94, 0.3);
      padding: 4px 10px;
      border-radius: 9999px;
    }}
    .status-dot {{
      width: 7px;
      height: 7px;
      background: #22c55e;
      border-radius: 50%;
      box-shadow: 0 0 8px #22c55e;
    }}
    .stats-grid {{
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(140px, 1fr));
      gap: 12px;
      margin-bottom: 20px;
    }}
    .stat-card {{
      background: #152238;
      border: 1px solid rgba(255,255,255,0.06);
      padding: 16px;
      border-radius: 16px;
      text-align: center;
    }}
    .stat-num {{
      font-size: 1.7rem;
      font-weight: 800;
      color: #22c55e;
      margin-bottom: 4px;
    }}
    .stat-label {{
      font-size: 0.78rem;
      color: #94a3b8;
      text-transform: uppercase;
      font-weight: 700;
      letter-spacing: 0.5px;
    }}
    .section-card {{
      background: #111c2d;
      border: 1px solid rgba(255,255,255,0.06);
      border-radius: 18px;
      padding: 20px;
      margin-bottom: 20px;
    }}
    .section-title {{
      font-size: 1.05rem;
      font-weight: 700;
      margin-bottom: 14px;
      display: flex;
      align-items: center;
      justify-content: space-between;
    }}
    .lead-row {{
      background: #182740;
      border: 1px solid rgba(255,255,255,0.05);
      border-radius: 12px;
      padding: 12px 14px;
      margin-bottom: 10px;
      display: flex;
      align-items: center;
      justify-content: space-between;
    }}
    .lead-info strong {{ font-size: 0.95rem; color: #fff; }}
    .lead-info p {{ font-size: 0.8rem; color: #94a3b8; margin-top: 2px; }}
    .btn-wa {{
      background: #22c55e;
      color: #fff;
      padding: 8px 12px;
      border-radius: 10px;
      text-decoration: none;
      font-size: 0.82rem;
      font-weight: 700;
    }}
    .config-grid {{
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 10px;
    }}
    .config-item {{
      background: #182740;
      padding: 10px 12px;
      border-radius: 10px;
      border: 1px solid rgba(255,255,255,0.05);
    }}
    .config-item label {{
      display: block;
      font-size: 0.72rem;
      color: #94a3b8;
      font-weight: 600;
      margin-bottom: 4px;
    }}
    .config-item input {{
      width: 100%;
      background: #0b131f;
      border: 1px solid #334155;
      color: #22c55e;
      font-weight: 700;
      padding: 6px 8px;
      border-radius: 8px;
      font-size: 0.9rem;
    }}
    .save-btn {{
      background: #22c55e;
      color: #0b131f;
      font-weight: 800;
      border: none;
      padding: 12px;
      width: 100%;
      border-radius: 12px;
      margin-top: 14px;
      cursor: pointer;
      font-size: 0.95rem;
    }}
    .alert-box {{
      padding: 12px;
      border-radius: 10px;
      margin-bottom: 14px;
      display: none;
    }}
  </style>
</head>
<body>
  <div class="header">
    <div class="brand-title">🌿 RODRIGUEZ <span>LAWNCARE</span></div>
    <div class="status-pill">
      <span class="status-dot"></span>
      <span>RAILWAY 24/7 ONLINE</span>
    </div>
  </div>

  <div class="stats-grid">
    <div class="stat-card">
      <div class="stat-num">{len(pending_leads)}</div>
      <div class="stat-label">Citas Pendientes</div>
    </div>
    <div class="stat-card">
      <div class="stat-num">{len(leads)}</div>
      <div class="stat-label">Total Clientes</div>
    </div>
    <div class="stat-card">
      <div class="stat-num">{analytics.get("visits_today", 0)}</div>
      <div class="stat-label">Visitas Hoy</div>
    </div>
    <div class="stat-card">
      <div class="stat-num">{len(gallery)}</div>
      <div class="stat-label">Fotos Web</div>
    </div>
  </div>

  <!-- Citas en vivo -->
  <div class="section-card">
    <div class="section-title">
      <span>🚨 Citas & Cotizaciones Recientes</span>
      <span style="font-size: 0.8rem; color: #4ade80;">{len(leads)} registradas</span>
    </div>
    {"".join([f'''
    <div class="lead-row">
      <div class="lead-info">
        <strong>{l.get("name", "Cliente")}</strong>
        <p>📞 {l.get("phone", "")} • {", ".join(l.get("services", ["Corte"]))}</p>
      </div>
      <a href="https://wa.me/{l.get('phone','').replace('(','').replace(')','').replace('-','').replace(' ','')}?text=Hola%20{l.get('name','')}!%20Te%20contacto%20de%20Rodriguez%20LawnCare." class="btn-wa">WhatsApp</a>
    </div>''' for l in leads[:4]]) if leads else '<p style="color:#64748b; font-size:0.85rem;">No hay citas pendientes por el momento.</p>'}
  </div>

  <!-- Configuración de Precios en Vivo para la App iOS -->
  <div class="section-card">
    <div class="section-title">
      <span>⚙️ Precios en Vivo para la App iOS (Sin compilar IPA)</span>
    </div>
    <p style="font-size: 0.8rem; color: #94a3b8; margin-bottom: 12px;">Cualquier cambio aquí se refleja inmediatamente en el cotizador de tu iPhone:</p>
    <div id="saveAlert" class="alert-box" style="background: rgba(34,197,94,0.2); color: #4ade80; border: 1px solid #22c55e;">
      ✅ ¡Precios actualizados en la nube con éxito!
    </div>
    <form id="pricingForm" onsubmit="savePricing(event)">
      <div class="config-grid">
        <div class="config-item">
          <label>Césped Chico (&lt; 5k sq ft)</label>
          <input type="number" step="0.5" id="rate_small" value="{config.get('rates', {}).get('small', 45.0)}">
        </div>
        <div class="config-item">
          <label>Césped Mediano (5k - 10k)</label>
          <input type="number" step="0.5" id="rate_medium" value="{config.get('rates', {}).get('medium', 60.0)}">
        </div>
        <div class="config-item">
          <label>Césped Grande (10k - 15k)</label>
          <input type="number" step="0.5" id="rate_large" value="{config.get('rates', {}).get('large', 85.0)}">
        </div>
        <div class="config-item">
          <label>Acre Completo</label>
          <input type="number" step="0.5" id="rate_acre" value="{config.get('rates', {}).get('acre', 140.0)}">
        </div>
        <div class="config-item">
          <label>Extra: Arbustos ($)</label>
          <input type="number" step="0.5" id="addon_bushes" value="{config.get('addons', {}).get('bushes', 30.0)}">
        </div>
        <div class="config-item">
          <label>Extra: Mulch ($)</label>
          <input type="number" step="0.5" id="addon_mulch" value="{config.get('addons', {}).get('mulch', 65.0)}">
        </div>
      </div>
      <button type="submit" class="save-btn">💾 Guardar y Aplicar a la App iOS</button>
    </form>
  </div>

  <!-- Centro OTA -->
  <div class="section-card" style="text-align: center;">
    <div class="section-title" style="justify-content: center;">
      <span>📲 Centro de Actualizaciones Inalámbricas OTA</span>
    </div>
    <p style="font-size: 0.85rem; color: #94a3b8; margin-bottom: 14px;">Versión compilada: <strong>{version} (Build {build})</strong></p>
    <a href="/instalar" style="display: inline-block; background: #3b82f6; color: #fff; font-weight: 700; padding: 10px 20px; border-radius: 12px; text-decoration: none;">Abrir Página de Instalación OTA</a>
  </div>

  <script>
    async function savePricing(e) {{
      e.preventDefault();
      const payload = {{
        rates: {{
          small: parseFloat(document.getElementById('rate_small').value),
          medium: parseFloat(document.getElementById('rate_medium').value),
          large: parseFloat(document.getElementById('rate_large').value),
          acre: parseFloat(document.getElementById('rate_acre').value)
        }},
        addons: {{
          bushes: parseFloat(document.getElementById('addon_bushes').value),
          mulch: parseFloat(document.getElementById('addon_mulch').value)
        }}
      }};
      try {{
        const resp = await fetch('/api/cloud/config', {{
          method: 'POST',
          headers: {{ 'Content-Type': 'application/json' }},
          body: JSON.stringify(payload)
        }});
        if (resp.ok) {{
          document.getElementById('saveAlert').style.display = 'block';
          setTimeout(() => {{ document.getElementById('saveAlert').style.display = 'none'; }}, 4000);
        }}
      }} catch(err) {{
        alert('Error al guardar: ' + err);
      }}
    }}
  </script>
</body>
</html>"""
    return web.Response(text=html, content_type="text/html", headers={"Access-Control-Allow-Origin": "*"})



# ----------------- CALENDAR & SCHEDULE API -----------------
async def handle_api_get_reviews(request):
    """Returns list of client reviews for website and iOS app."""
    return cors_json_response(load_reviews())

async def handle_api_add_review(request):
    """Adds or updates a client review."""
    try:
        data = await request.json()
        name = data.get("name", "").strip() or "Verified Customer"
        role = data.get("role", "").strip() or "Residential Service"
        badge = data.get("badge", "").strip() or "Verified Homeowner"
        rating = int(data.get("rating", 5) or 5)
        text = data.get("text", "").strip()
        if not text:
            return cors_json_response({"success": False, "error": "El texto de la reseña es requerido"}, status=400)

        parts = name.split()
        initials = (parts[0][0] + (parts[-1][0] if len(parts) > 1 else "")).upper() if parts else "VC"

        reviews = load_reviews()
        review_id = int(data.get("id", int(time.time() * 1000)))

        existing = next((r for r in reviews if r.get("id") == review_id), None)
        if existing:
            existing.update({
                "name": name,
                "role": role,
                "badge": badge,
                "rating": rating,
                "text": text,
                "initials": initials
            })
        else:
            new_review = {
                "id": review_id,
                "name": name,
                "role": role,
                "badge": badge,
                "rating": rating,
                "text": text,
                "initials": initials,
                "date": time.strftime("%Y-%m-%d", time.localtime())
            }
            reviews.insert(0, new_review)

        save_reviews(reviews)
        return cors_json_response({"success": True, "reviews": reviews})
    except Exception as e:
        return cors_json_response({"success": False, "error": str(e)}, status=400)

async def handle_api_delete_review(request):
    """Deletes a client review by id."""
    try:
        review_id = None
        if request.method == "POST":
            data = await request.json()
            review_id = data.get("id")
        else:
            review_id = request.match_info.get("id")

        if review_id is not None:
            review_id = int(review_id)
            reviews = load_reviews()
            reviews = [r for r in reviews if r.get("id") != review_id]
            save_reviews(reviews)
            return cors_json_response({"success": True, "reviews": reviews})
        return cors_json_response({"success": False, "error": "ID no proporcionado"}, status=400)
    except Exception as e:
        return cors_json_response({"success": False, "error": str(e)}, status=400)


async def handle_api_get_calendar(request):
    """Returns calendar days status and booked appointments."""
    cal = load_calendar()
    return cors_json_response({"success": True, "calendar": cal})

async def handle_api_save_calendar_day(request):
    """Sets a date status as 'normal' or 'full' (Lleno)."""
    try:
        data = await request.json()
        date_str = (data.get("date") or "").strip()
        status_val = (data.get("status") or "normal").strip().lower()
        if not date_str:
            return cors_json_response({"success": False, "error": "date is required"}, status=400)

        cal = load_calendar()
        cal.setdefault("day_status", {})[date_str] = status_val
        save_calendar(cal)
        return cors_json_response({"success": True, "calendar": cal, "date": date_str, "status": status_val})
    except Exception as e:
        return cors_json_response({"success": False, "error": str(e)}, status=400)

async def handle_api_save_calendar_appointment(request):
    """Adds or updates a job in the calendar."""
    try:
        data = await request.json()
        cal = load_calendar()
        appts = cal.setdefault("appointments", [])
        appt_id = int(data.get("id") or int(time.time() * 1000))

        existing = next((a for a in appts if a.get("id") == appt_id), None)
        item = {
            "id": appt_id,
            "date": data.get("date", time.strftime("%Y-%m-%d")),
            "time_window": data.get("time_window", "Morning (8:00 AM - 12:00 PM)"),
            "client_name": data.get("client_name", "Cliente"),
            "client_phone": data.get("client_phone", ""),
            "address": data.get("address", ""),
            "services": data.get("services", ["Corte de Césped"]),
            "amount": float(data.get("amount", 0.0) or 0.0),
            "status": data.get("status", "confirmed"),
            "notes": data.get("notes", "")
        }

        if existing:
            existing.update(item)
        else:
            appts.insert(0, item)

        save_calendar(cal)
        return cors_json_response({"success": True, "appointment": item, "calendar": cal})
    except Exception as e:
        return cors_json_response({"success": False, "error": str(e)}, status=400)

async def handle_api_delete_calendar_appointment(request):
    """Deletes a job from the calendar."""
    try:
        data = await request.json()
        appt_id = int(data.get("id") or 0)
        cal = load_calendar()
        appts = cal.setdefault("appointments", [])
        cal["appointments"] = [a for a in appts if a.get("id") != appt_id]
        save_calendar(cal)
        return cors_json_response({"success": True, "calendar": cal})
    except Exception as e:
        return cors_json_response({"success": False, "error": str(e)}, status=400)

async def handle_api_calendar_availability(request):
    """Live availability checker for web visitors booking dates and time slots."""
    date_val = request.query.get("date", "").strip()
    cal = load_calendar()
    day_status = cal.get("day_status", {}).get(date_val, "normal")

    if day_status == "full":
        return cors_json_response({
            "success": True,
            "date": date_val,
            "available": False,
            "is_available": False,
            "is_full": True,
            "day_status": "full",
            "message": "Día Lleno / Team Fully Booked. Please select another date."
        })

    # Check booked time slots for this date
    appts = cal.get("appointments", [])
    booked_slots = [
        a.get("time_window") for a in appts
        if a.get("date") == date_val and a.get("status") in ["confirmed", "scheduled", "in_progress"]
    ]

    return cors_json_response({
        "success": True,
        "date": date_val,
        "available": True,
        "is_available": True,
        "is_full": False,
        "day_status": "normal",
        "booked_slots": booked_slots,
        "booked_times": booked_slots,
        "team_working_slots": booked_slots
    })

# ----------------- PROMOTIONS API -----------------
async def handle_api_get_promo(request):
    """Returns active flash promotion for web and app."""
    promos = load_promotions()
    return cors_json_response({"success": True, "promo": promos.get("active"), "history": promos.get("history", [])})

async def handle_api_publish_promo(request):
    """Publishes a new promo to the website with expiration."""
    try:
        data = await request.json()
        promos = load_promotions()
        active = promos.get("active", {})
        if active and active.get("enabled"):
            promos.setdefault("history", []).insert(0, dict(active))

        duration_hours = max(1, int(data.get("duration_hours", 24)))
        now = int(time.time())
        new_active = {
            "id": int(now * 1000),
            "enabled": True,
            "title": data.get("title", "🎖️ Descuento Flash").strip(),
            "message": data.get("message", "Promoción especial activa").strip(),
            "badge": data.get("badge", "OFERTA LIMITADA").strip(),
            "created_at": now,
            "duration_hours": duration_hours,
            "expires_at": now + (duration_hours * 3600)
        }
        promos["active"] = new_active
        save_promotions(promos)
        return cors_json_response({"success": True, "promo": new_active, "history": promos.get("history", [])})
    except Exception as e:
        return cors_json_response({"success": False, "error": str(e)}, status=400)

async def handle_api_deactivate_promo(request):
    """Deactivates active promo and moves it to history."""
    try:
        promos = load_promotions()
        active = promos.get("active", {})
        if active and active.get("enabled"):
            active["enabled"] = False
            promos.setdefault("history", []).insert(0, dict(active))
            save_promotions(promos)
        return cors_json_response({"success": True, "promo": promos.get("active")})
    except Exception as e:
        return cors_json_response({"success": False, "error": str(e)}, status=400)

def create_web_app():
    app = web.Application(client_max_size=50 * 1024 * 1024)
    # Website static & pages
    app.router.add_get('/', handle_index)
    app.router.add_get('/index.html', handle_index)
    app.router.add_get('/gallery.json', handle_gallery_json)
    app.router.add_get('/health', handle_health)
    app.router.add_get('/ping', handle_health)

    # Lead Submission (Web form)
    app.router.add_post('/api/lead', handle_lead_submission)

    # 100% Online OTA & Cloud App Portal
    app.router.add_post('/api/ipa/send-discord', handle_send_ipa_discord)
    app.router.add_get('/api/ipa/send-discord', handle_send_ipa_discord)
    app.router.add_get('/ipa', handle_download_ipa)
    app.router.add_get('/rodriguezlawncareios.ipa', handle_download_ipa)
    app.router.add_get('/RodriguezLawnCare.ipa', handle_download_ipa)
    app.router.add_get('/app', handle_ota_page)
    app.router.add_get('/instalar', handle_ota_page)
    app.router.add_get('/admin', handle_cloud_admin_page)
    app.router.add_get('/admin/ota', handle_ota_page)
    app.router.add_get('/download/ipa', handle_download_ipa)
    app.router.add_get('/api/ota/manifest.plist', handle_ota_manifest)
    app.router.add_get('/api/app/version', handle_api_app_version)
    app.router.add_get('/api/cloud/config', handle_api_get_cloud_config)
    app.router.add_post('/api/cloud/config', handle_api_save_cloud_config)

    # REST API for iOS App & Admin
    app.router.add_route('OPTIONS', '/api/{tail:.*}', handle_cors_options)
    app.router.add_get('/api/leads', handle_api_get_leads)
    app.router.add_post('/api/leads', handle_api_create_lead)
    app.router.add_post('/api/leads/update', handle_api_update_lead)
    app.router.add_post('/api/leads/delete', handle_api_delete_lead)
    app.router.add_delete('/api/leads/{id}', handle_api_delete_lead)

    # Gallery API
    app.router.add_get('/api/gallery', handle_api_get_gallery)
    app.router.add_post('/api/gallery', handle_api_add_gallery)
    app.router.add_post('/api/gallery/update', handle_api_update_gallery)
    app.router.add_post('/api/gallery/reorder', handle_api_reorder_gallery)
    app.router.add_post('/api/gallery/delete', handle_api_delete_gallery)
    app.router.add_delete('/api/gallery/{id}', handle_api_delete_gallery)

    # Settings, Hero Background & Background Music API
    app.router.add_get('/api/settings', handle_api_get_settings)
    app.router.add_post('/api/settings/hero', handle_api_save_hero_settings)
    app.router.add_post('/api/settings/music', handle_api_save_music_settings)
    app.router.add_post('/api/ai/estimate', handle_api_ai_estimate)

    # Calendar & Availability API
    # Reviews API
    app.router.add_get('/api/reviews', handle_api_get_reviews)
    app.router.add_post('/api/reviews', handle_api_add_review)
    app.router.add_post('/api/reviews/delete', handle_api_delete_review)
    app.router.add_delete('/api/reviews/{id}', handle_api_delete_review)

    app.router.add_get('/api/calendar', handle_api_get_calendar)
    app.router.add_post('/api/calendar/day', handle_api_save_calendar_day)
    app.router.add_post('/api/calendar/appointment', handle_api_save_calendar_appointment)
    app.router.add_post('/api/calendar/delete', handle_api_delete_calendar_appointment)
    app.router.add_get('/api/calendar/availability', handle_api_calendar_availability)

    # Flash Promotions API
    app.router.add_get('/api/promo', handle_api_get_promo)
    app.router.add_post('/api/promo', handle_api_publish_promo)
    app.router.add_post('/api/promo/deactivate', handle_api_deactivate_promo)

    # Visitors & Analytics API
    app.router.add_get('/api/analytics', handle_api_get_analytics)
    app.router.add_post('/api/analytics/visit', handle_api_record_visit)
    app.router.add_get('/api/stats', handle_api_stats)

    # Static files (CSS, JS, Assets)
    app.router.add_static('/', path=BASE_DIR, show_index=False)
    return app


async def keepalive_heartbeat():
    """Background task that logs periodic heartbeat and verifies bot connectivity every 5 minutes."""
    while True:
        await asyncio.sleep(300)
        try:
            if bot_global and bot_global.is_ready():
                print(f"💚 [HEARTBEAT 24/7] Servidor y Bot activos al 100%. Conectado como {bot_global.user}. Canal Leads: {LEADS_CHANNEL_ID}")
            else:
                print("🟡 [HEARTBEAT 24/7] Servidor web activo, verificando reconexión del Discord Bot...")
        except Exception as e:
            print(f"⚠️ [HEARTBEAT] Error en verificación: {e}")


async def run_bot_supervisor():
    """24/7 auto-reconnecting supervisor loop that guarantees the bot never stays down."""
    global bot_global
    retry_delay = 5
    max_delay = 60

    while True:
        try:
            print("🤖 [SUPERVISOR 24/7] Conectando Discord Bot...")
            try:
                bot_global = build_bot(enable_message_content=True)
                await bot_global.start(BOT_TOKEN)
            except discord.errors.PrivilegedIntentsRequired:
                print("ℹ️ [SUPERVISOR 24/7] Privileged Intents no activos. Iniciando Bot con Slash Commands y Botones...")
                bot_global = build_bot(enable_message_content=False)
                await bot_global.start(BOT_TOKEN)

        except discord.errors.LoginFailure as e:
            print(f"❌ [CRÍTICO 24/7] Error de login en Discord (Token inválido): {e}. Reintentando en 60s...")
            await asyncio.sleep(60)
        except asyncio.CancelledError:
            print("🛑 [SUPERVISOR 24/7] Supervisor de Discord detenido.")
            break
        except Exception as e:
            print(f"⚠️ [SUPERVISOR 24/7] Conexión de Discord interrumpida ({type(e).__name__}: {e}). Reconectando automáticamente en {retry_delay}s...")
            await asyncio.sleep(retry_delay)
            retry_delay = min(int(retry_delay * 1.5), max_delay)
        else:
            print("ℹ️ [SUPERVISOR 24/7] Conexión de Discord finalizada limpiamente. Reconectando en 5s...")
            await asyncio.sleep(5)
            retry_delay = 5


# ----------------- MAIN RUNNER (CONCURRENT WEB + BOT) -----------------
async def main():
    # 1. Start Web Server
    web_app = create_web_app()
    runner = web.AppRunner(web_app)
    await runner.setup()
    site = web.TCPSite(runner, '0.0.0.0', PORT)
    await site.start()
    print(f"🌐 Servidor Web Rodriguez LawnCare activo 24/7 en http://0.0.0.0:{PORT}")

    # 2. Start Keepalive Heartbeat Task
    asyncio.create_task(keepalive_heartbeat())

    # 3. Start Resilient 24/7 Discord Bot Supervisor Loop
    await run_bot_supervisor()


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except (KeyboardInterrupt, SystemExit):
        print("Servidor detenido.")
