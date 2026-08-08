# =============================================================
# GitHub Contribution Generator
# Creates random commits (0-3 per day) from Jul 1 through today.
# Pushes to a new branch on Ayagoumi/Ayagoumi (never touches master).
# =============================================================

set -e

# ── Config ────────────────────────────────────────────────────
START_DATE="2026-07-01"
END_DATE="$(date +%Y-%m-%d)"
REPO_DIR="/Users/user/Desktop/Ayagoumi"
REMOTE_URL="https://github.com/Ayagoumi/Ayagoumi.git"
BRANCH_NAME="contributions/${START_DATE}-to-${END_DATE}"

# ── Colors ────────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════╗"
echo "║     GitHub Contribution Generator            ║"
echo "╚══════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "📅 Range  : ${YELLOW}$START_DATE${NC} → ${YELLOW}$END_DATE${NC}"
echo -e "📁 Repo   : ${YELLOW}$REPO_DIR${NC}"
echo -e "🔗 Remote : ${YELLOW}$REMOTE_URL${NC}"
echo -e "🌿 Branch : ${YELLOW}$BRANCH_NAME${NC}"
echo ""

if [[ "$START_DATE" > "$END_DATE" ]]; then
  echo -e "${RED}❌ START_DATE ($START_DATE) is after END_DATE ($END_DATE). Nothing to generate.${NC}"
  exit 1
fi

if [ ! -d "$REPO_DIR/.git" ]; then
  echo -e "${RED}❌ $REPO_DIR is not a git repository.${NC}"
  exit 1
fi

cd "$REPO_DIR"

git remote remove origin 2>/dev/null || true
git remote add origin "$REMOTE_URL"
echo -e "${GREEN}✅ Remote set to $REMOTE_URL${NC}"

# Always branch from master — never commit directly to it
git checkout master
echo -e "${GREEN}✅ Checked out master (will not push it)${NC}"

if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
  echo -e "${YELLOW}⚠️  Branch $BRANCH_NAME already exists locally. Checking it out.${NC}"
  git checkout "$BRANCH_NAME"
else
  git checkout -b "$BRANCH_NAME"
  echo -e "${GREEN}✅ Created branch $BRANCH_NAME from master${NC}"
fi

# ── Commit log file ───────────────────────────────────────────
LOG_FILE="$REPO_DIR/.contribution_log.txt"
if [ ! -f "$LOG_FILE" ]; then
  echo "Generated contributions — $(date)" > "$LOG_FILE"
else
  echo "" >> "$LOG_FILE"
  echo "Generated contributions — $(date)" >> "$LOG_FILE"
fi

# ── macOS-compatible date helpers ────────────────────────────
next_day() {
  date -j -v+1d -f "%Y-%m-%d" "$1" "+%Y-%m-%d"
}

# ── Date iteration ────────────────────────────────────────────
current="$START_DATE"
total_days=0
total_commits=0
active_days=0

echo ""
echo -e "${CYAN}Generating commits...${NC}"
echo "────────────────────────────────────────────────"

while true; do
  if [[ "$current" > "$END_DATE" ]]; then
    break
  fi

  # Random number of commits between 0 and 3
  num_commits=$(( RANDOM % 4 ))
  total_days=$(( total_days + 1 ))
  total_commits=$(( total_commits + num_commits ))
  if [ "$num_commits" -gt 0 ]; then
    active_days=$(( active_days + 1 ))
  fi

  for (( i=1; i<=num_commits; i++ )); do
    # Spread commits across the workday (8am–7pm)
    hour=$(( RANDOM % 11 + 8 ))
    minute=$(( RANDOM % 60 ))
    second=$(( RANDOM % 60 ))
    commit_date="${current}T$(printf '%02d' $hour):$(printf '%02d' $minute):$(printf '%02d' $second)"

    echo "$commit_date — commit $i of $num_commits" >> "$LOG_FILE"

    GIT_AUTHOR_DATE="$commit_date" \
    GIT_COMMITTER_DATE="$commit_date" \
    git add "$LOG_FILE" && \
    GIT_AUTHOR_DATE="$commit_date" \
    GIT_COMMITTER_DATE="$commit_date" \
    git commit -q -m "chore: update log [$current $i/$num_commits]"
  done

  if [ "$num_commits" -eq 0 ]; then
    echo -e "  ${YELLOW}–${NC} $current  → ${YELLOW}0${NC} commits (skipped)"
  else
    echo -e "  ${GREEN}✔${NC} $current  → ${YELLOW}$num_commits${NC} commit(s)"
  fi

  current=$(next_day "$current")
done

echo "────────────────────────────────────────────────"
echo -e "${GREEN}"
echo "✅ Done!"
echo -e "   Days in range      : $total_days"
echo -e "   Days with commits  : $active_days"
echo -e "   Total commits made : $total_commits"
echo -e "${NC}"

echo -e "${CYAN}Pushing branch $BRANCH_NAME to GitHub...${NC}"
git push -u origin "$BRANCH_NAME"
echo -e "${GREEN}🚀 Pushed to $REMOTE_URL (branch: $BRANCH_NAME)${NC}"

git checkout master
echo -e "${GREEN}✅ Switched back to master (unchanged on remote)${NC}"
