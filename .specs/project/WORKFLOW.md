# Como Trabalhar com Claude Code no Ekko

Este documento é para **você**, não para o Claude. Ele explica como interagir com o Claude Code de forma previsível, sem bagunçar o planejamento.

---

## Abrindo uma Nova Sessão

**O que fazer:**
Simplesmente diga uma das frases abaixo. O Claude vai ler o napkin, STATE.md e HANDOFF.md automaticamente e te situar antes de agir.

```
"resume"
"continue de onde paramos"
"retomar o trabalho"
"começa a T1"
```

**O que o Claude vai fazer:**
1. Ler `.claude/napkin.md` silenciosamente
2. Ler `.specs/HANDOFF.md` (se existir)
3. Confirmar: "Retomando M0 na T1. Completado: nada. Próximo: git init + Package.swift. Continuar?"
4. Esperar seu "sim" antes de agir

**Nunca faça:**
- Abrir a sessão pedindo direto "implementa o feature X" sem dar contexto — o Claude não terá o estado do projeto carregado e vai tomar decisões erradas.

---

## Durante a Execução de uma Task

**Situação: O Claude está implementando e você quer acompanhar**
Não interrompa. Espere o Claude postar o resultado da task. Ele vai avisar quando terminar e antes de começar a próxima.

**Situação: Você viu algo errado no meio da execução**
Interrompa imediatamente:
```
"para — vejo um problema em X"
```
O Claude vai parar, ouvir, e decidir se corrige na task atual ou abre um blocker.

**Situação: O Claude pediu aprovação para continuar para a próxima fase**
Revise o resumo postado (tasks completas, contagem de testes, desvios). Então:
```
"aprovado, pode continuar"   ← tudo ok
"tenho feedback antes de aprovar"  ← quer discutir algo
"reprovado — problema em T3"  ← quer que o Claude corrija antes
```

---

## Quando o Claude Pedir uma Ação Manual

Você vai ver um bloco assim:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  MANUAL STEP REQUIRED — T14
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. Abra o Xcode
2. File → New → Project...
...
Quando terminar, responda: "manual step done"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**O que fazer:**
1. Siga as instruções na ordem
2. Quando terminar, diga: `"manual step done"`
3. Se tiver dúvida em algum passo: `"dúvida no passo 3 — o que significa X?"`
4. Nunca diga "manual step done" sem ter feito os passos — o Claude vai assumir que está pronto e pode falhar de forma difícil de debugar

---

## Querendo Mudar Algo no Plano

### Mudança pequena (sem impacto no spec/design)
Ex: "quero renomear essa variável", "prefiro esse approach aqui"
```
"antes de continuar, quero ajustar X para Y"
```
O Claude corrige e continua.

### Mudança que afeta spec ou design
Ex: "mudei de ideia sobre como o logger funciona", "quero adicionar um requisito"
```
"preciso revisitar o spec de M0 antes de continuar"
```
O Claude vai pausar a execução, abrir o spec afetado, discutir a mudança, atualizar os documentos, e só depois retomar. **Nunca edite spec/design manualmente** sem avisar o Claude — os documentos ficam inconsistentes com o que foi implementado.

### Mudança grande (afeta arquitetura)
Ex: "quero adicionar suporte a múltiplos perfis já no M1"
```
"quero discutir uma mudança de escopo no roadmap"
```
O Claude vai usar o fluxo de tlc-spec-driven para avaliar impacto antes de qualquer coisa.

---

## Discordando de uma Decisão Técnica

Se o Claude tomou uma decisão técnica que você não gosta:
```
"discordo da abordagem em T9 — prefiro X porque Y"
```
O Claude vai explicar o raciocínio por trás da decisão. Se você ainda preferir outra abordagem, diga:
```
"entendi, mas quero seguir com X mesmo assim"
```
O Claude vai implementar sua preferência e registrar como decisão em STATE.md.

**Nunca:** deixe a divergência implícita. Se não falar, o Claude vai assumir que concordou.

---

## Fazendo Perguntas Sem Disparar Implementação

Se quiser entender algo sem que o Claude comece a agir:
```
"pergunta: por que escolhemos launchd ao invés de BGTaskScheduler?"
"me explica como o LaunchdScheduler vai funcionar"
"o que está dentro de EkkoCore agora?"
```
O Claude responde sem implementar nada.

---

## Encerrando uma Sessão

Antes de fechar, diga:
```
"pausa — encerra a sessão"
"vou parar por hoje"
"cria o handoff"
```
O Claude vai:
1. Atualizar `tasks.md` com os status atuais
2. Atualizar `STATE.md` com decisões e blockers
3. Criar `.specs/HANDOFF.md` com tudo que você precisa para retomar

**Nunca feche a sessão sem esse passo** se houver trabalho em andamento — você vai perder o estado e precisar reconstruir manualmente.

---

## Situações de Emergência

### "Compilou mas o comportamento está errado"
```
"tem um bug em X — vejo que Y está acontecendo mas deveria ser Z"
```
O Claude vai usar `superpowers:systematic-debugging`. Não tente debugar sozinho nos arquivos — o Claude precisa do contexto para não introduzir novos problemas.

### "Quero desfazer uma task"
```
"quero reverter T9 — o approach não está funcionando"
```
O Claude vai fazer `git revert` ou propor a estratégia de desfazer mais segura para aquele caso.

### "O Claude foi numa direção totalmente errada"
```
"para tudo — precisamos realinhar"
```
O Claude vai parar imediatamente, fazer um resumo do estado atual, e você redirecionam juntos antes de qualquer nova ação.

### "Não entendi o que foi feito numa task"
```
"me explica o que foi implementado em T3 antes de continuar"
```
O Claude explica o código, os trade-offs e as decisões tomadas. Nunca aprove uma fase sem entender o que foi feito.

---

## Resumo: Frases Úteis

| Situação | O que dizer |
|---|---|
| Iniciar/retomar sessão | `"resume"` / `"retomar"` |
| Aprovar fase | `"aprovado, pode continuar"` |
| Dar feedback numa fase | `"tenho feedback antes de aprovar"` |
| Reprovar fase | `"reprovado — problema em T<N>"` |
| Manual step concluído | `"manual step done"` |
| Parar execução | `"para — vejo um problema"` |
| Fazer pergunta | `"pergunta: ..."` |
| Mudar spec/design | `"preciso revisitar o spec antes de continuar"` |
| Encerrar sessão | `"pausa — encerra a sessão"` |
| Emergência | `"para tudo — precisamos realinhar"` |
