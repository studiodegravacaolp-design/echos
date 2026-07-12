# SYS-MANUFATURA-ENDGAME — Receitas Supremas do Ato 5
**Ato 5 (Níveis 46–50) — Catálogo de Receitas do Clímax**
**Status:** Documentação de Crafting do Endgame

---

## 1. EQP-ARM-051 — O Fuso do Veredito (Martelo Pesado)

| Propriedade | Valor |
|-------------|-------|
| **ID** | EQP-ARM-051 |
| **Nome** | O Fuso do Veredito |
| **Tipo** | Martelo Pesado (Arma Corpo a Corpo) |
| **Dano Base** | 150 |
| **Nível Requerido** | 48 |
| **Delta_M** | 0 |
| **Slot** | Arma Primária |

### Receita

| Componente | Quantidade |
|------------|------------|
| Fuso do Predador (EQP-ARM-013) | 1x |
| RES-FRAGMENTO-JUÍZO | 4x |
| RES-CINZA-VACUO | 3x |
| MGA (Moeda Geral de Aetheris) | 1200 |

### Habilidade Especial — Penetração de Armadura

**Ativa:** Consome **40 de Estafa Paterna** para garantir **100% de penetração de armadura** contra Abominações (MON-ERR-047) por **6 segundos**.

- Durante a ativação, todos os ataques ignoram a defesa física do alvo.
- O efeito se aplica exclusivamente a inimigos do tipo Abominação.
- Recarga da habilidade: 20 segundos.

### Notas de Crafting

- O Fuso do Predador (EQP-ARM-013) é obtido como drop de chefes do Ato 3.
- Os Fragmentos do Juízo são drops exclusivos do MON-ERR-047 e MON-ERR-BOSS-01.
- A Cinza do Vácuo é drop do MON-ERR-046.

---

## 2. EQP-ARM-052 — Couraça da Malha Estabilizada (Armadura Lendária)

| Propriedade | Valor |
|-------------|-------|
| **ID** | EQP-ARM-052 |
| **Nome** | Couraça da Malha Estabilizada |
| **Tipo** | Armadura de Torso (Lendária) |
| **Armadura** | +54 |
| **Nível Requerido** | 48 |
| **Delta_M** | 0 |
| **Slot** | Peitoral |

### Receita

| Componente | Quantidade |
|------------|------------|
| Couraça de Abafamento (EQP-ARM-021) | 1x |
| RES-CINZA-VACUO | 5x |
| RES-LIGA-CHUMBO | 2x |
| MGA (Moeda Geral de Aetheris) | 1500 |

### Efeito Passivo — Estabilização Térmica

**Retarda em 50% a velocidade do Colapso Termodinâmico ambiental.**

- O intervalo entre os ciclos de compressão dobra: de **3 turnos (15s) para 6 turnos (30s)**.
- O efeito é **multiplicativo** com REL-ONT-001 (Pêndulo Descalcificado):
  - Base: 3 turnos
  - Com REL-ONT-001: 6 turnos
  - Com EQP-ARM-052: 6 turnos (retardado em 50%)
  - Com ambos: 12 turnos (retardado em 50% sobre 6 turnos)

### Notas de Crafting

- A Couraça de Abafamento (EQP-ARM-021) é obtida no Ato 4 (ver SYS-MANUFATURA-ATO4).
- A Liga de Chumbo é um drop raro do MON-ERR-BOSS-01.
- Esta armadura é **recomendada** para jogadores que planejam combates prolongados contra o chefe final.

---

## 3. TABELA DE COMPONENTES — Drops do Ato 5

| Componente | Drop de | Raridade | Uso Principal |
|------------|---------|----------|---------------|
| RES-CINZA-VACUO | MON-ERR-046, MON-ERR-BOSS-01 | Comum | EQP-ARM-051, EQP-ARM-052 |
| RES-FRAGMENTO-JUÍZO | MON-ERR-047, MON-ERR-BOSS-01 | Incomum | EQP-ARM-051 |
| RES-LIGA-CHUMBO | MON-ERR-BOSS-01 | Raro | EQP-ARM-052 |

---

## 4. VISÃO GERAL DAS RECEITAS

| ID | Nome | Tipo | Dano / Armadura | Componentes | Custo MGA |
|----|------|------|-----------------|-------------|-----------|
| EQP-ARM-051 | O Fuso do Veredito | Martelo Pesado | Dano 150 | 1x EQP-ARM-013 + 4x RES-FRAGMENTO-JUÍZO + 3x RES-CINZA-VACUO | 1200 |
| EQP-ARM-052 | Couraça da Malha Estabilizada | Armadura Lendária | +54 Armadura | 1x EQP-ARM-021 + 5x RES-CINZA-VACUO + 2x RES-LIGA-CHUMBO | 1500 |

---

## 5. NOTAS DE BALANCEAMENTO

- Ambas as receitas requerem materiais obtidos exclusivamente no Ato 5, garantindo que sejam itens de endgame.
- O Fuso do Veredito é a arma de maior dano base do jogo (150), superando todas as armas dos Atos 1–4.
- A Couraça da Malha Estabilizada é a armadura com maior valor de armadura (+54) e o único item que retarda o Colapso Termodinâmico passivamente.
- A combinação de EQP-ARM-052 com REL-ONT-001 cria a configuração máxima de sustentação, permitindo combates de até 12 turnos antes da primeira compressão.

---

**Fim do Documento — SYS-MANUFATURA-ENDGAME.md**
**Versão 1.0 — Projeto Aetheris**