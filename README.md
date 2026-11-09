# Color Fund 🎨💰

**Color Fund** é um aplicativo mobile nativo gamificado desenvolvido em **Flutter** para rastreamento de metas financeiras através de um motor interativo de pintura.

---

## 🚀 Arquitetura & Stack Tecnológica

- **Linguagem & Framework:** Dart & Flutter (Material 3).
- **Gerência de Estado:** [Riverpod 2.x](https://riverpod.dev) (`flutter_riverpod`).
- **Backend & Autenticação:** Firebase Auth, Cloud Firestore e Firebase Crashlytics.
- **Monetização & Pagamentos:** `flutter_stripe` com Paywall freemium e webhooks.
- **Segurança:** `flutter_dotenv` (.env) e regras estritas do Firestore (`firestore.rules`).
- **Gamificação & UI:** Animações com `TweenAnimationBuilder`, `HapticFeedback` tátil e explosão de confetes com `confetti`.
- **Internacionalização (i18n):** Suporte nativo a Real (BRL), Euro (EUR) e Dólar (USD) via `intl`.

---

## 🔒 Regras de Negócio Freemium

| Recurso | FREE | PREMIUM (Pro) |
| :--- | :---: | :---: |
| **Metas ativas simultâneas** | 1 (uma) | **Ilimitadas** |
| **Layouts Visuais** | Apenas Pote Básico (`layout_jar_01`) | **Todos (Pote, Calendário 365, Cyber Cofrinho, Espacial)** |
| **Lançamento de depósitos** | Manual | **Manual + Calculadora Inteligente (diária/semanal)** |
| **Backup & Exportação** | ❌ | **✅ Exportação de histórico** |

---

## 📁 Estrutura de Pastas (Clean Architecture)

```
color_fund/
├── .github/workflows/
│   └── build.yml               # CI/CD: Compilação automática de APK no GitHub Actions
├── lib/
│   ├── core/
│   │   ├── utils/
│   │   │   └── currency_formatter.dart # Formatação BRL, EUR, USD
│   ├── models/
│   │   └── goal_model.dart             # Modelo de dados da meta com serialização Firestore
│   ├── services/
│   │   └── subscription_service.dart   # Controle de barreiras Free vs Premium
│   ├── widgets/
│   │   └── paintable_goal_widget.dart  # Motor interativo de pintura, vibração e confetes
│   └── main.dart                       # Ponto de entrada com Riverpod ProviderScope
├── .env.example                        # Modelo de variáveis de ambiente
├── firestore.rules                     # Regras de segurança do Firestore
└── pubspec.yaml                        # Dependências mapeadas
```

---

## 🛠️ Como rodar o projeto

1. **Instale as dependências:**
   ```bash
   flutter pub get
   ```

2. **Configure o arquivo de ambiente:**
   Copie `.env.example` para `.env` e preencha sua chave pública do Stripe:
   ```bash
   cp .env.example .env
   ```

3. **Execute no emulador ou dispositivo físico:**
   ```bash
   flutter run
   ```

