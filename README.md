# suoac-ai

Fonte de verdade das regras de trabalho que valem para **os dois** repositórios do SUOAC —
`suoac-back` e `suoac-front`. O que mora aqui é processo e postura: commits, Jira, branches e PRs,
e as duas regras de código que são idênticas nos dois lados.

O que é específico de um stack **não** mora aqui. Arquitetura FSD, Prisma, design system, NestJS,
Playwright e afins vivem em `.claude/rules/` do repositório a que pertencem.

## Por que este repositório existe

Os dois repositórios ficam lado a lado em `~/projetos-pessoais/suoac/`. Uma sessão de IA aberta na
pasta-mãe carrega as instruções dos dois quando toca arquivos dos dois lados — e, enquanto as regras
de processo estavam duplicadas em cada `AGENTS.md`, elas entravam em contexto **contraditórias**:
seções numeradas de formas diferentes, referências cruzadas apontando para números errados, e o
fechamento de card exigindo comandos diferentes. A documentação do Claude Code é explícita: diante de
instruções que se contradizem, o agente pode seguir qualquer uma.

Uma fonte, dois destinos, nenhuma cópia editada à mão.

## Onde esta fonte vive

Dois lugares, e os dois importam:

- `~/projetos-pessoais/suoac/suoac-ai/`, ao lado dos dois repositórios de código. É deste caminho que
  o `sincronizar.sh` distribui, porque ele resolve a fonte pela própria localização.
- `github.com/Fioravante1/suoac-ai`, público, como cópia durável. Sem ele, a fonte existiria só numa
  máquina: as cópias nos dois repositórios sobreviveriam, mas não haveria de onde sincronizar.

Só o `main` vai para o remote. O ramo `distribuicao` é derivado — recriado a cada sincronização — e
não tem por que existir lá.

## Como as regras chegam aos repositórios

Por `git subtree`, em `.claude/rules/compartilhado/` de cada repositório. O conteúdo fica
**commitado** lá, e é isso que faz a solução funcionar em clone novo, em sessão na nuvem e no CI —
nenhum deles vê arquivos fora do repositório clonado.

```bash
./scripts/sincronizar.sh ../suoac-front
./scripts/sincronizar.sh ../suoac-back
```

Na primeira execução o script faz `subtree add`; nas seguintes, `subtree pull`. As duas criam commit
no repositório de destino e exigem árvore de trabalho limpa — nos **dois** lados: `subtree split` lê
o histórico desta fonte, não a árvore de trabalho, então regra editada e não commitada aqui não
chegaria ao destino, e em silêncio.

Só `rules/` viaja. `git subtree add` importa a **raiz** do que recebe, e apontá-lo para `main`
entregaria o repositório inteiro: as regras um nível abaixo do esperado, em
`compartilhado/rules/`, e o `README.md` e o `CLAUDE.md` daqui virando arquivo de regra no destino —
tudo em `.claude/rules/**` é lido como regra. Por isso o script extrai `rules/` para o ramo
`distribuicao`, com `git subtree split`, e distribui esse ramo. O ramo é derivado: é recriado a cada
sincronização, nunca se commita nele à mão.

### Mecanismos que foram descartados, e por quê

Está registrado para ninguém refazer o caminho:

- **Symlink de `.claude/rules/` para cá**: o Claude Code trata link para fora do diretório de
  trabalho como import externo e, mesmo depois de aprovado, **carrega apenas as regras sem `paths`**.
  Isso mataria o escopo por caminho, que é metade do valor da reorganização.
- **Submodule**: clone sem `--recursive` deixa a pasta vazia e a sessão roda sem as regras, em
  silêncio. Falha que não avisa é a pior espécie.
- **Plugin do Claude Code**: não carrega instrução permanente — a documentação manda escrever
  instrução de plugin como skill — e plugin não chega em sessão na nuvem.
- **Import `@../suoac-ai/...` no `AGENTS.md`**: dispara diálogo de aprovação e, pior, o caminho não
  existe em clone isolado, na nuvem ou no CI.

## Como editar

1. Edite o arquivo aqui, em `rules/`.
2. Commite nesta fonte.
3. Rode `./scripts/sincronizar.sh` para cada repositório.
4. Commite o resultado em cada repositório, junto com o card correspondente no Jira.

Nunca edite `.claude/rules/compartilhado/` dentro de um repositório de código: a próxima
sincronização vai sobrescrever, e a divergência volta pela porta dos fundos.

## O que mora aqui

| Arquivo | Escopo | Carrega quando |
| - | - | - |
| `rules/commits.md` | Conventional Commits, organização por significado, sem trailer de IA | sempre |
| `rules/branches-e-prs.md` | nome de branch, título e corpo de PR, quando commitar | sempre |
| `rules/jira.md` | rastreamento de card, convenções do projeto `SUC`, como escrever card | sempre |
| `rules/postura-do-agente.md` | decisões são do usuário, dependência pendente, verificação | sempre |
| `rules/idioma-do-codigo.md` | identificadores em inglês, português para humanos | arquivos de código |
| `rules/aninhamento-e-ternarios.md` | early returns, sem ternário aninhado | arquivos de código |

As duas últimas têm `paths:` no frontmatter e entram em contexto só quando o agente toca um arquivo
de código. Isso funciona porque o subtree deixa os arquivos **dentro** do repositório — regra
path-scoped que chega por symlink externo não carrega.
