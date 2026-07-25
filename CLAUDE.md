# AETHERIS — Instruções de Trabalho do Projeto

## Regra de Documentação Contínua (obrigatória)
**Atualize o [`PROJECT_CHANGELOG.md`](PROJECT_CHANGELOG.md) no MESMO commit de cada feature, refatoração ou correção.**

- Código e documentação evoluem em **commits atômicos** — nunca separe a atualização do changelog em outro commit.
- Antes de commitar uma entrega:
  1. Adicione uma entrada no topo de **"🗓️ Histórico de Entregas & Modificações"** (newest-first): data, hash (quando já conhecido), o que foi implementado e o resultado dos testes.
  2. Ajuste o **"📊 Resumo do Estado do Sistema"** se o estado mudou.
  3. `git add PROJECT_CHANGELOG.md` junto dos arquivos da tarefa e commite tudo junto.
- Observação: o hash do próprio commit só existe após commitar — referencie como "HEAD"/subsequente, ou use `git commit --amend` para inserir o hash quando fizer diferença.

## Convenções técnicas
- **TypeScript strict**; validação de cada entrega: `npx tsc --noEmit` + execução das suites afetadas via `npx tsx src/test/<suite>.test.ts`.
- Testes usam harness nativo (`assert` + relatório), sem framework externo.
- Documentação-fonte: [`AETHERIS_MASTER_INDEX.md`](AETHERIS_MASTER_INDEX.md), [`docs/mechanics/ESTAFA_SYSTEM.md`](docs/mechanics/ESTAFA_SYSTEM.md).
