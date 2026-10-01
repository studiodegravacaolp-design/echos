# ECHOES OF THE SOUL — C10 HUMAN PLAYTEST CHECKLIST (Save/Load V2)

> **Status:** **NÃO EXECUTADO.** Este é um checklist para uma pessoa jogar e preencher manualmente.
> Nenhum item foi marcado automaticamente. Os playtests do C9 e do C10 foram **automatizados** e **não
> substituem** este teste.
> **Relacionados:** [C10](BLOCK_C10_ADOPTION_HARDENING.md) · [C9](BLOCK_C9_ADOPTION_READINESS.md)

---

## 0. Preparação

> **Atualização C10.5:** a primeira rodada deste checklist rodou **sem** as flags ligadas (o Ctrl+L
> caiu no load legado e o debugger do editor pausou no erro de `save_service.gd:44`). Desde o C10.5 o
> **V2 é o caminho padrão**: não é preciso editar código. Basta abrir o projeto no Godot 4.7.1 e rodar a
> cena principal (F5). Ctrl+S/Ctrl+L usam somente o Save/Load V2.

**Observações:**

- Com o V2 (padrão), o Ctrl+S grava só o V2, em `user://echoes_of_the_soul_save_v2_shadow.json`. O
  save antigo (`user://echoes_of_the_soul_save.json`) não é tocado.
- Para o Teste 10 (arquivo inválido), faça **antes** uma cópia do arquivo V2. `user://` fica em
  `%APPDATA%/Godot/app_userdata/Echoes of The Souls/`.
- Teclas: WASD/setas movem, E interage, Ctrl+S salva, Ctrl+L carrega.

## Como registrar

Para cada item, marque **PASS**, **FAIL** ou **NOT TESTED**. Em caso de FAIL, descreva no fim do
documento o passo, o comportamento esperado, o comportamento observado e, se tiver, uma captura de tela.

| Resultado | Significado |
|---|---|
| PASS | comportamento esperado observado |
| FAIL | comportamento diferente do esperado (descrever) |
| NOT TESTED | não executado |

---

## TESTE 1 — INÍCIO

| # | Passo | Resultado |
|---|---|---|
| 1.1 | abrir o jogo | NOT TESTED |
| 1.2 | mover o personagem | NOT TESTED |
| 1.3 | falar com Durn (o nome "Durn" aparece na caixa de diálogo) | NOT TESTED |
| 1.4 | iniciar a quest | NOT TESTED |

## TESTE 2 — SAVE

| # | Passo | Resultado |
|---|---|---|
| 2.1 | salvar V2 (Ctrl+S) | NOT TESTED |
| 2.2 | ver a mensagem de sucesso ("Jogo salvo.", destacada, some sozinha) | NOT TESTED |
| 2.3 | continuar jogando | NOT TESTED |

## TESTE 3 — LOAD

| # | Passo | Resultado |
|---|---|---|
| 3.1 | mudar de posição | NOT TESTED |
| 3.2 | carregar V2 (Ctrl+L) | NOT TESTED |
| 3.3 | voltar à posição salva (a câmera acompanha o personagem) | NOT TESTED |
| 3.4 | ver a mensagem de sucesso ("Jogo carregado.") | NOT TESTED |

## TESTE 4 — ANTES DO ECO

| # | Passo | Resultado |
|---|---|---|
| 4.1 | salvar antes do Eco | NOT TESTED |
| 4.2 | resolver o Eco | NOT TESTED |
| 4.3 | alterar o mundo (examinar observações, mover-se) | NOT TESTED |
| 4.4 | carregar | NOT TESTED |
| 4.5 | confirmar o visual anterior ao Eco; nenhum painel do estado desfeito continua na tela | NOT TESTED |

Verificar:

| # | Item | Resultado |
|---|---|---|
| 4.a | esfera (visível de novo) | NOT TESTED |
| 4.b | luz | NOT TESTED |
| 4.c | ambiente (sem reação pós-Eco) | NOT TESTED |
| 4.d | banner (não aparece) | NOT TESTED |
| 4.e | observações (não descobertas) | NOT TESTED |
| 4.f | quest (ativa, objetivo "Investigue…") | NOT TESTED |
| 4.g | posição | NOT TESTED |

## TESTE 5 — DEPOIS DO ECO

| # | Passo | Resultado |
|---|---|---|
| 5.1 | resolver o Eco | NOT TESTED |
| 5.2 | registrar a memória | NOT TESTED |
| 5.3 | descobrir uma observação | NOT TESTED |
| 5.4 | salvar | NOT TESTED |
| 5.5 | alterar o mundo | NOT TESTED |
| 5.6 | carregar | NOT TESTED |
| 5.7 | confirmar o estado pós-Eco (esfera oculta, banner, ambiente, observação) | NOT TESTED |

## TESTE 6 — DIÁLOGO

| # | Passo | Resultado |
|---|---|---|
| 6.1 | abrir o diálogo com Durn | NOT TESTED |
| 6.2 | tentar carregar (Ctrl+L) | NOT TESTED |
| 6.3 | ver a mensagem ("Termine a conversa antes de carregar o jogo.") | NOT TESTED |
| 6.4 | confirmar que o diálogo não foi fechado nem destruído | NOT TESTED |

## TESTE 7 — ESCOLHA

| # | Passo | Resultado |
|---|---|---|
| 7.1 | fazer uma escolha no diálogo | NOT TESTED |
| 7.2 | salvar | NOT TESTED |
| 7.3 | concluir o diálogo | NOT TESTED |
| 7.4 | alterar o mundo | NOT TESTED |
| 7.5 | carregar | NOT TESTED |
| 7.6 | verificar a última escolha (o diálogo **não** reabre) | NOT TESTED |

## TESTE 8 — SAVE

| # | Passo | Resultado |
|---|---|---|
| 8.1 | salvar novamente | NOT TESTED |
| 8.2 | ver a mensagem | NOT TESTED |

## TESTE 9 — REPETIÇÃO

| # | Passo | Resultado |
|---|---|---|
| 9.1 | carregar novamente | NOT TESTED |
| 9.2 | confirmar o mesmo estado | NOT TESTED |

## TESTE 10 — FALHA

| # | Passo | Resultado |
|---|---|---|
| 10.1 | testar um arquivo inválido, se for seguro (com o jogo fechado, edite um caractere do arquivo V2 **copiado**; depois restaure) | NOT TESTED |
| 10.2 | ver a mensagem ("O jogo salvo está danificado ou é incompatível. Nada foi alterado.") | NOT TESTED |
| 10.3 | confirmar que o jogo não foi alterado | NOT TESTED |

---

## Falhas observadas

| Teste/passo | Esperado | Observado | Captura |
|---|---|---|---|
| — | — | — | — |

## Execução

| Campo | Valor |
|---|---|
| Testador | — |
| Data | — |
| Máquina / GPU | — |
| Resultado geral | NOT TESTED |
