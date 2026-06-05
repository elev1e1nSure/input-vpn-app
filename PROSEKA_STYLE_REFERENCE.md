# Просека — Style Reference for AI

Этот файл даёшь ИИ в начале любого нового проекта.
Скажи: "Используй стили из этого файла. CSS-переменные уже подключены через proseka-design-system.css"

---

## Подключение

```
Скопируй proseka-design-system.css в проект и подключи:
- CSS/Vite: @import './proseka-design-system.css';
- Next.js: import './proseka-design-system.css'; в layout или _app
- HTML: <link rel="stylesheet" href="proseka-design-system.css">
```

Шрифт Geist (бесплатный): https://fonts.google.com/specimen/Geist
Или подключи через тег:
```html
<link href="https://fonts.googleapis.com/css2?family=Geist:wght@400;500;600;700;800&display=swap" rel="stylesheet">
```

---

## Цвета (CSS-переменные)

| Переменная | Значение | Использование |
|---|---|---|
| `--background` | `oklch(0.13 0 0)` | Фон страницы — почти чёрный |
| `--foreground` | `oklch(0.97 0 0)` | Основной текст — белый |
| `--muted` | `oklch(0.20 0 0)` | Фон карточек, мутных элементов |
| `--muted-fg` | `oklch(0.62 0 0)` | Второстепенный текст, иконки |
| `--border` | `oklch(0.24 0 0)` | Границы |
| `--accent-green` | `oklch(0.78 0.22 145)` | Единственный акцентный цвет — зелёный |

Принцип: всё тёмное и сдержанное, один зелёный акцент.
Никаких других цветов нет.

---

## Логотип

Файл: `/logo-brand.svg` (SVG-файл лежит в /public)
Использование: просто `<img src="/logo-brand.svg" alt="Просека">`
На главной логотип крутится с классом `.breathe` (медленное дыхание).

---

## Кнопка .btn-primary

**Внешний вид:** белая/светлая, круглая (border-radius: full), полужирный текст, стрелка →
**Эффект при ховере:** зелёный круг растекается из точки где курсор (liquid fill)
**Стрелка** при ховере сдвигается вправо на 4px

HTML:
```html
<a href="#" class="btn-primary">
  Открыть в Телеграме
  <svg class="btn-arrow" viewBox="0 0 24 24" fill="none" width="16" height="16">
    <path d="M5 12h14M13 6l6 6-6 6" stroke="currentColor" stroke-width="2.5"
          stroke-linecap="round" stroke-linejoin="round"/>
  </svg>
</a>
```

JS для эффекта заливки от курсора (обязателен):
```js
document.querySelectorAll('.btn-primary').forEach(btn => {
  btn.addEventListener('mousemove', e => {
    const r = btn.getBoundingClientRect();
    btn.style.setProperty('--mx', ((e.clientX - r.left) / r.width * 100) + '%');
    btn.style.setProperty('--my', ((e.clientY - r.top)  / r.height * 100) + '%');
  });
});
```

---

## Карточки .feature-card

**Внешний вид:** тёмный фон с полупрозрачной границей, иконка слева, лейбл мелкими буквами сверху, крупный текст снизу
**Эффект при ховере:** граница светлее + scale(1.02) + иконка становится зелёной

HTML:
```html
<div class="feature-card">
  <span class="feature-card__icon">
    <!-- SVG иконка 18x18 -->
    <svg>...</svg>
  </span>
  <div>
    <p class="feature-card__label">Работает в РФ</p>
    <p class="feature-card__value">VLESS — стабильное соединение</p>
  </div>
</div>
```

Сетка карточек (2 колонки на десктопе):
```html
<div style="display:grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 1rem;">
  <!-- карточки -->
</div>
```

Иконки из набора Lucide (бесплатные SVG): https://lucide.dev
Использованные иконки: ShieldCheck, Wallet, MessageCircle, Zap

---

## Типографика

Все заголовки: font-weight 700-800, tight tracking (letter-spacing: -0.02em)
Основной текст: font-weight 400, leading 1.6
Второстепенный текст: цвет `--muted-fg`

```css
h1 { font-size: clamp(2.5rem, 8vw, 5rem); font-weight: 800; letter-spacing: -0.02em; line-height: 0.95; }
h2 { font-size: clamp(2rem, 6vw, 4rem); font-weight: 700; letter-spacing: -0.02em; }
h3 { font-size: clamp(1.5rem, 4vw, 2.5rem); font-weight: 700; }
p  { font-size: 1.125rem; line-height: 1.6; color: var(--muted-fg); }
```

---

## Анимации (CSS-классы)

| Класс | Эффект |
|---|---|
| `.breathe` | Медленное дыхание — scale 1→1.06→1, бесконечно (для логотипа) |
| `.pulse-dot` | Пульсация с зелёным свечением (для статус-точек) |
| `.scroll-chevron` | Прыжок вниз (для иконки "листай вниз") |
| `.reveal` | Скрыт по умолчанию. Добавь `.is-visible` чтобы показать с анимацией |
| `.marker-ping` | Пинг-эффект на SVG `<circle>` (для карт) |

Для `.reveal` нужен IntersectionObserver:
```js
const obs = new IntersectionObserver(entries => {
  entries.forEach(e => { if (e.isIntersecting) e.target.classList.add('is-visible'); });
}, { threshold: 0.15 });
document.querySelectorAll('.reveal').forEach(el => obs.observe(el));
```

---

## Разделитель

Горизонтальная линия между секциями:
```html
<hr style="border: none; border-top: 1px solid var(--border); margin: 0; opacity: 0.5;">
```

---

## Принципы дизайна

1. **Монохром + один акцент.** Только чёрное, белое, серое — и зелёный для важного.
2. **Сдержанность.** Нет ярких градиентов, теней, украшений. Всё минимально.
3. **Плавность.** Переходы всегда через `cubic-bezier(0.22, 1, 0.36, 1)` — быстрый старт, мягкое торможение.
4. **Шрифт — главный инструмент.** Крупные жирные заголовки, tight tracking.
