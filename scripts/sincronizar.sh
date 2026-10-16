#!/usr/bin/env bash
#
# Propaga as regras compartilhadas deste repositorio para um repositorio de codigo
# do SUOAC, como um subtree em .claude/rules/compartilhado.
#
#   ./scripts/sincronizar.sh ../suoac-front
#
# Na primeira vez faz `subtree add`; depois, `subtree pull`. As duas operacoes
# CRIAM COMMIT no repositorio de destino e exigem arvore de trabalho limpa.

set -euo pipefail

PREFIXO=".claude/rules/compartilhado"
REMOTE="ai"
RAMO="main"

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

cd "$DESTINO"

if [[ -n "$(git status --porcelain)" ]]; then
  echo "erro: a arvore de trabalho de $DESTINO tem mudancas nao commitadas." >&2
  echo "      git subtree exige arvore limpa. Commite ou guarde antes de sincronizar." >&2
  exit 1
fi

if ! git remote get-url "$REMOTE" >/dev/null 2>&1; then
  git remote add "$REMOTE" "$FONTE"
  echo "remote '$REMOTE' adicionado apontando para $FONTE"
fi

git fetch --quiet "$REMOTE" "$RAMO"

if [[ -d "$PREFIXO" ]]; then
  echo "atualizando $PREFIXO a partir de $REMOTE/$RAMO"
  git subtree pull --prefix="$PREFIXO" "$REMOTE" "$RAMO" --squash
else
  echo "instalando $PREFIXO a partir de $REMOTE/$RAMO"
  git subtree add --prefix="$PREFIXO" "$REMOTE" "$RAMO" --squash
fi

echo
echo "pronto. Confira o que entrou:"
echo "  git -C $DESTINO log --oneline -3"
echo "  git -C $DESTINO ls-files $PREFIXO"
