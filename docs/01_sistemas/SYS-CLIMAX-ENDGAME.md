# SYS-CLIMAX-ENDGAME — O Vértice do Veredito
**Ato 5 (Níveis 46–50) — Clímax da Campanha Base 1.0**
**Status:** Documentação de Regras Operacionais do Endgame

---

## 1. REGRA DE AMBIENTE — Colapso Termodinâmico

A instabilidade física da malha no Ato 5 impõe uma pressão temporal crescente sobre o jogador. O ambiente encolhe as margens de segurança da barra de Estafa a cada intervalo fixo, reduzindo os limites máximos seguros e apressando o disparo da Fratura.

### Mecânica do Colapso

| Ciclo | Intervalo (Turnos) | Intervalo (Segundos) | Limite Máximo Seguro (Novo) | Efeito |
|-------|-------------------|----------------------|----------------------------|--------|
| 0     | —                 | —                    | +100 / -100                | Estado inicial da barra |
| 1     | 3                 | 15                   | +95 / -95                  | Primeira compressão |
| 2     | 6                 | 30                   | +90 / -90                  | Segunda compressão |
| 3     | 9                 | 45                   | +85 / -85                  | Terceira compressão |
| n     | 3n                | 15n                  | +100 - (5n) / -100 + (5n)  | Progressão contínua |

- O Colapso é **cumulativo e irreversível** durante o combate.
- Quando o limite máximo seguro se iguala ao valor atual da barra, a Fratura é **automaticamente disparada**.
- Habilidades e relíquias podem **retardar ou anular temporariamente** o Colapso (ver seções abaixo).

---

## 2. GRIMÓRIO SUPREMO — SYS-HABILIDADES-ENDGAME

Disciplinas de teto técnico desbloqueadas no Ato 5. Representam o ápice do domínio do jogador sobre as três Estafas.

### SKL-NEU-050 — Ancoragem do Ponteiro Absoluto

| Propriedade | Valor |
|-------------|-------|
| **Elemento** | Terra |
| **Dano Base** | 150 |
| **Custo de Estafa** | 40 Neutra |
| **Tipo** | Ativa / Técnica Suprema |
| **Delta_M** | 0 |

**Efeito Primário:** Desfere um golpe de ancoragem que crava o Ponteiro Absoluto no campo de batalha.

**Congelamento Ontológico:** Trava a barra de Estafa de ambos os lados (jogador e monstro) por **6 segundos**. Durante este período:
- Nenhum dos lados pode acumular Estafa ativa ou passivamente.
- O Colapso Termodinâmico ambiental é **anulado** (não avança nem encolhe os limites).
- Habilidades que consomem Estafa não podem ser usadas (a barra está congelada).
- Delta_M = 0 permanente durante a duração.

**Sinergia Crítica:** Combinada com REL-ONT-003 (Chassi Estático Primordial), o Congelamento Ontológico se estende para **8 segundos** e o dano é dobrado para **300**.

---

### SKL-PAT-045 — Sobrecarga do Fuso Crônico

| Propriedade | Valor |
|-------------|-------|
| **Elemento** | Fogo |
| **Dano Base** | 180 |
| **Custo de Estafa** | 35 Paterna (+25 adicional na faixa crítica) |
| **Tipo** | Ativa / Técnica de Ruptura |
| **Delta_M** | Variável |

**Efeito Primário:** Canaliza o Fuso Crônico para sobrecarregar o alvo com energia temporal desestabilizada.

**Disparo na Faixa Crítica:** Se o jogador estiver na faixa de Estafa Paterna entre **+61 e +99** no momento da ativação:
- Consome **+25 de Delta_M Paterno** adicional (total efetivo de 60 de custo).
- Injeta **+25 de Delta_M Paterno diretamente na barra do monstro alvo**.
- Força o deslocamento imediato da barra do monstro em direção à Fratura.

**Risco:** Se a barra do jogador estiver abaixo de +61, a habilidade falha e consome apenas o custo base de 35, sem efeito adicional.

---

### SKL-MAT-045 — Dilatação do Limiar de Quebra

| Propriedade | Valor |
|-------------|-------|
| **Elemento** | Luz |
| **Escudo Gerado** | 120 |
| **Custo de Estafa** | 30 Materna |
| **Tipo** | Ativa / Técnica Defensiva |
| **Delta_M** | 0 |

**Efeito Primário:** Ergue um escudo de luz que dilata o limiar de tolerância do jogador.

**Propriedade "Hackear a Massa Abafadora":** Se o monstro alvo colapsar em Fratura enquanto o escudo estiver ativo:
- Cancela a animação de ejeção de chumbo (reduzindo o tempo perdido).
- Expande a janela útil de dano livre do jogador de **4 para 5 segundos globais cheios**.
- O escudo é consumido no processo.

**Nota Técnica:** Esta habilidade é essencial para maximizar o DPS na janela de Massa Abafadora do chefe final (MON-ERR-BOSS-01).

---

## 3. AS RELÍQUIAS ONTOLÓGICAS — SYS-EQUIP-RELICS

Slot único e excludente. Apenas **uma** relíquia ontológica pode estar equipada por vez. A escolha define a estratégia de endgame do jogador.

### REL-ONT-001 — Pêndulo Descalcificado (Paterno)

| Propriedade | Valor |
|-------------|-------|
| **Tipo** | Relíquia Ontológica — Paterna |
| **Slot** | Único / Excludente |
| **Requisito** | Nível 46+ |

**Efeitos:**
1. **Retardo do Colapso Termodinâmico:** O ambiente encolhe as margens a cada **6 turnos** (em vez de 3), dobrando o tempo disponível antes da compressão.
2. **Amplificação Crítica:** Converte **20% da Estafa Paterna acima de +61** em amplificação crítica para o próximo ataque.
   - Exemplo: Com +80 de Estafa Paterna, 20% de (80 - 61) = 3.8 → +3.8% de chance crítica acumulada.

**Estilo de Jogo:** Sustentação prolongada e buildup crítico. Ideal para jogadores que preferem combates mais longos e controle fino da barra.

---

### REL-ONT-002 — Lente Prismathica Invertida (Materno)

| Propriedade | Valor |
|-------------|-------|
| **Tipo** | Relíquia Ontológica — Materna |
| **Slot** | Único / Excludente |
| **Requisito** | Nível 46+ |

**Efeitos:**
1. **Imunidade a Silêncio e Trava de Eixo:** O jogador não pode ser silenciado nem ter seu eixo de Estafa travado por inimigos (anula a IA "Trava de Eixo" do MON-ERR-047).
2. **Ressurgência da Estagnação:** Ao atingir **-100 (Estagnação)**:
   - Consome o escudo ativo (se houver) para zerar a barra instantaneamente.
   - Dispara uma cura em área que restaura **30% do HP máximo** de todos os aliados.

**Estilo de Jogo:** Suporte e resiliência. Ideal para jogadores que operam na faixa Materna e enfrentam inimigos com controle de Estafa.

---

### REL-ONT-003 — Chassi Estático Primordial (Neutro Absoluto)

| Propriedade | Valor |
|-------------|-------|
| **Tipo** | Relíquia Ontológica — Neutra Absoluta |
| **Slot** | Único / Excludente |
| **Requisito** | Nível 48+ |

**Efeitos:**
1. **Anulação de Flutuações Dinâmicas:** Anula todas as flutuações dinâmicas de início de turno nos Atos 4 e 5. A barra inicia cada turno exatamente onde terminou no turno anterior.
2. **Potencialização Técnica do Elemento Terra:**
   - Dobra a eficácia mecânica e o dano de **todas as técnicas do elemento Terra**.
   - Delta_M = 0 garantido para estas técnicas.
   - Afeta inclusive SKL-NEU-050 (Ancoragem do Ponteiro Absoluto), que passa a causar 300 de dano e ter 8s de Congelamento Ontológico.

**Estilo de Jogo:** Precisão máxima e neutralidade. Ideal para a build Neutra Máxima e jogadores que buscam o controle absoluto da barra.

---

## 4. TABELA DE COMPATIBILIDADE — RELÍQUIAS × HABILIDADES SUPREMAS

| Relíquia | SKL-NEU-050 | SKL-PAT-045 | SKL-MAT-045 | Colapso Termodinâmico |
|----------|-------------|-------------|-------------|----------------------|
| REL-ONT-001 | Sem sinergia direta | Amplificação crítica potencializada | Sem sinergia direta | Retardado (6 turnos) |
| REL-ONT-002 | Sem sinergia direta | Sem sinergia direta | Escudo preservado na Ressurgência | Sem efeito |
| REL-ONT-003 | Dano 300 / 8s Congelamento | Sem sinergia direta | Sem sinergia direta | Anulação de flutuações |

---

## 5. NOTAS DE BALANCEAMENTO

- O Colapso Termodinâmico foi projetado para tornar o Ato 5 intrinsecamente mais difícil que os atos anteriores, exigindo gerenciamento ativo da barra.
- As Relíquias Ontológicas são **mutuamente excludentes** para forçar escolhas estratégicas significativas.
- A build Neutra Máxima (REL-ONT-003 + SKL-NEU-050) é a mais versátil, mas sacrifica as vantagens especializadas das outras relíquias.
- Nenhuma combinação de relíquias e habilidades pode **reverter** o Colapso Termodinâmico — apenas retardá-lo ou anulá-lo temporariamente.

---

**Fim do Documento — SYS-CLIMAX-ENDGAME.md**
**Versão 1.0 — Projeto Aetheris**