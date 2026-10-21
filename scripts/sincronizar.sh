#!/usr/bin/env bash
#
# Propaga as regras compartilhadas deste repositorio para um repositorio de codigo
# do SUOAC, como um subtree em .claude/rules/compartilhado.
#
#   ./scripts/sincronizar.sh ../suoac-front
#
# Na primeira vez faz `subtree add`; depois, `subtree pull`. As duas operacoes
# CRIAM COMMIT no repositorio de destino e exigem arvore de trabalho limpa.
#
# Só `rules/` viaja. O resto desta fonte -- README, scripts, CLAUDE.md -- fica
# aqui: `git subtree add` importa a RAIZ do que recebe, entao o script primeiro
# extrai `rules/` para o ramo `distribuicao` com `git subtree split` e distribui
# esse ramo. Sem isso, o destino receberia o repositorio inteiro, com as regras
# um nivel abaixo do esperado e com README e CLAUDE.md virando arquivo de regra.

set -euo pipefail

PREFIXO_DESTINO=".claude/rules/compartilhado"
PREFIXO_FONTE="rules"
REMOTE="ai"
RAMO="distribuicao"

FONTE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DESTINO="${1:-}"

if [[ -z "$DESTINO" ]]; then
  echo "uso: $0 <caminho-do-repositorio-de-destino>" >&2
  exit 1
fi

if [[ ! -d "$DESTINO/.git" ]]; then
  echo "erro: $DESTINO nao e um repositorio git" >&2
  exit 1
fi

# A extracao le o historico, nao a arvore de trabalho: regra editada e nao
# commitada aqui nao chegaria no destino, e em silencio.
if [[ -n "$(git -C "$FONTE" status --porcelain)" ]]; then
  echo "erro: a arvore de trabalho da fonte ($FONTE) tem mudancas nao commitadas." >&2
  echo "      so o que esta commitado e distribuido. Commite antes de sincronizar." >&2
  exit 1
fi

if [[ -n "$(git -C "$DESTINO" status --porcelain)" ]]; then
  echo "erro: a arvore de trabalho de $DESTINO tem mudancas nao commitadas." >&2
  echo "      git subtree exige arvore limpa. Commite ou guarde antes de sincronizar." >&2
  exit 1
fi

echo "extraindo $PREFIXO_FONTE/ para o ramo '$RAMO'"
COMMIT_DIST="$(git -C "$FONTE" subtree split --prefix="$PREFIXO_FONTE")"
git -C "$FONTE" branch --force "$RAMO" "$COMMIT_DIST"

cd "$DESTINO"

if ! git remote get-url "$REMOTE" >/dev/null 2>&1; then
  git remote add "$REMOTE" "$FONTE"
  echo "remote '$REMOTE' adicionado apontando para $FONTE"
fi

git fetch --quiet "$REMOTE" "$RAMO"

if git ls-files --error-unmatch "$PREFIXO_DESTINO" >/dev/null 2>&1; then
  echo "atualizando $PREFIXO_DESTINO a partir de $REMOTE/$RAMO"
  git subtree pull --prefix="$PREFIXO_DESTINO" "$REMOTE" "$RAMO" --squash \
    -m "docs(regras): sincronizar regras compartilhadas"
else
  echo "instalando $PREFIXO_DESTINO a partir de $REMOTE/$RAMO"
  git subtree add --prefix="$PREFIXO_DESTINO" "$REMOTE" "$RAMO" --squash \
    -m "docs(regras): instalar as regras compartilhadas"
fi

if [[ ! -f ".agents/rules.json" ]]; then
  mkdir -p .agents
  cat > .agents/rules.json <<'EOF'
{
  "entries": [{ "path": ".claude/rules" }, { "path": ".claude/rules/compartilhado" }]
}
EOF
  echo "criado .agents/rules.json apontando para .claude/rules e $PREFIXO_DESTINO"
fi

echo
echo "pronto. Confira o que entrou:"
echo "  git -C $DESTINO log --oneline -3"
echo "  git -C $DESTINO ls-files $PREFIXO_DESTINO"
