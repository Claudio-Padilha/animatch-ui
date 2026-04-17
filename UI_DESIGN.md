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
| `displayMedium`  | Merriweather      | 28   | Bold   |
| `headlineLarge`  | Merriweather      | 28   | Bold   |
| `headlineMedium` | Merriweather      | 24   | Bold   |
| `headlineSmall`  | Merriweather      | 20   | Bold   |
| `titleLarge`     | Inter             | 18   | 600    |
| `titleMedium`    | Inter             | 16   | 600    |
| `titleSmall`     | Inter             | 14   | 600    |
| `bodyLarge`      | Inter             | 16   | 400    |
| `bodyMedium`     | Inter             | 14   | 400    |
| `bodySmall`      | Inter             | 12   | 400    |
| `labelLarge`     | Inter             | 14   | 500    |
| `labelMedium`    | Inter             | 12   | 500    |
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
│                    [ Pular]│  ← top-right, all slides
│                            │
│   [Slide background]       │
│   (see slide details below)│
│                            │
│  ┌─ content panel ────────┐│
│  │                        ││
│  │ Conecte seus animais   ││
│  │ com a melhor genética  ││
│  │ do Brasil.             ││
│  │                        ││
│  │ Encontre parceiros de  ││
│  │ reprodução por raça,   ││
│  │ região e qualidade.    ││
│  │                        ││
│  │   ══ ─ ─   (dots)      ││  ← active dot is wide pill
│  │                        ││
│  │  [ Continuar ]         ││  ← "Começar" on last slide
│  │  [ Já tenho conta ]    ││
│  └────────────────────────┘│
└────────────────────────────┘
```

**Slide backgrounds:**
- **Slide 1** — full-bleed `onboarding_1.jpg` (matching concept photo) with a subtle top scrim
- **Slide 2** — dark green gradient (`#0D2105` → `#2D5016`) with radar rings and scattered `agriculture` icons representing geo-proximity
- **Slide 3** — gold gradient (`#3D2A00` → `#C8860A`) with a premium badge icon and floating association chips (ABCZ, ABQM, ABCAngus, ABCCMM)

**Dots indicator:** animated pill — active dot expands horizontally (22 px wide); inactive dots are 8 px circles.

**Navigation:** "Pular" and "Começar" → Register. "Já tenho conta" → Login.

**UX rationale:** Breeders are not necessarily tech-native. 3 slides max. Skip button top-right.

---

### 2a. Login

```
┌────────────────────────────┐
│  ← Voltar                  │
│                            │
│  [Animatch logo]           │
│                            │
│  Entrar na sua conta       │
│  Use seu e-mail ou         │
│  CPF/CNPJ para acessar.    │
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
│  [ Esqueci minha senha ]   │
│                            │
│  ─────── ou ───────        │
│                            │
│  [ Criar conta gratuita ]  │  ← OutlinedButton
└────────────────────────────┘
```

**UX rationale:** CPF/CNPJ as login identifier builds trust and maps to the Verified Breeder validation flow. Password field has visibility toggle.

---

### 2b. Register

```
┌────────────────────────────┐
│  ← Voltar                  │
│                            │
│  [Animatch logo]           │
│                            │
│  Criar sua conta           │
│  Acesse a maior rede de    │
│  genética de elite.        │
│                            │
│  ┌──────────────────────┐  │
│  │ Nome completo        │  │
│  └──────────────────────┘  │
│  ┌──────────────────────┐  │
│  │ E-mail               │  │
│  └──────────────────────┘  │
│  ┌──────────────────────┐  │
│  │ CPF ou CNPJ          │  │
│  └──────────────────────┘  │
│  ┌──────────────────────┐  │
│  │ Senha           👁   │  │
│  └──────────────────────┘  │
│  ┌──────────────────────┐  │
│  │ Confirmar senha 👁   │  │
│  └──────────────────────┘  │
│                            │
│  [ Criar conta ]           │
│                            │
│  Já tem uma conta? Entrar  │
└────────────────────────────┘
```

**Validation:** E-mail must contain `@`. Senha minimum 8 characters. Confirm senha must match. All fields required.

**UX rationale:** CPF/CNPJ captured at registration enables Verified Breeder validation later. Both password fields have independent visibility toggles.

---

### 3. Discover (Home Feed)

The core screen. Swipeable animal cards.

```
┌────────────────────────────┐
│  Animatch        🔔  🎛️   │
│                            │
│  ┌ selected animal banner┐ │  ← shown when an animal is selected
│  │ ♥ Buscando par para:  │ │
│  │ Imperador da Serra    │ │
│  │                 Trocar│ │
│  └────────────────────────┘ │
│                            │
│  [Espécie ▾][Raça ▾][Distância ▾][Disponível]
│                            │
│  ┌──────────────────────┐  │
│  │                      │  │
│  │  ⭐ 87/100           │  │  ← score badge overlays photo
│  │                      │  │
│  │  [Full-bleed photo,  │  │  ← BoxFit.contain on black bg
│  │   black letterbox]   │  │
│  │                      │  │
│  │  Imperador da Serra  │  │
│  │  Nelore · Touro      │  │
│  │  📍 ~340 km · MG     │  │
│  │  👤 João Mendonça    │  │
│  │     [Verificado]     │  │
│  └──────────────────────┘  │
│                            │
│      ✕         ♥           │
│    Passar    Curtir        │
└────────────────────────────┘
```

**No-animal-selected state:** If no animal is selected from Meu Rebanho, a full-screen empty state replaces the swiper with instructions and a "Meu Rebanho" button.

**Empty state (all cards swiped):** "Nenhum animal por aqui / Tente ajustar os filtros ou volte mais tarde."

**Selected animal banner:** Pinned below the AppBar when an animal is active for pairing. "Trocar" link navigates to Meu Rebanho to change selection.

**Card details:**
- Full-bleed photo with `BoxFit.contain` on black background (full animal visible, letterboxed if needed)
- Score badge (top of content overlay), name, breed · sex, distance, breeder + "Verificado" pill if verified
- Gradient scrim from center to bottom so text is readable over photo

**Swipe gestures:** right = like, left = pass. Buttons also available for accessibility.

**Filter bar** (above card, scrollable chips):
```
[Espécie ▾]  [Raça ▾]  [Distância ▾]  [Disponível]
```

**Note:** Map background is planned but not yet implemented. Background is currently `surface` colour.

**UX rationale:** Quality score is visible immediately — these users judge animals fast. Selected-animal banner keeps context clear when swiping.

---

### 4. Animal Detail (full profile)

Reached by tapping the card (not swiping). No traditional AppBar — a floating circular back button overlays the photo.

```
┌────────────────────────────┐
│ ←  (floating circle btn)   │  ← overlays photo, top-left
│                            │
│  [Photo, 440px height,     │
│   BoxFit.contain, black bg]│
│  ── ─ ─  (dot indicator)   │  ← only shown if >1 photo
│                            │
│  Imperador da Serra        │  ← headlineMedium (Merriweather)
│  Nelore · Touro · 4 anos   │
│  [⭐ Qualidade: 87/100]    │  ← coloured pill badge
│                            │
│  ┌─ LOCALIZAÇÃO ──────────┐│
│  │ 📍 Triângulo Mineiro,MG││
│  │ 〰 ~340 km de você · MG││
│  └────────────────────────┘│
│  ┌─ CRIADOR ───────────────┐│
│  │ [J] João Mendonça  ✓   ││  ← initial avatar + verified icon
│  │     Produtor Premium    ││
│  └────────────────────────┘│
│  ┌─ GENÉTICA ──────────────┐│
│  │ 🌿 Pedigree: ver no ABCZ││
│  │ DEP Peso      [+12.4]  ││  ← green pill for positive
│  │ DEP Conf.     [+8.1]   ││
│  └────────────────────────┘│
│  ┌─ REGISTRO ──────────────┐│
│  │ 🪪 ABCZ: 4521-MG        ││
│  └────────────────────────┘│
│                            │
│  [bottom nav bar]          │
│      ✕         ♥           │  ← floating above bottom nav
│    Passar    Curtir        │
└────────────────────────────┘
```

**Score badge colour:** gold (`#D4A017`) for ≥90, primary green for ≥75, muted for lower.

**DEP values:** colour-coded pills — green for positive (`+`), red for negative. Values shown with one decimal place.

**Breeder row:** circle avatar with name initial, "Produtor Premium" subtitle if verified, plain "Produtor" otherwise.

**Curtir action:** shows confirmation dialog — "Curtiu! Seu interesse em [animal] foi registrado. Você será notificado quando o criador responder."

**Bottom nav** remains visible (screen uses `AppBottomNav`). Floating CTAs sit above it.

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
└────────────────────────────┘
```

**Status badges:**
- `✅ Confirmado` — both sides liked, contact revealed; tapping opens Match Detail
- `⏳ Pendente` — waiting for the other breeder; not tappable

**Note:** Rejected matches are not shown in the list — the list only surfaces actionable states.

**UX rationale:** Status is the most important information — show it immediately on the list item. No mystery about where a match stands.

---

### 6. Match Detail (post-confirmation)

Only reachable for `Confirmado` matches. **This is where contact is revealed.**

```
┌────────────────────────────┐
│  ← Match Confirmado ✅     │
│                            │
│  [Your photo]  ♥  [Their]  │  ← side by side, heart between
│  Imperador        Estrela  │
│  da Serra         Real     │
│  Nelore·Touro  Nelore·Vaca │
│                            │
│  ──── Animais ─────        │
│  SEU ANIMAL                │
│  Imperador da Serra  ⭐87  │
│  Nelore · Touro            │
│  🎂 4 anos  🪪 ABCZ:4521-MG│
│  📍 Triângulo Mineiro, MG  │
│  DEP Peso Desmame   [+12.4]│
│  DEP Conformação    [+8.1] │
│                            │
│  ANIMAL DO CRIADOR         │
│  Estrela Real        ⭐91  │
│  Nelore · Vaca             │
│  🎂 3 anos  🪪 ABCZ:7834-GO│
│  📍 Sul Goiano, GO         │
│  DEP Peso Desmame   [+14.2]│
│  DEP Conformação    [+9.5] │
│                            │
│  ──── Contato ─────        │
│  👤 João Mendonça          │
│  📧 joao@fazendaxyz.com.br │
│                            │
│  [       💬 Chat        ]  │  ← full-width, WhatsApp green
│                            │
│  [ Desfazer match ]        │
└────────────────────────────┘
```

**Pair header:** Two photos side by side with a heart circle between them. Each photo has the animal name and breed below it.

**Animal cards:** Each animal shown in a card with score pill, age, registry (ABCZ/ABQM), location, and DEP values as colour-coded pills (green for positive, red for negative). Fields are optional — cards adapt if data is absent.

**Contact section:** Shows only breeder name and email. Phone number is used exclusively by the Chat button and is not displayed as a field.

**Chat button:** Full-width `FilledButton` in WhatsApp green (`#25D366`). Opens `https://wa.me/55{phone}`. No Ligar button — Chat covers the primary communication channel.

**DEP values:** green pill for positive (`+`), red for negative. One decimal place.

**Desfazer match:** shows a confirmation dialog before acting — "O contato será removido e esta conexão será desfeita."

**UX rationale:** Names under photos remove ambiguity at a glance. Single Chat action reduces friction — WhatsApp is the dominant business channel in Brazil.

---

### 7. My Herd (Meu Rebanho)

```
┌────────────────────────────┐
│  Meu Rebanho          [+]  │  ← icon button in AppBar
│                            │
│  ┌─ selection banner ─────┐│  ← contextual; hidden if none selected
│  │ ♥ Buscando par para:   ││
│  │   Imperador da Serra   ││
│  └────────────────────────┘│
│                            │
│  ┌─ quota card ───────────┐│
│  │ 3 / 5 animais  [Plano  ││
│  │                Gratuito││
│  │ [████████░░░░░░░░░░░░] ││  ← red at limit
│  │ Upgrade para animais   ││
│  │ ilimitados →           ││
│  └────────────────────────┘│
│                            │
│  ┌──────────────────────┐  │
│  │ [Photo] Imperador    │  │
│  │ Nelore · Touro       │  │
│  │ ⭐ 87  [Disponível]  │  │
│  │           [Buscar par]│  │  ← or [✓ Selecionado] if active
│  └──────────────────────┘  │
│                            │
│  ┌──────────────────────┐  │
│  │ [Photo] Dom Carlos   │  │
│  │ Nelore · Touro       │  │
│  │ ⭐ 72  [Indisponível]│  │
│  │           [Buscar par]│  │
│  └──────────────────────┘  │
│                            │
│       [+ Adicionar animal] │  ← FloatingActionButton.extended
└────────────────────────────┘
```

**Selection flow:** Tapping "Buscar par" marks that animal as active and navigates to Discover. The card highlights with a primary-coloured border and shows "Selecionado" instead.

**Card tap:** Tapping anywhere on an animal card (outside the "Buscar par" button) navigates to Screen 7b — My Animal Detail.

**UX rationale:** The animal count limit (5 for free tier) is shown as a progress bar — not a hard wall. Soft upgrade nudge beneath, not a modal blocker.

---

### 7b. My Animal Detail

Own-animal detail view, reached by tapping a card in Meu Rebanho. No AppBar — floating circular buttons overlay the photo, matching the style of Screen 4.

```
┌────────────────────────────┐
│ ←                    [✏]   │  ← both floating circle buttons over photo
│                            │
│  [Full-bleed photo, 400px] │
│                            │
│  Imperador da Serra        │  ← headlineMedium (Merriweather)
│  Nelore · Touro · 4 anos   │
│  [⭐ Qualidade: 87/100]    │  ← coloured pill badge (same rules as Screen 4)
│  [Disponível]              │  ← green or muted pill
│                            │
│  ┌─ IDENTIFICAÇÃO ────────┐│
│  │ 🪪 ABCZ: 4521-MG       ││
│  │ 📅 4 anos               ││
│  │ 🏷 Nelore · Touro       ││
│  └────────────────────────┘│
│                            │
│  ┌─ LOCALIZAÇÃO ──────────┐│
│  │ 📍 Triângulo Mineiro,MG││
│  └────────────────────────┘│
│                            │
│  ┌─ STATUS ────────────────┐│
│  │ ✅ Disponível p/ match  ││
│  │ ⭐ Pontuação: 87/100    ││
│  └────────────────────────┘│
│                            │
│  [bottom nav bar]          │
└────────────────────────────┘
```

**Back button:** top-left, same semi-transparent black circle as Screen 4.

**Edit button:** top-right, same semi-transparent black circle with pencil icon. Navigates to Screen 8 (Edit Animal) pre-populated with this animal's data.

**No CTAs for like/pass** — this is the user's own animal, not a candidate for matching. No "Curtir" or "Passar" buttons.

**Photo fallback:** if no image is set, shows a `#2D5016` tinted container with a `pets` icon centred.

**UX rationale:** Keeps the same visual language as the Discover detail screen so breeders feel at home, while removing the pairing actions that don't apply to their own animals.

---

### 8. Add / Edit Animal

Both screens share the same form layout. **Add Animal** (`/rebanho/novo`) starts with all fields empty. **Edit Animal** (`/rebanho/animal/editar`) is reached from Screen 7b's edit button and arrives pre-populated with the selected animal's data; the AppBar title becomes "Editar [animal name]" and there is a **[Salvar]** text action in the AppBar in addition to the bottom button.

```
┌────────────────────────────┐
│  ← Novo Animal             │  ← or "Editar Imperador da Serra  [Salvar]"
│                            │
│  ┌─ photo area ───────────┐│  ← 180px height, rounded-16
│  │  [existing photo]      ││  ← on Edit: shows current photo
│  │  [Alterar foto] badge  ││  ← dark pill overlay, bottom-right
│  │                        ││  ← on Add: placeholder with camera icon
│  └────────────────────────┘│
│                            │
│  Nome do animal *          │
│  ┌──────────────────────┐  │
│  │ Imperador da Serra   │  │
│  └──────────────────────┘  │
│                            │
│  Espécie *    Raça *        │
│  [Bovino ▾]  [Nelore ▾]   │
│                            │
│  Sexo *       Idade (anos) │
│  [Touro ▾]   [Ex: 4     ] │  ← text field, not dropdown
│                            │
│  Registro (ABCZ/ABQM/etc.) │
│  ┌──────────────────────┐  │
│  └──────────────────────┘  │
│                            │
│  Localização *             │
│  ┌──────────────────────┐  │
│  │ 📍 Município, UF     │  │  ← text field only, no GPS button
│  └──────────────────────┘  │
│                            │
│  ┌──────────────────────┐  │
│  │ Disponível para match  ●│  ← SwitchListTile (toggle)
│  └──────────────────────┘  │
│                            │
│  ┌─ DEP / Índices ─────[▾]┐│  ← collapsible section
│  │ (collapsed by default) ││
│  │ When expanded:         ││
│  │  DEP Peso ao Nascer    ││
│  │  DEP Peso ao Desmame   ││
│  │  DEP Peso aos 18 meses ││
│  │  Índice de Fertilidade ││
│  └────────────────────────┘│
│                            │
│      [ Salvar animal ]     │
└────────────────────────────┘
```

**Species-aware dropdowns:** Raça and Sexo options change based on Espécie selection.
- Bovino sexes: Touro, Vaca, Novilho, Novilha
- Equino sexes: Garanhão, Égua, Potro, Potranca

**UX rationale:** DEP fields are optional and collapsed — not all animals have formal EPD data, and forcing it creates friction. Location is a free-text municipality field (GPS integration is planned).

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

### 10. Edit Breeder Profile

Reached from Screen 9 via the **[Editar]** button in the AppBar. Push navigation (not a tab).

```
┌────────────────────────────┐
│  ←  Editar Perfil  [Salvar]│
│                            │
│        [Avatar]            │
│         📷 (badge)         │
│                            │
│  DADOS PESSOAIS            │
│  ┌──────────────────────┐  │
│  │ 👤 Nome completo *   │  │
│  └──────────────────────┘  │
│  ┌──────────────────────┐  │
│  │ 🏚 Nome da fazenda * │  │
│  └──────────────────────┘  │
│  ┌──────────────────────┐  │
│  │ 📍 Localização *     │  │
│  └──────────────────────┘  │
│                            │
│  ASSOCIAÇÃO                │
│  ┌──────────────────────┐  │
│  │ 🪪 Registro ABCZ     │  │
│  └──────────────────────┘  │
│  Usado para verificação    │
│                            │
│  [ Salvar alterações ]     │
└────────────────────────────┘
```

Fields marked `*` are required — empty submit shows inline "Campo obrigatório" errors.

On save: Riverpod state is updated in-memory, a snackbar "Perfil atualizado" appears, and the screen pops back to Screen 9, which reactively reflects the changes.

Avatar circle shows a camera-badge overlay. Tapping it is a placeholder for `image_picker` upload (not yet wired to backend).

Fields not editable here (plan, stats) are read-only on Screen 9 — they are server-driven.

**UX rationale:** Separating view and edit keeps the profile screen clean. Saving and popping instead of navigating forward maintains the shallow stack expected on iOS.

---

## Flutter Implementation Notes

- Use **Material 3** (`useMaterial3: true`) with a custom `ColorScheme.fromSeed` seeded from `#2D5016`.
- The discover card stack uses [`flutter_card_swiper`](https://pub.dev/packages/flutter_card_swiper) — already integrated.
- Bottom nav: `NavigationBar` widget (Material 3), not the older `BottomNavigationBar`.
- Map background on Discover: `flutter_map` (OpenStreetMap, no API key needed) or Google Maps. Use a low-opacity overlay so the card is the focus.
- WhatsApp deeplink: `url_launcher` with `https://wa.me/55XXXXXXXXXXX`.
- Photo upload: `image_picker` + multipart POST to your API.
- For the progress bar on "Meu Rebanho": `LinearProgressIndicator` with a custom color.
- Localization: use `intl` package. All copy in pt-BR from the start.
