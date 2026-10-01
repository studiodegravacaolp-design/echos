# ECHOES OF THE SOUL — SAVE MIGRATION POLICY (Decision Record)

> **Status:** **DECIDIDO — OPTION B — OPT-IN MIGRATION** (aprovado no Bloco C10). A conversão
> ainda **não está implementada**: esta decisão define como ela deverá funcionar.
> **Origem:** Blocos C9 (opções) e C10 (decisão) · **Relacionados:** [C8](BLOCK_C8_V2_ADOPTION_AND_OPERATIONAL_SAVE.md) §8 · [C9](BLOCK_C9_ADOPTION_READINESS.md) §5 · [C10](BLOCK_C10_ADOPTION_HARDENING.md)

---

## 1. Formatos

| | OLD SAVE — formato **legado** | V2 SAVE — formato **atual** |
|---|---|---|
| Arquivo | `user://echoes_of_the_soul_save.json` | `user://echoes_of_the_soul_save_v2_shadow.json` (slot único `current`) |
| Escrito por | `SaveService` (Ctrl+S com flag OFF) | `SaveV2Service` (sombra C2, ou Ctrl+S com flag ON) |
| Forma | `{"version": 2, "language", "world", "quests", "player"}` | envelope `{checksum, format, game_version, metadata, schema_version: 2, state}` |
| Integridade | nenhuma | checksum SHA-256 + validação de contrato + escrita atômica |
| Conteúdo | flags, values, memories (misturadas com consequências), quests, player | GameState canônico: player, world, consequences, observations, quests, dialogue, memory, NPCs |
| Diálogo | **não grava** | grava (concluídos + última escolha) |
| Load | `SaveService.load_game` — aborta em `save_service.gd:44` antes de quests e Player | Load V2 com rehearsal, snapshot e rollback |

**Detecção**, feita por `SaveV2PersistenceInventory`, que é somente leitura:

- **legado:** JSON com `"version"` e `"world"`/`"quests"`, sem `"format"`;
- **V2:** `format = echoes_of_the_soul_save` e validação completa do C1;
- **confusão de formatos:** um envelope V2 no caminho legado é identificado e não é tratado como
  legado;
- **ilegível:** "não reconhecido".

Os dois arquivos vivem em caminhos distintos.

## 2. Situação atual (depois do C9)

1. Saves antigos continuam legíveis pelo caminho antigo (flag de load OFF), com o bug conhecido.
2. O V2 não lê, não modifica, não sobrescreve, não converte e não apaga saves antigos (testado com
   arquivos sentinela).
3. Com a flag de load ON e só um save antigo existente, o jogador é informado:
   *"Só existe um jogo salvo no formato antigo; ele não é carregado neste modo."*
4. Não há migração nem migrator.

**Cenários de instalação:**

- **A. Só save antigo.** Com as flags OFF, nada muda. Com as flags ON, o jogador não consegue carregar
  o progresso antigo pelo Ctrl+L até existir uma política.
- **B. Save antigo + V2.** Com as flags OFF, o Ctrl+L carrega o antigo e o Ctrl+S grava o antigo mais
  a sombra V2. Com as flags ON, só o V2. Os dois arquivos podem representar **pontos diferentes do
  jogo**; hoje nada indica ao jogador qual é o mais recente.

## 3. Opções

### A. Migração automática

Ao iniciar ou carregar, se só existir o save antigo, converter para V2 sem perguntar (mantendo o
original).

- **Vantagens:** transparente para o jogador; o progresso antigo continua acessível com as flags ON.
- **Riscos:**
  - migração **silenciosa**, contrária à política adotada até o C8;
  - o save antigo pode estar incompleto por causa do bug de `save_service.gd:44`, que afeta só o load;
  - o formato antigo mistura memórias e consequências e não tem diálogo, então o resultado seria um V2
    com lacunas "legítimas";
  - não há checksum no legado para confirmar integridade.
- **Impacto:** alto. Muda o comportamento de todas as instalações de uma vez.
- **Dependências:**
  - migrator sobre `GameStateMigrator.migrate_legacy_payload` (A2);
  - regra para os dados em quarentena;
  - decisão sobre diálogo ausente;
  - testes com saves reais antigos;
  - nunca sobrescrever o V2 existente (cenário B).

### B. Migração opt-in

O jogador escolhe converter ("Encontramos um jogo salvo no formato antigo. Converter?"). O original é
mantido.

- **Vantagens:** nada silencioso; o jogador controla; dá para mostrar um resumo do que será convertido
  e das perdas (diálogo, quarentena); permite desfazer mantendo o original.
- **Riscos:**
  - exige UI nova (fora do escopo até o C9);
  - no cenário B o jogador precisa escolher entre dois pontos do jogo;
  - mais caminhos de teste.
- **Impacto:** médio. Afeta só quem tem save antigo e aceita.
- **Dependências:**
  - o mesmo migrator da opção A;
  - UI de confirmação localizada;
  - regra de conflito com um V2 existente;
  - relatório de migração (o que foi convertido e o que foi para quarentena).

### C. Encerramento do legado

Não migrar. Em uma versão futura, o caminho antigo é removido e os saves antigos deixam de ser
carregáveis. O arquivo não é apagado.

- **Vantagens:** a manutenção mais simples; elimina o bug de `save_service.gd:44` sem corrigi-lo; um
  único formato.
- **Riscos:** perda de progresso para quem só tem save antigo; exige comunicação clara
  (aviso/changelog).
- **Impacto:** alto para jogadores com saves antigos; baixo para o código.
- **Dependências:**
  - flags ON por padrão (critérios em C9 §9);
  - aviso ao jogador (a mensagem "formato antigo" já existe);
  - período de convivência definido;
  - decidir se o arquivo antigo fica no disco.

## 4. Pontos comuns a qualquer opção

- Nunca apagar nem sobrescrever o save antigo sem ação explícita do jogador.
- Nunca sobrescrever um V2 existente com o resultado de uma migração.
- Todo resultado de migração passa pelo mesmo pipeline do Load V2 (validação, rehearsal) antes de valer.
- O bug de `save_service.gd:44` afeta o **load** antigo, não o arquivo. Uma migração lê o arquivo
  diretamente pelo migrator do A2, sem usar `SaveService.load_game`.

## 5. Decisão

| Campo | Valor |
|---|---|
| Opção escolhida | **OPTION B — OPT-IN MIGRATION** |
| Decidido por | usuário/responsável do projeto (aprovação registrada no Bloco C10) |
| Data | 2026-09-27 |
| Justificativa | nenhuma migração silenciosa; o jogador controla; o save antigo é preservado; permite informar perdas conhecidas (diálogo ausente, dados em quarentena) antes de converter |

### 5.1 Regras da opção B

```
OLD SAVE ─► detectado (SaveV2PersistenceInventory) ─► jogador pergunta/decide ─► converter SOMENTE com consentimento explícito
```

1. **Nenhuma migração automática.** Nada converte saves antigos sem ação explícita do jogador.
2. **Nenhum save antigo é sobrescrito, movido ou apagado** — nem pela migração.
3. **Nenhuma migração ocorre silenciosamente** — o jogador vê o que será convertido e o que não pode ser (diálogo ausente no formato legado, dados em quarentena).
4. **O jogador pode continuar usando o caminho legado** (flags OFF) enquanto ele existir.
5. **A futura migração será explícita** e usará os contratos existentes do A2 (`GameStateMigrator.migrate_legacy_payload`), lendo o arquivo diretamente — nunca `SaveService.load_game` (bug de `save_service.gd:44`).
6. O resultado da conversão nunca sobrescreve um V2 existente sem nova confirmação, e passa pelo mesmo pipeline do Load V2 (validação + rehearsal) antes de valer.

### 5.2 Estado da implementação

| Item | Estado |
|---|---|
| Detecção do save antigo | **existe** (C9 — `SaveV2PersistenceInventory`, somente leitura) |
| Aviso ao jogador ("só existe save no formato antigo") | **existe** (C9 — mensagem localizada no Load V2) |
| Pergunta/consentimento | **não implementado** (bloco futuro; exige UI de confirmação) |
| Conversão | **não implementada**; **nenhum migrator novo criado** |

### 5.3 Atualização C10.5 — V2 é o caminho padrão

Por decisão do usuário após o playtest humano, `SAVE_V2_OPERATIONAL_LOAD/SAVE_ENABLED` passaram a **true**
por padrão. Consequência para esta política: um save **antigo** não é carregado pelo Ctrl+L padrão — o
jogador vê *"Só existe um jogo salvo no formato antigo; ele não é carregado neste modo."*. O caminho
legado continua no código e só roda com as flags desligadas explicitamente (`SaveV2OperationalConfig.create(false, …, false)`).
A conversão continua **opt-in e não implementada**; nada é migrado, sobrescrito ou apagado.
