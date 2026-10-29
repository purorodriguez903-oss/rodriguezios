/**
 * RODRIGUEZ LAWN CARE - 24/7 AI SMART ASSISTANT WIDGET
 * Provides instant answers for Lawn Care pricing, service areas (Killeen, Fort Cavazos, Harker Heights, Temple, Copperas Cove),
 * official Zelle & Cash App payment details, and 1-tap quote booking.
 */

(function () {
  'use strict';

  let currentLang = 'es'; // default Spanish or detect from navigator

  if (navigator.language && navigator.language.startsWith('en')) {
    currentLang = 'en';
  }

  const KNOWLEDGE_BASE = {
    es: {
      welcome: "👋 ¡Hola! Soy el **Asistente Virtual de Rodriguez Lawn Care**. ¿En qué puedo ayudarte hoy? Puedes preguntarme precios de corte, mulch, zonas de servicio o métodos de pago (Zelle / Cash App).",
      pricing: "🌱 **Nuestros Precios Estimados:**\n• **Corte Residencial Estándar (Frente y Atrás):** Desde **$45 - $65** (incluye corte de pasto, orillado razor-sharp y soplado de banquetas).\n• **Patios Grandes / Esquinas:** **$65 - $85**.\n• **Instalación de Mulch:** **$85 - $115** por yarda cúbica instalada.\n• **Poda de Arbustos / Setos:** Desde **$45** según cantidad y altura.\n• **Tala de Árboles y Limpieza:** Cotización personalizada gratuita.\n\n¿Quieres que te agendemos un estimado 100% gratis a tu domicilio?",
      payment: "💳 **Métodos de Pago Oficiales de Rodriguez Lawn Care:**\n\n• **ZELLE:**\n  👤 Nombre: **Olivia Rodriguez**\n  📱 Número: **(623) 764-4177**\n\n• **CASH APP:**\n  💲 Cashtag: **$rafajrii**\n  🔗 Link: [cash.app/$rafajrii](https://cash.app/$rafajrii)\n\n• También aceptamos: Efectivo y Tarjetas de Débito/Crédito.\n\n*Nota: Siempre incluye tu dirección o nombre en la nota de pago para tu recibo.*",
      coverage: "📍 **Áreas y Ciudades de Cobertura en Texas:**\nAtendemos todo el condado de Bell y alrededores:\n• **Killeen, TX**\n• **Fort Cavazos (Base Militar)**\n• **Harker Heights, TX**\n• **Copperas Cove, TX**\n• **Temple, TX**\n• **Belton, TX**\n• **Nolanville, TX**\n\n¿En qué ciudad o código postal se encuentra tu propiedad?",
      schedule: "📅 **¡Excelente! Para agendar tu estimado gratis:**\nPuedes llenar el formulario de arriba en esta página, llamarnos directo al **(254) 612-1399** o mandarnos un mensaje rápido por WhatsApp al mismo número.",
      contact: "📞 **Contacto Directo:**\n• Teléfono / WhatsApp: **(254) 612-1399**\n• Horario: Lunes a Sábado 7:00 AM - 7:00 PM\n• Base: Killeen, TX",
      fallback: "Entendido. Para darte el mejor precio exacto y atención personalizada, te recomiendo llamarnos o escribirnos al **(254) 612-1399** o hacer clic en 'Agendar Estimado Gratis'. ¿Deseas que te comunique por WhatsApp?",
      pills: [
        { label: "💵 ¿Cuánto cobran?", query: "precios" },
        { label: "💳 Métodos de Pago (Zelle/Cash App)", query: "pagos" },
        { label: "📍 ¿Cubren mi ciudad?", query: "ciudades" },
        { label: "📅 Agendar Estimado Gratis", query: "agendar" },
        { label: "🪵 Mulch y Arbustos", query: "mulch" }
      ]
    },
    en: {
      welcome: "👋 Hi there! I'm the **Rodriguez Lawn Care AI Assistant**. How can I help you today? Ask me about mowing prices, mulch, service areas, or payment methods (Zelle / Cash App)!",
      pricing: "🌱 **Estimated Pricing:**\n• **Standard Residential Cut (Front & Back):** Starting at **$45 - $65** (includes mowing, razor-sharp sidewalk edging, and clean blow-off).\n• **Large / Corner Lots:** **$65 - $85**.\n• **Mulch Installation:** **$85 - $115** per cubic yard installed.\n• **Shrub & Hedge Trimming:** Starting at **$45** depending on size.\n• **Tree Trimming & Cleanups:** Free custom on-site quote.\n\nWould you like a 100% free estimate at your home?",
      payment: "💳 **Official Payment Methods:**\n\n• **ZELLE:**\n  👤 Name: **Olivia Rodriguez**\n  📱 Phone: **(623) 764-4177**\n\n• **CASH APP:**\n  💲 Cashtag: **$rafajrii**\n  🔗 Link: [cash.app/$rafajrii](https://cash.app/$rafajrii)\n\n• We also accept: Cash and all major Debit/Credit Cards.\n\n*Note: Please include your address or name in the payment memo.*",
      coverage: "📍 **Service Areas in Central Texas:**\nWe proudly service all of Bell County and nearby communities:\n• **Killeen, TX**\n• **Fort Cavazos (Military Base)**\n• **Harker Heights, TX**\n• **Copperas Cove, TX**\n• **Temple, TX**\n• **Belton, TX**\n• **Nolanville, TX**\n\nWhich city or ZIP code is your lawn located in?",
      schedule: "📅 **Awesome! To schedule your free estimate:**\nYou can fill out the fast quote form on this page, call us directly at **(254) 612-1399**, or send us a quick WhatsApp text.",
      contact: "📞 **Direct Contact Info:**\n• Phone / WhatsApp: **(254) 612-1399**\n• Hours: Monday - Saturday 7:00 AM - 7:00 PM\n• Location: Killeen, TX",
      fallback: "Got it! For the most accurate pricing tailored to your yard, you can call or text us anytime at **(254) 612-1399** or tap 'Book Free Estimate'. Would you like to connect via WhatsApp?",
      pills: [
        { label: "💵 Pricing Estimates", query: "precios" },
        { label: "💳 Payment Methods (Zelle/CashApp)", query: "pagos" },
        { label: "📍 Do you cover my city?", query: "ciudades" },
        { label: "📅 Book Free Estimate", query: "agendar" },
        { label: "🪵 Mulch & Shrub Trimming", query: "mulch" }
      ]
    }
  };

  document.addEventListener('DOMContentLoaded', () => {
    initAiWidget();
  });

  function initAiWidget() {
    const toggleBtn = document.getElementById('aiWidgetToggleBtn');
    const chatWindow = document.getElementById('aiChatWindow');
    const closeBtn = document.getElementById('aiChatClose');
    const langBtn = document.getElementById('aiLangToggle');
    const chatForm = document.getElementById('aiChatForm');
    const userInput = document.getElementById('aiUserInput');
    const messagesContainer = document.getElementById('aiChatMessages');
    const pillsContainer = document.getElementById('aiQuickPills');

    if (!toggleBtn || !chatWindow) return;

    // Toggle open/close
    toggleBtn.addEventListener('click', () => {
      const isVisible = chatWindow.style.display !== 'none';
      if (isVisible) {
        chatWindow.style.display = 'none';
      } else {
        chatWindow.style.display = 'flex';
        if (messagesContainer.children.length === 0) {
          appendAiMessage(KNOWLEDGE_BASE[currentLang].welcome);
          renderPills();
        }
        setTimeout(() => userInput.focus(), 200);
      }
    });

    closeBtn?.addEventListener('click', () => {
      chatWindow.style.display = 'none';
    });

    // Language Toggle
    langBtn?.addEventListener('click', () => {
      currentLang = currentLang === 'es' ? 'en' : 'es';
      langBtn.textContent = currentLang === 'es' ? '🌐 ES' : '🌐 EN';
      appendAiMessage(currentLang === 'es' ? '🌐 Idioma cambiado a **Español**.' : '🌐 Language switched to **English**.');
      renderPills();
    });

    // Handle Quick Pills
    function renderPills() {
      if (!pillsContainer) return;
      pillsContainer.innerHTML = '';
      KNOWLEDGE_BASE[currentLang].pills.forEach(pill => {
        const btn = document.createElement('button');
        btn.className = 'ai-pill';
        btn.textContent = pill.label;
        btn.type = 'button';
        btn.addEventListener('click', () => {
          handleUserQuery(pill.query, pill.label);
        });
        pillsContainer.appendChild(btn);
      });
    }

    // Submit form
    chatForm?.addEventListener('submit', (e) => {
      e.preventDefault();
      const text = userInput.value.trim();
      if (!text) return;
      userInput.value = '';
      handleUserQuery(text, text);
    });

    function handleUserQuery(queryKey, displayLabel) {
      appendUserMessage(displayLabel);
      showTypingIndicator();

      setTimeout(() => {
        removeTypingIndicator();
        const reply = generateAiReply(queryKey);
        appendAiMessage(reply);
      }, 450);
    }

    function generateAiReply(query) {
      const q = query.toLowerCase();
      const kb = KNOWLEDGE_BASE[currentLang];

      if (q.includes('precio') || q.includes('price') || q.includes('cost') || q.includes('cuanto') || q.includes('how much') || q.includes('rate') || q.includes('cut')) {
        return kb.pricing;
      }
      if (q.includes('pago') || q.includes('pay') || q.includes('zelle') || q.includes('cash app') || q.includes('cashapp') || q.includes('card') || q.includes('tarjeta') || q.includes('money')) {
        return kb.payment;
      }
      if (q.includes('ciudad') || q.includes('area') || q.includes('killeen') || q.includes('hood') || q.includes('cavazos') || q.includes('temple') || q.includes('cove') || q.includes('heights') || q.includes('donde') || q.includes('where')) {
        return kb.coverage;
      }
      if (q.includes('agendar') || q.includes('book') || q.includes('cita') || q.includes('estimate') || q.includes('cotiz') || q.includes('free') || q.includes('schedule')) {
        return kb.schedule;
      }
      if (q.includes('mulch') || q.includes('arbusto') || q.includes('shrub') || q.includes('hedge') || q.includes('tree') || q.includes('arbol')) {
        return kb.pricing;
      }
      if (q.includes('hola') || q.includes('hello') || q.includes('hi') || q.includes('buenos')) {
        return kb.welcome;
      }
      if (q.includes('telefono') || q.includes('phone') || q.includes('call') || q.includes('llamar') || q.includes('numero')) {
        return kb.contact;
      }
      return kb.fallback;
    }

    function appendUserMessage(text) {
      const msg = document.createElement('div');
      msg.className = 'ai-msg ai-msg-user';
      msg.textContent = text;
      messagesContainer.appendChild(msg);
      messagesContainer.scrollTop = messagesContainer.scrollHeight;
    }

    function appendAiMessage(markdownText) {
      const msg = document.createElement('div');
      msg.className = 'ai-msg ai-msg-bot';
      msg.innerHTML = formatMarkdown(markdownText);

      // Append quick action buttons inside bot message if relevant
      if (markdownText.includes('ZELLE') || markdownText.includes('Precios') || markdownText.includes('Pricing')) {
        const actionRow = document.createElement('div');
        actionRow.className = 'ai-msg-actions';
        actionRow.innerHTML = `
          <a href="tel:2546121399" class="ai-act-btn ai-call-btn">📞 Llamar (254) 612-1399</a>
          <a href="https://wa.me/12546121399?text=Hola%20Rodriguez%20Lawn%20Care,%20me%20gustaria%20una%20cotizacion" target="_blank" class="ai-act-btn ai-wa-btn">💬 WhatsApp</a>
        `;
        msg.appendChild(actionRow);
      }

      messagesContainer.appendChild(msg);
      messagesContainer.scrollTop = messagesContainer.scrollHeight;
    }

    function showTypingIndicator() {
      const typing = document.createElement('div');
      typing.id = 'aiTypingIndicator';
      typing.className = 'ai-msg ai-msg-bot ai-typing';
      typing.innerHTML = '<span class="dot"></span><span class="dot"></span><span class="dot"></span>';
      messagesContainer.appendChild(typing);
      messagesContainer.scrollTop = messagesContainer.scrollHeight;
    }

    function removeTypingIndicator() {
      const typing = document.getElementById('aiTypingIndicator');
      if (typing) typing.remove();
    }

    function formatMarkdown(text) {
      return text
        .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
        .replace(/\*(.*?)\*/g, '<em>$1</em>')
        .replace(/\[(.*?)\]\((.*?)\)/g, '<a href="$2" target="_blank" rel="noopener">$1</a>')
        .replace(/\n/g, '<br>');
    }
  }

})();
