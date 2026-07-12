# ART-BIBLIA-INTERFACE
## Capítulo 4 — Linguagem Visual das Interfaces
### Projeto Aetheris — RPG de Sistemas Mecânico-Ontológicos Mobile
**Status:** Cânone Travado — v2.0.0

---

## 1. Medidor da Balança de Estafa (HUD Central)

### 1.1 Disposição Física
- **Forma:** Arco ou linha horizontal mecânica de alto contraste.
- **Posição:** Base da tela mobile, na zona de acessibilidade do polegar (thumb zone inferior).
- **Movimento do Ponteiro:** Exclusivamente analógico — deslocamento rústico, sem transições suaves digitais. Cada variação de tensão moral deve ser sentida como um deslocamento físico de engrenagens.

### 1.2 Estado Paterno (+) — Ember
- Quando o jogador pende para o polo Paterno (+), o indicador exala **estática de brasa (Ember)**.
- Efeito visual: partículas incandescentes laranja-avermelhadas tremeluzindo ao redor do ponteiro, simulando carvão em combustão lenta.
- Nenhum brilho suave ou gradiente — apenas faíscas secas e agressivas.

### 1.3 Estado Materno (−) — Dourado Prismathico
- Quando o jogador pende para o polo Materno (−), o indicador exibe **linhas circulares concêntricas (Dourado Prismathico)**.
- Efeito visual: anéis concêntricos dourados pulsando em frequência baixa, irradiando do centro do arco.
- Transmissão de calma geometria sagrada — oposto visual ao Ember.

### 1.4 Estado Neutro (0) — Acromático
- Em zero absoluto, o chassi do medidor permanece **fosco (Acromático)**.
- Ausência total de partículas, anéis ou incandescência.
- A interface repousa em cinza-chumbo inerte, sem qualquer sinalizador de ativação.

---

## 2. Alerta de Fratura de Frenesi (+100)

### 2.1 Ativação
- Quando o limiar de +100 é atingido, toda a **moldura da UI de combate** é imediatamente transformada.

### 2.2 Efeito de Moldura
- As bordas sofrem um **efeito estático de linhas tremeluzentes** — como interferência de sinal analógico corrompido.
- A moldura é preenchida por uma **incandescência de metal líquido (Ember)**: ouro-brasa derretido escorrendo pelas bordas da tela.

### 2.3 Cronômetro da Janela Útil — Massa Abafadora (4 segundos)
- Um cronômetro de **4 segundos** (Massa Abafadora) deve **piscar em contagem regressiva severa e analógica**.
- O cronômetro sobrepõe-se a **todas as demais ações** em primeiro plano absoluto.
- Estilo: mostrador mecânico-digital rústico, algarismos grossos, sem serifa, piscando em vermelho-ember sobre fundo preto.
- A cada segundo decorrido, o algarismo treme como um relógio analógico prestes a quebrar.

---

## 3. Alerta de Estagnação Tática (−100)

### 3.1 Ativação
- Quando o limiar de −100 é atingido, a interface de combate sofre paralisia visual completa.

### 3.2 Efeitos Visuais
- **Barra de habilidades rúnicas:** Congela visualmente. Nenhum ícone pode ser selecionado ou pressionado.
- **Opacidade cinza-chumbo fosca:** Toda a área tática é coberta por uma camada de opacidade densa, transmitindo asfixia e peso material.
- **Ícones:** Permanecem visíveis mas inertes, como ferramentas petrificadas.
- Ausência total de brilho, pulsação ou qualquer indicador de vida na interface.

---

## 4. Legibilidade Mobile e Toque

### 4.1 Geometria de Contraforte
- **Botões de comando** usam exclusivamente a **Geometria de Contraforte**:
  - Retângulos pesados
  - Trapézios
  - Ângulos retos
- **Proibido** o uso de:
  - Ícones flutuantes arredondados
  - Neon digital cyberpunk
  - Cantos arredondados suaves
  - Sombras difusas ou glow excessivo

### 4.2 Paleta de Cores (Regra 70/30)
- **70% — Tons de Opressão Dessaturados:**
  - Cinza Chumbo (#3A3A3A, #4F4F4F)
  - Ferrugem (#6B3A2A, #8B4513)
  - Asfalto (#2C2C2C, #1A1A1A)
- **30% — Sinalizadores de Ativação:**
  - Ember (#FF4500, #DC143C, #FF6347) — para estados Paterno/Frenesi
  - Dourado Prismathico (#DAA520, #FFD700, #B8860B) — para estados Materno

### 4.3 Princípio de Destaque Instantâneo
- Os tons de opressão (70%) servem como tela fosca para que os sinalizadores de ativação (30%) **se destaquem instantaneamente**.
- Nunca mais de 30% da tela pode conter cores vibrantes em estado de repouso.
- Em estado de alerta (+100 ou −100), os sinalizadores podem ocupar até 60% da tela, mas nunca o fundo completo.

---

## 5. Hierarquia de Layout (Mobile Vertical)

```
┌─────────────────────────────────────┐
│         Status Secundário           │  ← 10% da tela (topo)
│   (HP, MP, buffs, debuffs)          │
├─────────────────────────────────────┤
│                                     │
│         ÁREA DE COMBATE             │  ← 55% da tela (centro)
│   (Animação, inimigos, cenário)     │
│                                     │
├─────────────────────────────────────┤
│                                     │
│      HABILIDADES RÚNICAS            │  ← 20% da tela (meio-base)
│   (4-6 slots, geometria angular)    │
│                                     │
├─────────────────────────────────────┤
│                                     │
│   BALANÇA DE ESTAFA (HUD Central)   │  ← 15% da tela (base)
│   (Arco horizontal, thumb zone)     │
│                                     │
└─────────────────────────────────────┘
```

---

## 6. Regras de Animação

| Elemento | Transição | Duração | Easing |
|----------|-----------|---------|--------|
| Ponteiro da Balança | Analógico rústico | 0.3s–0.6s | Step / Linear |
| Partículas Ember | Faíscas aleatórias | 0.1s–0.4s | None (discreto) |
| Anéis Dourados | Expansão concêntrica | 1.0s–2.0s | Ease-out |
| Moldura Frenesi | Tremulação estática | 0.05s (frame) | N/A |
| Cronômetro 4s | Piscar severo | 1.0s por segundo | Step |
| Congelamento −100 | Fade para opacidade | 0.5s | Ease-in |
| Botões (pressionar) | Recuo angular seco | 0.1s | Step |

---

## 7. Proibições Absolutas

1. **Proibido** qualquer elemento de interface flutuante com cantos arredondados.
2. **Proibido** gradientes suaves como transição de estado — apenas cortes secos.
3. **Proibido** uso de azul elétrico, rosa neon, ou qualquer cor ciano digital.
4. **Proibido** animações de transição com duração superior a 0.6s (exceto anéis dourados).
5. **Proibido** sombras projetadas com blur — usar apenas sombras duras (hard shadows).
6. **Proibido** sobreposição de mais de 2 elementos transparentes simultaneamente.
7. **Proibido** ocupar mais de 30% da tela com sinalizadores de ativação em estado de repouso.

---

## 8. Checklist de Conformidade de Interface

- [ ] Medidor da Balança está na base da tela (thumb zone)?
- [ ] Ponteiro usa movimento analógico sem transições suaves?
- [ ] Ember usa apenas partículas de brasa seca (sem glow)?
- [ ] Dourado usa linhas concêntricas (sem gradiente)?
- [ ] Neutro é totalmente fosco?
- [ ] Moldura Frenesi tem tremulação estática e metal líquido?
- [ ] Cronômetro de 4s sobrepõe todas as ações?
- [ ] −100 aplica opacidade cinza-chumbo e congela ícones?
- [ ] Botões seguem Geometria de Contraforte?
- [ ] Paleta segue regra 70/30 (opressão/sinalizadores)?
- [ ] Nenhum ícone arredondado ou neon cyberpunk?
- [ ] Hierarquia de layout respeita proporções definidas?

---

*Fim do Capítulo 4 — Linguagem Visual das Interfaces*
*Próximo: Capítulo 5 — Design de Som e Identidade Auditiva*