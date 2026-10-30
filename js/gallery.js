/**
 * RODRIGUEZ LAWNCARE - DYNAMIC LIVE WORK GALLERY
 * Loads real-time photos managed via the Discord Bot & iOS App.
 * Highlights new photos with a glowing "🔥 NEW" badge for 3 days (72 hours),
 * Displays category badges (🏡 Front Yard, 🌿 Back Yard, 🪵 Mulch, 🌳 Tree Care, etc.),
 * Supports dual filtering: by Category AND by City (Killeen, Fort Cavazos, Harker Heights, Temple, Copperas Cove),
 * and allows instant fullscreen viewing.
 */

(function () {
  'use strict';

  const THREE_DAYS_MS = 3 * 24 * 60 * 60 * 1000;

  // Category Icon Map
  const CATEGORY_ICONS = {
    'Front Yard': '🏡',
    'Back Yard': '🌿',
    'Mulch': '🪵',
    'Tree Care': '🌳',
    'Shrubs & Bushes': '✂️',
    'Cleanups': '🧹',
    'Mowing & Edging': '📐',
    'General LawnCare': '🌱'
  };

  // Fallback items in case gallery.json is accessed via local file:// protocol
  const fallbackGallery = [
    {
      id: 8,
      filename: "work_8.jpg",
      url: "./assets/gallery/work_8.jpg",
      uploaded_at: Date.now() - (1000 * 60 * 60 * 4),
      title: "Builder Duplex Mowing & Razor Edging",
      category: "General LawnCare",
      location: "Killeen, TX",
      city: "Killeen"
    },
    {
      id: 7,
      filename: "work_7.jpg",
      url: "./assets/gallery/work_7.jpg",
      uploaded_at: Date.now() - (1000 * 60 * 60 * 12),
      title: "Front Yard Clean & Sharp Mowing",
      category: "Front Yard",
      location: "Harker Heights, TX",
      city: "Harker Heights"
    },
    {
      id: 4,
      filename: "work_4.jpg",
      url: "./assets/gallery/work_4.jpg",
      uploaded_at: Date.now() - (1000 * 60 * 60 * 24 * 5),
      title: "Fresh Dark Mulch Installation & Flowerbeds",
      category: "Mulch",
      location: "Fort Cavazos, TX",
      city: "Fort Cavazos"
    }
  ];

  let currentItems = [];
  let currentFilter = 'all';
  let currentCityFilter = 'all';

  document.addEventListener('DOMContentLoaded', () => {
    initGallery();
  });

  function detectCategory(title) {
    if (!title) return 'General LawnCare';
    const lower = title.toLowerCase();
    if (lower.includes('front') || lower.includes('frente') || lower.includes('delantera')) return 'Front Yard';
    if (lower.includes('back') || lower.includes('trasero') || lower.includes('atras')) return 'Back Yard';
    if (lower.includes('mulch') || lower.includes('bark') || lower.includes('acolchado')) return 'Mulch';
    if (lower.includes('tree') || lower.includes('arbol') || lower.includes('poda')) return 'Tree Care';
    if (lower.includes('shrub') || lower.includes('hedge') || lower.includes('bush') || lower.includes('arbusto')) return 'Shrubs & Bushes';
    if (lower.includes('clean') || lower.includes('limpieza') || lower.includes('junk') || lower.includes('leaf') || lower.includes('hojas')) return 'Cleanups';
    if (lower.includes('mow') || lower.includes('edg') || lower.includes('stripe') || lower.includes('corte') || lower.includes('pasto')) return 'Mowing & Edging';
    return 'General LawnCare';
  }

  function getCategoryIcon(cat) {
    return CATEGORY_ICONS[cat] || '🌱';
  }

  function escapeHtml(str) {
    if (!str) return '';
    return String(str)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');
  }

  async function initGallery() {
    const grid = document.getElementById('galleryGrid');
    if (!grid) return;

    let items = [];
    try {
      const response = await fetch('./gallery.json?t=' + Date.now());
      if (response.ok) {
        items = await response.json();
      } else {
        items = fallbackGallery;
      }
    } catch (err) {
      console.warn('[Gallery] Using fallback items:', err);
      items = fallbackGallery;
    }

    if (!Array.isArray(items) || items.length === 0) {
      items = fallbackGallery;
    }

    // Normalize category and location properties
    items = items.map((item, idx) => {
      const cat = item.category || detectCategory(item.title);
      const cities = ["Killeen, TX", "Fort Cavazos, TX", "Harker Heights, TX", "Copperas Cove, TX", "Temple, TX"];
      const loc = item.location || cities[idx % cities.length];
      return {
        ...item,
        category: cat,
        location: loc
      };
    });

    // Sort by newest first (descending id / uploaded_at)
    items.sort((a, b) => (b.id || 0) - (a.id || 0));
    currentItems = items;

    setupFilterButtons();
    setupCityFilterButtons();
    updateCategoryCounts(items);
    renderGalleryCards(grid, items, currentFilter, currentCityFilter);
    setupLightbox();

    // Real-time auto-refresh: polls gallery.json every 8 seconds so uploads from iOS App appear immediately!
    if (!window._galleryIntervalSet) {
      window._galleryIntervalSet = true;
      setInterval(async () => {
        try {
          const res = await fetch('./gallery.json?t=' + Date.now());
          if (!res.ok) return;
          const fresh = await res.json();
          if (Array.isArray(fresh) && fresh.length > 0) {
            fresh.sort((a, b) => (b.id || 0) - (a.id || 0));
            currentItems = fresh;
            updateCategoryCounts(fresh);
            renderGalleryCards(grid, fresh, currentFilter, currentCityFilter);
          }
        } catch(e) {}
      }, 8000);
    }
  }

  function updateCategoryCounts(items) {
    const counts = { all: items.length };

    items.forEach(item => {
      const cat = item.category || 'General LawnCare';
      counts[cat] = (counts[cat] || 0) + 1;
    });

    const setBadgeCount = (id, count) => {
      const el = document.getElementById(id);
      if (el) el.textContent = String(count || 0);
    };

    setBadgeCount('countAll', counts['all']);
    setBadgeCount('countFront', counts['Front Yard']);
    setBadgeCount('countBack', counts['Back Yard']);
    setBadgeCount('countMulch', counts['Mulch']);
    setBadgeCount('countTree', counts['Tree Care']);
    setBadgeCount('countShrubs', (counts['Shrubs & Bushes'] || 0) + (counts['Cleanups'] || 0) + (counts['Mowing & Edging'] || 0) + (counts['General LawnCare'] || 0));
  }

  function setupFilterButtons() {
    const filterBar = document.getElementById('galleryFilterBar');
    if (!filterBar) return;

    filterBar.addEventListener('click', (e) => {
      const btn = e.target.closest('.gallery-filter-btn');
      if (!btn) return;

      const filter = btn.getAttribute('data-filter');
      if (!filter) return;

      filterBar.querySelectorAll('.gallery-filter-btn').forEach(b => {
        b.classList.remove('active');
        b.setAttribute('aria-selected', 'false');
      });

      btn.classList.add('active');
      btn.setAttribute('aria-selected', 'true');
      currentFilter = filter;

      const grid = document.getElementById('galleryGrid');
      if (grid) {
        renderGalleryCards(grid, currentItems, currentFilter, currentCityFilter);
      }
    });
  }

  function setupCityFilterButtons() {
    const cityBar = document.getElementById('galleryCityBar');
    if (!cityBar) return;

    cityBar.addEventListener('click', (e) => {
      const btn = e.target.closest('.gallery-city-btn');
      if (!btn) return;

      const city = btn.getAttribute('data-city');
      if (!city) return;

      cityBar.querySelectorAll('.gallery-city-btn').forEach(b => {
        b.classList.remove('active');
      });

      btn.classList.add('active');
      currentCityFilter = city;

      const grid = document.getElementById('galleryGrid');
      if (grid) {
        renderGalleryCards(grid, currentItems, currentFilter, currentCityFilter);
      }
    });
  }

  function renderGalleryCards(container, items, filter, cityFilter) {
    const now = Date.now();

    let filtered = items;

    // Filter by Category
    if (filter && filter !== 'all') {
      if (filter === 'Other') {
        filtered = filtered.filter(item => 
          !['Front Yard', 'Back Yard', 'Mulch', 'Tree Care'].includes(item.category)
        );
      } else {
        filtered = filtered.filter(item => {
          const itemCat = (item.category || '').toLowerCase();
          const target = filter.toLowerCase();
          return itemCat === target || itemCat.includes(target);
        });
      }
    }

    // Filter by City
    if (cityFilter && cityFilter !== 'all') {
      const cTarget = cityFilter.toLowerCase();
      filtered = filtered.filter(item => {
        const loc = (item.location || item.city || '').toLowerCase();
        const title = (item.title || '').toLowerCase();
        return loc.includes(cTarget) || title.includes(cTarget);
      });
    }

    if (filtered.length === 0) {
      container.innerHTML = `
        <div class="gallery-empty-state" style="grid-column: 1 / -1; text-align: center; padding: 3rem 1.5rem; background: rgba(16, 185, 129, 0.05); border: 1px dashed rgba(16, 185, 129, 0.3); border-radius: 16px;">
          <span class="empty-icon" style="font-size: 2.8rem; display: block; margin-bottom: 0.8rem;">🌿</span>
          <h3 style="color: #fff; margin-bottom: 0.5rem; font-size: 1.3rem;">No photos found for this filter</h3>
          <p style="color: #94a3b8; max-width: 460px; margin: 0 auto 1.2rem;">No projects found in <strong>"${escapeHtml(cityFilter !== 'all' ? cityFilter : filter)}"</strong>. Please select "All Cities" or "All Projects".</p>
          <button type="button" class="btn btn-outline btn-sm" onclick="document.querySelector('[data-city=all]')?.click(); document.querySelector('[data-filter=all]')?.click();" style="border-radius: 9999px; font-weight: 600;">View All Projects ✨</button>
        </div>
      `;
      return;
    }

    container.innerHTML = filtered.map((item) => {
      const upTime = item.uploaded_at || now;
      const isNew = (now - upTime) < THREE_DAYS_MS;
      const idFormatted = String(item.id).padStart(2, '0');

      const badgeHtml = isNew
        ? `<span class="gallery-badge badge-new"><span class="badge-pulse"></span>🔥 NEW</span>`
        : `<span class="gallery-badge badge-num">#${idFormatted}</span>`;

      const beforeAfterBadge = item.is_before_after
        ? `<span class="gallery-badge" style="background: linear-gradient(135deg, #10b981, #059669); color: white; font-weight: 700;">✨ Antes & Después</span>`
        : '';

      const category = item.category || detectCategory(item.title);
      const icon = getCategoryIcon(category);
      const title = item.title || `Trabajo #${item.id}`;
      const location = item.location || item.city || 'Killeen & Central TX';

      return `
        <div class="gallery-card" data-full="${item.url}" data-title="${escapeHtml(title)}" data-category="${escapeHtml(category)}" data-id="${item.id}">
          <div class="gallery-thumb-wrap">
            <div class="gallery-badges-row">
              ${badgeHtml}
              ${beforeAfterBadge}
              <span class="gallery-category-pill">${icon} ${escapeHtml(category)}</span>
            </div>
            <img src="${item.url}" alt="${escapeHtml(title)}" class="gallery-img" loading="lazy" onerror="this.src='./assets/images/mowing.jpg'">
            <div class="gallery-overlay">
              <span class="gallery-zoom-pill">🔍 Ampliar Foto</span>
            </div>
          </div>
          <div class="gallery-info">
            <div class="gallery-cat-row">
              <span class="gallery-cat-tag">${icon} ${escapeHtml(category)}</span>
              <span class="gallery-id-tag">#${idFormatted}</span>
            </div>
            <h3 class="gallery-title">${escapeHtml(title)}</h3>
            <div class="gallery-card-footer">
              <span class="gallery-sub-tag">📍 ${escapeHtml(location)}</span>
              <span class="gallery-verified-badge">✓ Verificado</span>
            </div>
          </div>
        </div>
      `;
    }).join('');
  }

  function setupLightbox() {
    const modal = document.getElementById('lightboxModal');
    if (!modal) return;

    const img = document.getElementById('lightboxImg');
    const title = document.getElementById('lightboxTitle');
    const badge = document.getElementById('lightboxBadge');
    const closeBtn = document.getElementById('lightboxClose');

    const openLightbox = (card) => {
      const fullUrl = card.getAttribute('data-full');
      const cardTitle = card.getAttribute('data-title');
      const cardCat = card.getAttribute('data-category');

      if (img) img.src = fullUrl;
      if (title) title.textContent = cardTitle;
      if (badge) badge.textContent = `${getCategoryIcon(cardCat)} ${cardCat}`;

      modal.classList.add('active');
      document.body.style.overflow = 'hidden';
    };

    const closeLightbox = () => {
      modal.classList.remove('active');
      document.body.style.overflow = '';
      if (img) img.src = '';
    };

    document.getElementById('galleryGrid')?.addEventListener('click', (e) => {
      const card = e.target.closest('.gallery-card');
      if (card) {
        openLightbox(card);
      }
    });

    if (closeBtn) {
      closeBtn.addEventListener('click', closeLightbox);
    }

    modal.addEventListener('click', (e) => {
      if (e.target === modal) {
        closeLightbox();
      }
    });

    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape' && modal.classList.contains('active')) {
        closeLightbox();
      }
    });
  }

})();
