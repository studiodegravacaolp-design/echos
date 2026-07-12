# SYS-BESTIARIO-ENDGAME — Ameaças Terminais do Ato 5
**Ato 5 (Níveis 46–50) — Catálogo de Inimigos e IA do Chefe Final**
**Status:** Documentação de Combate do Endgame

---

## 1. MON-ERR-046 — Cinza Errante do Vácuo

| Propriedade | Valor |
|-------------|-------|
| **ID** | MON-ERR-046 |
| **Nome** | Cinza Errante do Vácuo |
| **HP** | 1100 |
| **Nível Mínimo** | 46 |
| **Tipo** | Aberração do Vácuo |
| **R_Estafa** | 1.2 |
| **Drop** | RES-CINZA-VACUO |

### Comportamento

- **Movimentação:** Flutua erraticamente pelo campo, alternando entre aproximação e recuo.
- **Ataque Primário:** Dispara projéteis de cinza do vácuo que causam dano médio (40–60).
- **Debuff Passivo:** Cada acerto aplica uma marca de **+20% no acúmulo de Estafa passiva do jogador** por 8 segundos.
  - Efeito cumulativo: múltiplos acertos aumentam a taxa de acúmulo em progressão aditiva (+20%, +40%, +60%...).
  - O debuff expira 8 segundos após o último acerto recebido.

### Estratégia Recomendada

- Priorizar eliminação rápida para evitar acúmulo excessivo do debuff.
- Usar habilidades de interrupção para negar os projéteis.
- A REL-ONT-001 (Pêndulo Descalcificado) mitiga o risco ao retardar o Colapso Termodinâmico.

---

## 2. MON-ERR-047 — Sentinela do Ponteiro Cego

| Propriedade | Valor |
|-------------|-------|
| **ID** | MON-ERR-047 |
| **Nome** | Sentinela do Ponteiro Cego |
| **HP** | 1350 |
| **Nível Mínimo** | 47 |
| **Tipo** | Abominação |
| **R_Estafa** | 1.5 |
| **Drop** | RES-FRAGMENTO-JUÍZO |

### Comportamento

- **Movimentação:** Estacionária. A Sentinela não se move, mas possui um campo de alcance de 15 metros.
- **Ataque Primário:** Disparo de energia cega que causa dano alto (70–90).
- **IA "Trava de Eixo":** A cada 10 segundos, a Sentinela emite um pulso que **bloqueia o uso de Catalisadores de Estafa por 4 segundos**.
  - Catalisadores de Estafa incluem: itens consumíveis que alteram a barra, habilidades de terceiros que manipulam Estafa, e qualquer fonte externa de Delta_M.
  - Habilidades próprias do jogador (como SKL-NEU-050) **não** são afetadas.
  - O pulso tem um indicador visual (anel de energia se expandindo) que permite ao jogador desviar.

### Estratégia Recomendada

- A REL-ONT-002 (Lente Prismathica Invertida) concede **imunidade total** à Trava de Eixo.
- Manter distância e usar ataques à distância.
- Quebrar a Sentinela rapidamente para eliminar a fonte do pulso.

---

## 3. MON-ERR-BOSS-01 — O Juízo da Balança (Chefe Final)

| Propriedade | Valor |
|-------------|-------|
| **ID** | MON-ERR-BOSS-01 |
| **Nome** | O Juízo da Balança |
| **HP** | 18500 |
| **Nível Mínimo** | 50 |
| **Tipo** | Entidade Ontológica / Chefe Final |
| **R_Estafa** | 2.0 |
| **Drop** | RES-FRAGMENTO-JUÍZO (5–8), RES-CINZA-VACUO (3–5), RES-LIGA-CHUMBO (1–2) |

### IA "Paradoxo de Sincronia"

O Juízo da Balança opera com uma inteligência artificial reativa de alto nível que monitora o estado da barra de Estafa do jogador em tempo real.

**Mecânica:**
1. A cada **3 segundos**, a IA avalia o Delta_M de curto prazo do jogador (média dos últimos 2 segundos).
2. Se o Delta_M for **positivo** (tendência Paterna), o Juízo descarrega um ataque de **polo Materno** (empurrando a barra do jogador para o lado negativo).
3. Se o Delta_M for **negativo** (tendência Materna), o Juízo descarrega um ataque de **polo Paterno** (empurrando a barra do jogador para o lado positivo).
4. Se o Delta_M for **zero** (neutro), o Juízo executa um ataque de **polo equilibrado** que causa dano físico puro (100–120) sem alterar a barra.

**Implicação Tática:** O jogador não pode manter uma tendência estável por muito tempo sem ser contra-atacado. A alternância constante entre os polos é necessária para evitar o contra-ataque especializado.

### Fases do Combate

| Fase | HP Restante (%) | Comportamento Adicional |
|------|-----------------|------------------------|
| 1    | 100% – 51%      | IA "Paradoxo de Sincronia" padrão. Ataques básicos alternados. |
| 2    | 50% – 21%       | IA acelera para avaliação a cada **2 segundos**. Ataques causam +25% de dano. |
| 3    | 20% – 0%        | IA acelera para avaliação a cada **1 segundo**. Ataques causam +50% de dano. Surge padrão adicional de projéteis de cinza. |

### Massa Abafadora

Quando o HP do Juízo da Balança chega a **0%**, a seguinte sequência é disparada:

1. **Animação de Ejeção de Chumbo (1 segundo):** O chefe ejeta todo o chumbo acumulado em uma animação visual. O jogador não pode agir.
2. **Janela Útil de Ataque (4 segundos):** O chefe fica vulnerável e imóvel. O jogador pode causar dano livre sem restrições.
   - Com SKL-MAT-045 (Dilatação do Limiar de Quebra) ativa no momento do colapso, esta janela se expande para **5 segundos**.
3. **Reativação:** Após a janela, o chefe se reergue com **20% do HP máximo** (3700 HP) e retorna à Fase 3.

**Ciclo de Quebra:** O chefe precisa ser quebrado **3 vezes** para ser definitivamente derrotado. A cada quebra:
- 1ª Quebra: Fase 2 → Fase 3 (HP resetado para 20%).
- 2ª Quebra: Fase 3 → Fase 3 (HP resetado para 20%).
- 3ª Quebra: Derrota permanente. Cutscene de encerramento.

---

## 4. TABELA DE DROPS

| Inimigo | Drop 1 (Comum) | Drop 2 (Raro) | Drop 3 (Lendário) |
|---------|---------------|---------------|-------------------|
| MON-ERR-046 | RES-CINZA-VACUO (1–2) | — | — |
| MON-ERR-047 | RES-FRAGMENTO-JUÍZO (1–2) | — | — |
| MON-ERR-BOSS-01 | RES-FRAGMENTO-JUÍZO (5–8) | RES-CINZA-VACUO (3–5) | RES-LIGA-CHUMBO (1–2) |

---

## 5. NOTAS DE BALANCEAMENTO

- O MON-ERR-BOSS-01 é projetado para ser o teste final de maestria do sistema de Estafa. Jogadores que dominam a alternância de polos terão vantagem significativa.
- A Massa Abafadora com 3 ciclos de quebra garante que o combate seja uma maratona, não um sprint.
- A combinação de REL-ONT-002 (imunidade a Trava de Eixo) e SKL-MAT-045 (janela expandida) é a configuração defensiva ideal para este combate.
- A build Neutra Máxima (REL-ONT-003 + SKL-NEU-050) permite ignorar o Paradoxo de Sincronia durante o Congelamento Ontológico, criando janelas de dano seguro.

---

**Fim do Documento — SYS-BESTIARIO-ENDGAME.md**
**Versão 1.0 — Projeto Aetheris**