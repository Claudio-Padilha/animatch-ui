# Animatch — UI Design Document

**Platform:** Flutter (iOS & Android)
**Market:** Brazil
**Target users:** Elite livestock breeders (cattle & horses)

---

## Design Principles

- **Trust first** — breeders deal in assets worth R$ millions. The UI must feel premium, not playful.
- **Information density** — these users are experts. Show breed, EPD scores, and location data clearly; don't hide behind progressive disclosure unnecessarily.
- **Geo-aware** — location is the primary matching signal. Maps and proximity cues should be prominent.
- **Tier transparency** — users must always understand what they have access to and what requires upgrading, without feeling blocked at every turn.

---

## Color & Typography

### Palette

| Token              | Hex       | Usage                                      |
|--------------------|-----------|--------------------------------------------|
| `primary`          | `#2D5016` | Deep forest green — trust, nature, wealth  |
| `primary-light`    | `#4A7C2F` | Buttons, active states                     |
| `secondary`        | `#C8860A` | Gold — premium tier accent, badges         |
| `surface`          | `#F9F6F0` | Warm off-white — cards, backgrounds        |
| `on-surface`       | `#1A1A1A` | Primary text                               |
| `muted`            | `#6B7280` | Secondary text, labels                     |
| `error`            | `#B91C1C` | Destructive actions                        |
| `verified-badge`   | `#C8860A` | Verified Breeder badge (gold)              |

### Typography (Flutter `TextTheme`)

| Style            | Font              | Size | Weight |
|------------------|-------------------|------|--------|
| `displayLarge`   | Merriweather      | 32   | Bold   |
| `headlineMedium` | Merriweather      | 24   | Bold   |
| `titleMedium`    | Inter             | 16   | 600    |
| `bodyMedium`     | Inter             | 14   | 400    |
| `labelSmall`     | Inter             | 11   | 500    |

Merriweather for headings gives a heritage/pedigree feel. Inter for body keeps it readable on small screens.

---

## Navigation Structure

Bottom `NavigationBar` (Material 3) with 4 destinations:

```
[ Descobrir ]  [ Matches ]  [ Meu Rebanho ]  [ Perfil ]
   (compass)    (handshake)    (list-alt)      (person)
```

---

## Screens

---

### 1. Onboarding (3 slides + CTA)

**Purpose:** Explain the value proposition before sign-up friction.

```
┌────────────────────────────┐
│                            │
│   [Full-bleed photo of     │
│    Nelore in field]        │
│                            │
│   ────────────────         │
│                            │
│   Conecte seus animais     │
│   com a melhor genética    │
│   do Brasil.               │
│                            │
│   Encontre parceiros de    │
│   reprodução por raça,     │
│   região e qualidade.      │
│                            │
│      ○ ● ○                 │
│                            │
│   [ Começar ]              │
│   [ Já tenho conta ]       │
└────────────────────────────┘
```

**Slides:** (1) Matching concept, (2) Geo-proximity, (3) Verified breeders
**UX rationale:** Breeders are not necessarily tech-native. 3 slides max. Skip button top-right.

---

### 2. Login / Register

```
┌────────────────────────────┐
│  ← Voltar                  │
│                            │
│  [Animatch logo]           │
│                            │
│  Entrar na sua conta       │
│                            │
│  ┌──────────────────────┐  │
│  │ E-mail ou CPF/CNPJ   │  │
│  └──────────────────────┘  │
│  ┌──────────────────────┐  │
│  │ Senha           👁   │  │
│  └──────────────────────┘  │
│                            │
│  [ Entrar ]                │
│                            │
│  Esqueci minha senha       │
│                            │
│  ─────── ou ───────        │
│                            │
│  [ Criar conta gratuita ]  │
└────────────────────────────┘
```

**UX rationale:** CPF/CNPJ as login identifier builds trust and maps to the Verified Breeder validation flow. Password field has visibility toggle.

---

### 3. Discover (Home Feed)

The core screen. Swipeable animal cards stacked on a map background.

```
┌────────────────────────────┐
│  Animatch        🔔  ⚙️   │
│                            │
│  [Subtle map of Brazil     │
│   with dots for animals    │
│   in the background]       │
│                            │
│  ┌──────────────────────┐  │
│  │ [Animal photo]       │  │
│  │                      │  │
│  │ Imperador da Serra   │  │
│  │ Nelore · Touro       │  │
│  │ ⭐ 87/100            │  │
│  │ 📍 ~340 km · MG     │  │
│  │                      │  │
│  │ [Breeder name] ✓     │  │
│  └──────────────────────┘  │
│                            │
│      ✕         ♥           │
│    Passar    Curtir        │
└────────────────────────────┘
```

**Card details:**
- Large animal photo (landscape crop)
- Name, species, breed, sex
- Quality score (badge, 0–100)
- Distance — shown at state level for free-tier source animal, município for premium
- Breeder name + verified badge if applicable

**Swipe gestures:** right = like, left = pass. Buttons also available for accessibility.

**Filter bar** (above card, scrollable chips):
```
[Espécie ▾]  [Raça ▾]  [Distância ▾]  [Disponível]
```

**UX rationale:** Map background reinforces that geo-proximity is the primary signal. Quality score is visible immediately — these users judge animals fast.

---

### 4. Animal Detail (full profile)

Reached by tapping the card (not swiping).

```
┌────────────────────────────┐
│  ←  Imperador da Serra     │
│                            │
│  [Photo carousel]          │
│  ○ ● ○ ○                  │
│                            │
│  Imperador da Serra        │
│  Nelore · Touro · 4 anos   │
│  ⭐ Qualidade: 87/100      │
│                            │
│  ──── Localização ────     │
│  📍 Triângulo Mineiro, MG  │
│  ~340 km de você           │
│                            │
│  ──── Criador ─────        │
│  [Avatar] João Mendonça ✓  │
│  Produtor Premium          │
│                            │
│  ──── Genética ─────       │
│  Pedigree: [link ABCZ]     │
│  DEP Peso: +12.4           │
│  DEP Conf.: +8.1           │
│                            │
│  ──── Registro ─────       │
│  ABCZ: 4521-MG             │
│                            │
│        [ ♥ Curtir ]        │
└────────────────────────────┘
```

**UX rationale:** DEP/EPD values are shown as plain numbers — breeders know what they mean. ABCZ registration is a trust signal. Contact details are NOT shown here (only after match confirmation).

---

### 5. Matches List

```
┌────────────────────────────┐
│  Matches                   │
│                            │
│  ┌──────────────────────┐  │
│  │ [Photo] Estrela Real  │  │
│  │         Mangalarga    │  │
│  │         ✅ Confirmado │  │
│  │         2 dias atrás  │  │
│  └──────────────────────┘  │
│                            │
│  ┌──────────────────────┐  │
│  │ [Photo] Dom Quixote   │  │
│  │         Nelore        │  │
│  │         ⏳ Pendente   │  │
│  │         Hoje          │  │
│  └──────────────────────┘  │
│                            │
│  ┌──────────────────────┐  │
│  │ [Photo] Rainha Árabe  │  │
│  │         Quarto Milha  │  │
│  │         ❌ Recusado   │  │
│  │         5 dias atrás  │  │
│  └──────────────────────┘  │
└────────────────────────────┘
```

**Status badges:**
- `✅ Confirmado` — both sides liked, contact revealed
- `⏳ Pendente` — waiting for the other breeder
- `❌ Recusado` — rejected

**UX rationale:** Status is the most important information — show it immediately on the list item. No mystery about where a match stands.

---

### 6. Match Detail (post-confirmation)

Only reachable for `Confirmado` matches. **This is where contact is revealed.**

```
┌────────────────────────────┐
│  ← Match Confirmado ✅     │
│                            │
│  [Your animal photo]       │
│      ♥                     │
│  [Their animal photo]      │
│                            │
│  Imperador da Serra        │
│  ×                         │
│  Estrela Real              │
│                            │
│  ──── Contato ─────        │
│  Criador: João Mendonça    │
│  📞 (34) 9 9812-3456       │
│  📧 joao@fazendaxyz.com.br │
│  🌐 fazendaxyz.com.br      │
│                            │
│  ──── Ações ───────        │
│  [ Ligar ]   [ WhatsApp ]  │
│                            │
│  [ Desfazer match ]        │
└────────────────────────────┘
```

**UX rationale:** Contact is only revealed here, fulfilling the privacy rule from the domain. WhatsApp deeplink is essential for the Brazilian market — it's the primary business communication channel.

---

### 7. My Herd (Meu Rebanho)

```
┌────────────────────────────┐
│  Meu Rebanho          [+]  │
│                            │
│  3 / 5 animais (Free)      │
│  [░░░░░░░░░░░░░░░░░░░░░░]  │
│  Upgrade para mais animais │
│                            │
│  ┌──────────────────────┐  │
│  │ [Photo] Imperador    │  │
│  │ Nelore · Disponível  │  │
│  │ ⭐ 87   [Editar]     │  │
│  └──────────────────────┘  │
│                            │
│  ┌──────────────────────┐  │
│  │ [Photo] Dom Carlos   │  │
│  │ Nelore · Indisponível│  │
│  │ ⭐ 72   [Editar]     │  │
│  └──────────────────────┘  │
└────────────────────────────┘
```

**UX rationale:** The animal count limit (5 for free tier) is shown as a progress bar — not a hard wall. Soft upgrade nudge beneath, not a modal blocker.

---

### 8. Add / Edit Animal

```
┌────────────────────────────┐
│  ← Novo Animal             │
│                            │
│  [Photo upload area]       │
│  + Adicionar fotos         │
│                            │
│  Nome *                    │
│  ┌──────────────────────┐  │
│  │ Imperador da Serra   │  │
│  └──────────────────────┘  │
│                            │
│  Espécie *    Raça *        │
│  [Bovino ▾]  [Nelore ▾]   │
│                            │
│  Sexo *       Idade        │
│  [Touro ▾]   [4 anos ▾]   │
│                            │
│  Registro ABCZ             │
│  ┌──────────────────────┐  │
│  └──────────────────────┘  │
│                            │
│  Localização *             │
│  [Use minha localização]   │
│  ou buscar município...    │
│                            │
│  Disponível para match     │
│  ○ Sim  ○ Não              │
│                            │
│  DEP / Índices (opcional)  │
│  [+ Adicionar índice]      │
│                            │
│        [ Salvar ]          │
└────────────────────────────┘
```

**UX rationale:** DEP fields are optional and collapsed — not all animals have formal EPD data, and forcing it creates friction. Location uses GPS by default with municipality fallback (important for the tier-gated precision logic).

---

### 9. Breeder Profile

```
┌────────────────────────────┐
│  ←  Meu Perfil    [Editar] │
│                            │
│  [Avatar / farm logo]      │
│  João Mendonça             │
│  Fazenda Serra Verde       │
│  Triângulo Mineiro, MG     │
│                            │
│  ✓ Criador Verificado      │
│  ABCZ: 4521-MG             │
│                            │
│  ──── Plano ───────        │
│  🟡 Premium Individual     │
│  Renova em 14/08/2026      │
│  [ Gerenciar plano ]       │
│                            │
│  ──── Estatísticas ────    │
│  12 animais cadastrados    │
│  8 matches confirmados     │
│  34 curtidas recebidas     │
│                            │
│  [ Sair da conta ]         │
└────────────────────────────┘
```

**UX rationale:** Verified badge and association registration are prominent — they're the credibility markers in this market. Stats give users a sense of traction.

---

## Flutter Implementation Notes

- Use **Material 3** (`useMaterial3: true`) with a custom `ColorScheme.fromSeed` seeded from `#2D5016`.
- The discover card stack can be built with a `Stack` + `GestureDetector` + `Transform.rotate` for the swipe feel. Consider the [`flutter_card_swiper`](https://pub.dev/packages/flutter_card_swiper) package.
- Bottom nav: `NavigationBar` widget (Material 3), not the older `BottomNavigationBar`.
- Map background on Discover: `flutter_map` (OpenStreetMap, no API key needed) or Google Maps. Use a low-opacity overlay so the card is the focus.
- WhatsApp deeplink: `url_launcher` with `https://wa.me/55XXXXXXXXXXX`.
- Photo upload: `image_picker` + multipart POST to your API.
- For the progress bar on "Meu Rebanho": `LinearProgressIndicator` with a custom color.
- Localization: use `intl` package. All copy in pt-BR from the start.
