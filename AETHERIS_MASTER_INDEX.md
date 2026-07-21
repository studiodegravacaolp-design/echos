# 🧭 AETHERIS — MASTER PROJECT BLUEPRINT & AI CONTEXT INDEX

> **Nota para IAs/Assistentes de Código:** Este arquivo contém a especificação mestre do Projeto AETHERIS. Toda geração de código TypeScript, arquitetura de classes, lógicas de combate e componentes de UI deve seguir estritamente as regras e limites definidos aqui.

---

## 1. VISÃO GERAL DO PRODUTO (PRODUCT OVERVIEW)
- **Título:** Aetheris
- **Gênero:** JRPG Tático de Sobrevivência e Escolhas (HD-2D Pixel Art).
- **Estilo Visual:** 32-bit HD-2D Pixel Art (Inspirado em Octopath Traveler / Triangle Strategy). Sem 3D fotorrealista.
- **Tom Narrativo:** Apocalipse industrial, escassez de recursos, fumaça, fuligem e arqueologia de máquinas em Brenhold.
- **Premissa Core:** "Nostalgia. Escolha. Consequência." — O ambiente reage às decisões do jogador e o equilíbrio da mente molda o combate e a história.

---

## 2. MECÂNICA CORE: A BALANÇA DE ESTAFA (SYSTEM MATRIX)
A Balança de Estafa oscila em um eixo dinâmico de **-100 (Materno)** a **+100 (Paterno)**.

### Regras de Atributos:
- **Materno (-1 a -100):** Foco em Preservação e EP.
  - *Fórmula:* Bônus EP = +(|Estafa| * 0.5)%. Max (-100): +50% Regeneração de EP/turno, -20% Eficiência de Armadura Física.
- **Paterno (+1 a +100):** Foco em Rigidez, Impacto e Defesa Física.
  - *Fórmula:* Bônus Defesa = +(Estafa * 0.4)%. Max (+100): +40% Resistência Física, +30% no Custo de EP de Habilidades Mágicas/Complexas.

### Regras de UI Diegética & Insubordinação Tática:
- **Extremo Materno (-60 a -100):** Bloqueia opções de execução, sacrifício ou frieza na UI ("Empatia Ativa").
- **Extremo Paterno (+60 a +100):** Bloqueia opções de diálogo sensível, cura compassiva ou partilha de itens ("Cálculo Tático").
- **Consequência:** Se o jogador força um comando incompatível, a unidade executa a ação de forma autônoma e modificada.

---

## 3. AS SEIS RAÇAS FUNDADORAS E SUAS REAÇÕES TÁTICAS

> **Status Visual HD-2D (Blueprint v1.2):** os prompts de arte HD-2D de **Anões**, **Fadas** e **Lurídeos** estão **calibrados e consolidados** ✅ (chassi, silhueta, paleta e prompt de geração fechados) — ver [`doc/art_bible/BLUEPRINT_VISUAL_MESTRE.md`](doc/art_bible/BLUEPRINT_VISUAL_MESTRE.md) §3. Isso fecha a lacuna racial dos Anões. Humanos, Elfos e Draconianos seguem no baseline v1.2.

1. **Humanos (Engenheiros de Sucata):**
   - *Materno:* Solda de Sobrevivência (Reparo de chassi aliado).
   - *Paterno:* Sobrecarga de Pistão (Dano massivo com coice).
2. **Anões (Metalurgia Pesada):**
   - *Materno:* Vapor de Arrefecimento (Evasão/Nuvem de vapor).
   - *Paterno:* Prensa Hidráulica (Postura defensiva inamovível +60%).
3. **Elfos (Engenheiros de Reator):**
   - *Materno:* Ressonância de Núcleo (Pulso de regeneração de EP coletivo).
   - *Paterno:* Corte de Centelha (Ataque elétrico ignorando 50% de armadura).
4. **Fadas (Mecânicas de Duto):**
   - *Materno:* Névoa Química (Cura de envenenamento e estresse em área).
   - *Paterno:* Injeção Pneumática (Jato de ar/pressão que repele inimigos).
5. **Draconianos (Forjadores de Alta Temperatura):**
   - *Materno:* Dissipador Térmico (Absorção e conversão de dano aliado).
   - *Paterno:* Sobrecarga Vulcânica (Explosão de fogo e área 360°).
6. **Lurídeos (Fluidez e Adaptação Subaquática):**
   - *Materno:* Cápsula de Pressão (Bolha de proteção hidráulica).
   - *Paterno:* Siphon Químico (Dreno de vida + terreno tóxico).

---

## 4. DIRETRIZES DE ARQUITETURA DE CÓDIGO (BACKEND STACK)
- **Linguagem:** TypeScript (Strict Mode).
- **Estrutura de Pastas:**
  - `src/core/`: Motores principais (`GameLoop.ts`, gerenciadores de estado e turnos).
  - `src/database/`: Módulos de dados estáticos para Raças, Habilidades e Items.
  - `src/mechanics/`: Regras de cálculo (Estafa, Dano, Modificadores).
  - `doc/` e `docs/`: Documentações de Design e Bíblia de Arte.
- **Princípios:** Código limpo, desacoplado, funções puras para cálculo de modificadores de combate e tratamento rigoroso de exceções.

---

## 5. GUIA CROMÁTICO E VISUAL (70 - 20 - 10)
- **70% Tons Base:** `#121214` (Preto-Carbono), `#1E222A` (Chumbo), `#2A2C30` (Cinza-Ferrugem).
- **20% Accents:** `#4A7C7A` (Cobre/Verdete), `#8C633E` (Bronze), `#A68052` (Latão).
- **10% Glow Emissivo:** `#39FF14` (Verde-Químico), `#FF7900` (Laranja-Incandescente), `#00E5FF` (Azul-Centelha).
